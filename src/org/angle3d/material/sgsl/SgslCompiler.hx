package org.angle3d.material.sgsl;


import de.polygonal.ds.error.Assert;
import flash.utils.ByteArray;
import flash.utils.Endian;
import flash.Vector;
import haxe.ds.IntMap;
import org.angle3d.Angle3D;
import org.angle3d.manager.ShaderManager;
import org.angle3d.utils.FastStringMap;
import org.angle3d.material.sgsl.node.AgalNode;
import org.angle3d.material.sgsl.node.ArrayAccessNode;
import org.angle3d.material.sgsl.node.LeafNode;
import org.angle3d.material.sgsl.node.NodeType;
import org.angle3d.material.sgsl.node.NumberNode;
import org.angle3d.material.sgsl.node.ProgramNode;
import org.angle3d.material.sgsl.node.reg.AttributeReg;
import org.angle3d.material.sgsl.node.reg.RegNode;
import org.angle3d.material.sgsl.node.reg.TempReg;
import org.angle3d.material.sgsl.parser.SgslParser;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderParamType;
import org.angle3d.material.shader.ShaderProfile;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.utils.Logger;


using StringTools;

/**
 * Stage3D Shader Language(sgsl) Complier
 * @author weilichuang
 */
//TODO 添加数组类型
class SgslCompiler
{
	public var profile:ShaderProfile;
	
	public var agalVersion:Int = 2;
	
	private var MAX_OPCODES:Int = 1024;

	private var _swizzleMap:FastStringMap<Int>;
	
	private var _xyzwMap:IntMap<String>;

	private var _regCodeMap:FastStringMap<Int>;

	private var _vertexData:SgslData;

	private var _fragmentData:SgslData;

	private var _byteArray:ByteArray;

	private var _sgsl2Agal:Sgsl2Agal;

	private var _parser:SgslParser;

	private var _optimizer:SgslOptimizer;

	private var _opCodeManager:OpCodeManager;
	
	private var _currentData:SgslData;

	public function new(profile:ShaderProfile, sgslParser:SgslParser, opCodeManager:OpCodeManager)
	{
		this.profile = profile;
		
		agalVersion = Angle3D.getAgalVersion(profile);

		switch(agalVersion)
		{
			case 1:
				MAX_OPCODES = 200;
			case 2:
				MAX_OPCODES = 1024;
			case 3:
				MAX_OPCODES = 2047;
		}

		_parser = sgslParser;
		_opCodeManager = opCodeManager;

		_swizzleMap = new FastStringMap<Int>();
		_swizzleMap.set("x",0);
		_swizzleMap.set("y",1);
		_swizzleMap.set("z",2);
		_swizzleMap.set("w",3);
		_swizzleMap.set("r",0);
		_swizzleMap.set("g",1);
		_swizzleMap.set("b",2);
		_swizzleMap.set("a", 3);
		
		_xyzwMap = new IntMap<String>();
		_xyzwMap.set(0,"x");
		_xyzwMap.set(1,"y");
		_xyzwMap.set(2,"z");
		_xyzwMap.set(3,"w");

		_initEmitCodes();

		_optimizer = new SgslOptimizer();

		_sgsl2Agal = new Sgsl2Agal();

		_vertexData = new SgslData(profile, ShaderType.VERTEX);
		_fragmentData = new SgslData(profile, ShaderType.FRAGMENT);
	}

	/**
	 * 编译并传递数据到Shader中
	 * @param	shader
	 * @param	sources
	 * @param	conditions
	 * @return
	 */
	public function complie(vertexSource:String, fragmentSource:String, 
							vertexDefines:Vector<String> = null, fragmentDefines:Vector<String> = null):Shader
	{
		var shader:Shader = new Shader();

		_vertexData.clear();
		var tree:ProgramNode = _parser.exec(vertexSource);
		_optimizer.exec(_vertexData, tree, vertexDefines);

		_fragmentData.clear();
		tree = _parser.exec(fragmentSource);
		_optimizer.exec(_fragmentData, tree, fragmentDefines);

		_updateShader(_vertexData, shader);
		_updateShader(_fragmentData, shader);

		shader.vertexData = assemble(_vertexData);
		shader.fragmentData = assemble(_fragmentData);

		shader.updateLocations();

		#if debug
		Assert.assert(_vertexData.checkVarying(_fragmentData), "varying数据不匹配");
		#end

		#if debug
			Logger.log("Vertex Agal:\n" + _sgsl2Agal.toAgal(shader.vertexData,true) + "\n");
			Logger.log("Fragment Agal:\n" + _sgsl2Agal.toAgal(shader.fragmentData,true) + "\n");
		#end

		return shader;
	}

	private function _initEmitCodes():Void
	{
		_regCodeMap = new  FastStringMap<Int>();
		_regCodeMap.set(RegType.ATTRIBUTE, 0x0);
		_regCodeMap.set(RegType.UNIFORM, 0x1);
		_regCodeMap.set(RegType.TEMP, 0x2);
		_regCodeMap.set(RegType.OUTPUT, 0x3);
		_regCodeMap.set(RegType.VARYING, 0x4);
		//_regCodeMap.set(RegType.TEXTURE, 0x5);
		_regCodeMap.set(RegType.DEPTH, 0x6);
	}

	
	private inline function getRegCode(reg:RegNode):Int
	{
		return _regCodeMap.get(reg.regType);
	}

	/**
	 * 更新Shader中对应的变量名和其大小
	 * @param	data
	 * @param	shader
	 */
	private function _updateShader(data:SgslData, shader:Shader):Void
	{
		var shaderType:ShaderType = data.shaderType;

		shader.setConstants(shaderType, data.uniformPool.getConstants());

		var regList:Vector<RegNode> = data.uniformPool.getRegs();

		var reg:RegNode;
		var varType:ShaderParamType = ShaderParamType.UNIFORM;
		for (i in 0...regList.length)
		{
			reg = regList[i];
			shader.addVariable(shaderType, varType, reg);
		}

		if (shaderType == ShaderType.VERTEX)
		{
			regList = data.attributePool.getRegs();
			varType = ShaderParamType.ATTRIBUTE;
		}
		else
		{
			regList = data.texturePool.getRegs();
			varType = ShaderParamType.TEXTURE;
		}

		for (i  in 0...regList.length)
		{
			reg = regList[i];
			shader.addVariable(shaderType, varType, reg);
		}
	}

	private function assemble(data:SgslData):ByteArray
	{
		_currentData = data;

		_byteArray = new ByteArray();
		_byteArray.endian = Endian.LITTLE_ENDIAN;
		_byteArray.position = 0;

		writeHeader(data.shaderType == ShaderType.FRAGMENT);

		var nodes:Vector<AgalNode> = data.nodes;
		var count:Int = nodes.length;
		
		#if debug
		Assert.assert(count <= MAX_OPCODES, "too many opcodes. maximum is " + MAX_OPCODES + ".");
		#end

		for (i in 0...count)
		{
			writeNode(nodes[i]);
		}

		return _byteArray;
	}

	/**
	 * Agal头部
	 * @param	isFrag
	 * @param	data
	 */
	private function writeHeader(isFrag:Bool):Void
	{
		_byteArray.writeByte(0xa0); // tag version
		_byteArray.writeUnsignedInt(agalVersion); // AGAL version, big endian, bit pattern will be 0x01000000
		_byteArray.writeByte(0xa1); // tag program id
		_byteArray.writeByte(isFrag ? 1 : 0); // vertex or fragment
	}

	/**
	 *
	 * 63.............................................................0
	 * FFFFMMMMWWWWSSSSDDDD--------TTTT--------BBBBBBBBNNNNNNNNNNNNNNNN
	 * N = Sampler register number (16 bits)
	 * B = Texture level-of-detail (LOD) bias, signed integer, scale by 8. The floating point value used is b/8.0 (8 bits)
	 * T = Register type, must be 5, Sampler (4 bits)
	 * F = Filter (0=nearest,1=linear) (4 bits)
	 * M = Mipmap (0=disable,1=nearest, 2=linear)
	 * W = Wrapping (0=clamp,1=repeat)
	 * S = Special flag bits (must be 0)
	 * D = Dimension (0=2D, 1=Cube)
	 * @param regIndex 注册位置
	 * @param flag
	 *
	 */
	private function writeTexture(regIndex:Int, flag:TexFlag):Void
	{
		_byteArray.writeShort(regIndex); //16 bits
		_byteArray.writeByte(flag.getLod()); //8 bits
		_byteArray.writeByte(0); //8 bits
		_byteArray.writeByte(5); //8 bits

		var bits:Int = flag.getTexFlagsBits();

		_byteArray.writeByte(bits & 0xFF);
		_byteArray.writeByte((bits >> 8) & 0xFF);
		_byteArray.writeByte(bits >> 16);
	}

	/**
	 * 数组类型会有个偏移量需要加上
	 * @param node
	 */
	private function getRegisterIndex(node:LeafNode):Int
	{
		var reg:RegNode = _currentData.getRegNode(node.name);
		if (Std.is(node,ArrayAccessNode))
		{
			return reg.index + cast(node,ArrayAccessNode).offset;
		}
		return reg.index;
	}

	private function writeNode(node:AgalNode):Void
	{
		//emitCode
		var opCode:OpCode = _opCodeManager.getCode(node.name);
		_byteArray.writeUnsignedInt(opCode.emitCode);
		
		writeDest(node.dest);
		
		if (_opCodeManager.isTexture(node.name))
		{
			writeSrc(node.source1);

			//提取出参数
			//var flags:Array<String> = [];
			//for (i in 2...fLength)
			//{
				//flags.push(fChildren[i].name);
			//}
			var texFlag:TexFlag = new TexFlag();
			//texFlag.parseFlags(flags);

			if (node.name == "texture2D")
			{
				texFlag.dimension = 0;
			}
			else if (node.name == "textureCube")
			{
				texFlag.dimension = 1;
			}
			else if (node.name == "texture3D")
			{
				texFlag.dimension = 2;
			}

			var fcReg:RegNode = _currentData.getRegNode(node.source2.name);

			writeTexture(fcReg.index, texFlag);
		}
		else 
		{
			writeSrc(node.source1);
			writeSrc(node.source2);
		}
	}

	/**
	 * The [destination] field is 32 bits in size:
	 * 31.............................0
	 * ----TTTT----MMMMNNNNNNNNNNNNNNNN
	 * T = Register type (4 bits)
	 * M = Write mask (4 bits)
	 * N = Register number (16 bits)
	 * - = undefined, must be 0
	 */
	private function writeDest(dest:LeafNode):Void
	{
		if (dest == null)
		{
			_byteArray.writeUnsignedInt(0);
			return;
		}

		var reg:RegNode = _currentData.getRegNode(dest.name);
		_byteArray.writeShort(getRegisterIndex(dest));
		_byteArray.writeByte(maskBits(reg, dest.mask));
		_byteArray.writeByte(getRegCode(reg));
	}

	/**
	 * The [source] field is 64 bits in size:
	 *
	 * 63.............................................................0
	 * D-------------QQ----IIII----TTTTSSSSSSSSOOOOOOOONNNNNNNNNNNNNNNN
	 *
	 * D = Direct=0/Indirect=1 for direct Q and I are ignored, 1bit
	 * Q = Index register component select (2 bits)
	 * I = Index register type (4 bits)
	 * T = Register type (4 bits)
	 * S = Swizzle (8 bits, 2 bits per component)
	 * O = Indirect offset(8 bits)
	 * N = Register number (16 bits)
	 * - = undefined, must be 0
	 */
	private function writeSrc(node:LeafNode):Void
	{
		if (node == null)
		{
			_byteArray.writeInt(0);
			_byteArray.writeInt(0);
			return;
		}

		var reg:RegNode;

		var registerIndex:Int;
		if (node.isRelative())
		{
			reg = _currentData.getRegNode(node.name);
			
			var relativeNode:ArrayAccessNode = cast node;
			
			var arrayAccessNode:LeafNode = relativeNode.children[0];

			var relOffset:Int = relativeNode.offset + reg.index;

			var accessReg:RegNode = _currentData.getRegNode(arrayAccessNode.name);

			registerIndex = getRegisterIndex(arrayAccessNode);

			_byteArray.writeShort(registerIndex);
			_byteArray.writeByte(relOffset);
			_byteArray.writeByte(swizzleBits(reg, relativeNode.mask));

			_byteArray.writeByte(getRegCode(reg));
			_byteArray.writeByte(getRegCode(accessReg));
			_byteArray.writeShort((getCharIndex(arrayAccessNode.mask) | (1 << 15)));
		}
		else
		{
			var swizzleBit:Int;
			var regCode:Int;

			if (node.type == NodeType.NUMBER)
			{
				var constantNode:NumberNode = cast node;

				registerIndex = _currentData.getNumberIndex(constantNode.value);
				swizzleBit = swizzleBits(null, _currentData.getNumberMask(constantNode.value));
				regCode = _regCodeMap.get(RegType.UNIFORM);
			}
			else
			{
				reg = _currentData.getRegNode(node.name);
				registerIndex = getRegisterIndex(node);
				swizzleBit = swizzleBits(reg, node.mask);
				regCode = getRegCode(reg);
			}

			_byteArray.writeShort(registerIndex);
			_byteArray.writeByte(0);
			_byteArray.writeByte(swizzleBit);
			_byteArray.writeByte(regCode);
			_byteArray.writeByte(0);
			_byteArray.writeShort(0);
		}
	}


	#if debug
	private function readString(data:ByteArray, size:Int):String
	{
		var result:String = "";
		var start:Int = data.position;
		var end:Int = size + start;
		for (i in start...end)
		{
			var byteStr:String = data[i].hex(2);
			if (byteStr.length < 2)
				byteStr = "0" + byteStr;

			result += byteStr;
		}

		data.position += size;

		return result;
	}

	private function getAgalInfo(data:ByteArray):String
	{
		data.position = 0;

		var result:String = "agal bytecode:\n";

		//header
		result += readString(data, 7) + "\n";

		var count:Int = Std.int((data.length - 7) / 24);
		for (i in 0...count)
		{
			//opcode
			result += readString(data, 4);
			result += " ";
			//dest
			result += readString(data, 4);
			result += " ";
			//source0
			result += readString(data, 8);
			result += " ";
			//source1
			result += readString(data, 8);
			result += "\n";
		}
		return result;
	}
	#end

	private inline function getCharIndex(char:String):Int
	{
		return _swizzleMap.get(char.toLowerCase());
	}

	private function maskBits(reg:RegNode, swizzle:String):Int
	{
		var comps:String = getRealSwizzle(reg, swizzle);

		if (comps == null || comps.length == 0)
			return 0x0f;

		var bits:Int = 0;
		var length:Int = comps.length;
		for (i in 0...length)
		{
			bits |= 1 << getCharIndex(comps.charAt(i));
		}
		return bits;
	}

	/**
	 *
	 * @param list Array<String>
	 * @return
	 *
	 */
	private function swizzleBits(reg:RegNode, swizzle:String):Int
	{
		var comps:String = getRealSwizzle(reg, swizzle);

		if (comps == null || comps.length == 0)
			return 0xe4; //0 | (1 << 2) | (2 << 4) | (3 << 6)

		Assert.assert(comps.length <= 4, "comps的长度不能超过4");

		var bits:Int = 0;
		var p:Int = 0;
		var last:Int = 0;
		var sLength:Int = comps.length;
		for (i in 0...sLength)
		{
			last = getCharIndex(comps.charAt(i));
			bits |= last << p;
			p += 2;
		}

		// repeat last component
		while (p < 8)
		{
			bits |= last << p;
			p += 2;
		}
		return bits;
	}

	private static var _xyzw:String = "xyzw";

	private function getTempRegSwizzle(tempReg:TempReg, swizzle:String):String
	{
		if (swizzle == null || swizzle.length == 0)
		{
			return _xyzw.substr(tempReg.offset, tempReg.size);
		}

		var result:String = "";
		var sLength:Int = swizzle.length;
		for (i in 0...sLength)
		{
			var index:Int = _swizzleMap.get(swizzle.charAt(i)) + tempReg.offset;
			result += _xyzwMap.get(index);
		}

		return result;
	}

	private function getRealSwizzle(reg:RegNode, swizzle:String):String
	{
		if (reg == null)
		{
			return swizzle;
		}

		//貌似有点问题
		if (Std.is(reg,TempReg) && DataType.isNeedOffset(reg.dataType))
		{
			return getTempRegSwizzle(Std.instance(reg,TempReg), swizzle);
		}
		else if (swizzle == null || swizzle.length == 0)
		{
			if (Std.is(reg,AttributeReg))
			{
				var typeSize:Int = reg.size;
				if (typeSize < 2)
				{
					return _xyzw.substr(0, typeSize);
				}
			}
			return "";
		}
		else
		{
			return swizzle;
		}
	}
}

