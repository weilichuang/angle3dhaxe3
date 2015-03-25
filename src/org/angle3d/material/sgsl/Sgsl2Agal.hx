package org.angle3d.material.sgsl;

import flash.utils.ByteArray;
import haxe.ds.IntMap;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.math.FastMath;


class Sgsl2Agal
{
	private var _codeMap:IntMap<String>;

	private var _swizzleMap:IntMap<String>;

	private var _shaderType:ShaderType;

	private var _data:ByteArray;

	public function new()
	{
		_codeMap = new IntMap<String>();
		_codeMap.set(0x00,"mov");
		_codeMap.set(0x01,"add");
		_codeMap.set(0x02,"sub");
		_codeMap.set(0x03,"mul");
		_codeMap.set(0x04,"div");
		_codeMap.set(0x05,"rcp");
		_codeMap.set(0x06,"min");
		_codeMap.set(0x07,"max");
		_codeMap.set(0x08,"frc");
		_codeMap.set(0x09,"sqt");
		_codeMap.set(0x0a,"rsq");
		_codeMap.set(0x0b,"pow");
		_codeMap.set(0x0c,"log");
		_codeMap.set(0x0d,"exp");
		_codeMap.set(0x0e,"nrm");
		_codeMap.set(0x0f,"sin");
		_codeMap.set(0x10,"cos");
		_codeMap.set(0x11,"crs");
		_codeMap.set(0x12,"dp3");
		_codeMap.set(0x13,"dp4");
		_codeMap.set(0x14,"abs");
		_codeMap.set(0x15,"neg");
		_codeMap.set(0x16,"sat");
		_codeMap.set(0x17,"m33");
		_codeMap.set(0x18,"m44");
		_codeMap.set(0x19,"m34");

		_codeMap.set(0x1a,"ddx");
		_codeMap.set(0x1b,"ddy");
		_codeMap.set(0x1c,"ife");
		_codeMap.set(0x1d,"ine");
		_codeMap.set(0x1e,"ifg");
		_codeMap.set(0x1f,"ifl");
		_codeMap.set(0x20,"els");
		_codeMap.set(0x21,"eif");
		
		//space
		//_codeMap.set(0x26,"ted");

		_codeMap.set(0x27,"kil");
		_codeMap.set(0x28,"tex");
		_codeMap.set(0x29,"sge");
		_codeMap.set(0x2a,"slt");
		_codeMap.set(0x2b,"sgn");
		_codeMap.set(0x2c,"seq");
		_codeMap.set(0x2d,"sne");

		_swizzleMap = new IntMap<String>();
		_swizzleMap.set(0,"x");
		_swizzleMap.set(1,"y");
		_swizzleMap.set(2,"z");
		_swizzleMap.set(3,"w");
	}

	public function toAgal(data:ByteArray):String
	{
		_data = data;

		_data.position = 0;

		_data.readUnsignedByte(); // tag version
		var version:Int = _data.readUnsignedInt(); // AGAL version, big endian, bit pattern will be 0x01000000
		_data.readUnsignedByte(); // tag program id

		_shaderType = (_data.readUnsignedByte() == 0) ? ShaderType.VERTEX : ShaderType.FRAGMENT;

		var agal:String = "";
		var index:Int;
		var code:Int;
		var offset:Int;
		while (data.position < data.length)
		{
			var elements:Array<String> = [];

			var opcode:String = _codeMap.get(data.readUnsignedInt());

			addElement(elements, opcode);

			addElement(elements, readDest());

			//source0
			addElement(elements, readSrc());

			//source1
			var source1:String;
			if (opcode == "tex")
			{
				source1 = readTexture();
			}
			else
			{
				source1 = readSrc();
			}
			addElement(elements, source1);

			agal += elements.join(" ") + "\n";
		}

		return agal;
	}

	private function addElement(list:Array<String>, element:String):Void
	{
		if (element.length > 0)
		{
			list.push(element);
		}
	}

	private function getRegPrex(code:Int):String
	{
		switch (code)
		{
			case 0x0:
				return "va";
			case 0x1:
				return _shaderType == ShaderType.VERTEX ? "vc" : "fc";
			case 0x2:
				return _shaderType == ShaderType.VERTEX ? "vt" : "ft";
			case 0x3:
				return _shaderType == ShaderType.VERTEX ? "op" : "oc";
			case 0x4:
				return "v";
			case 0x5:
				return "fs";
			case 0x6:
				return "fd";
		}
		return "";
	}

	private function readTexture():String
	{
		var index:Int = _data.readUnsignedShort();
		var lod:Int = _data.readUnsignedByte();
		//未使用
		_data.position += 2;

		var value:Int = _data.readUnsignedByte();
		var format:Int = value & 0xf;
		var dimension:Int = value >> 4 & 0xf;

		value = _data.readUnsignedByte();
		var special:Int = value & 0xf;
		var wrap:Int = value >> 4 & 0xf;

		value = _data.readUnsignedByte();
		var mipmap:Int = value & 0xf;
		var filter:Int = value >> 4 & 0xf;

		var option:Array<String> = [];

		if (special == 4)
		{
			option.push("ignoresampler");
		}

		if (format == 0)
		{
			option.push("rgba");
		}
		else if (format == 1)
		{
			option.push("dxt1");
		}
		else if (format == 2)
		{
			option.push("dxt5");
		}

		if (dimension == 0)
		{
			option.push("2d");
		}
		else if (dimension == 1)
		{
			option.push("cube");
		}
		else if (dimension == 2)
		{
			option.push("3d");
		}

		if (wrap == 0)
		{
			option.push("clamp");
		}
		else if (wrap == 1)
		{
			option.push("wrap");
		}

		if (mipmap == 0)
		{
			option.push("nomip");
		}
		else if (mipmap == 1)
		{
			option.push("mipnearest");
		}
		else if (mipmap == 2)
		{
			option.push("miplinear");
		}

		if (filter == 0)
		{
			option.push("nearest");
		}
		else if (filter == 1)
		{
			option.push("linear");
		}

		if (lod > 0)
		{
			option.push(lod * 8 + "");
		}

		return "fs" + index + " <" + option.join(",") + ">";
	}

	private function readDest():String
	{
		var result:String = "";

		var dest:Int = _data.readUnsignedInt();
		//dest为0代表没有
		if (dest != 0)
		{
			_data.position -= 4;

			var index:Int = _data.readShort();
			var maskBits:Int = _data.readUnsignedByte();
			var code:Int = _data.readUnsignedByte();

			if (code == 0x3)
			{
				result = getRegPrex(code);
			}
			else if (code == 0x6)
			{
				result = getRegPrex(code);
			}
			else
			{
				result = getRegPrex(code) + index;
			}

			var mask:String = "";
			//0x0f时包含所有mask,可不写
			if (maskBits != 0x0f)
			{
				for (i in 0...4)
				{
					var t:Int = maskBits & (1 << i);
					if (t > 0)
					{
						mask += _swizzleMap.get(FastMath.log2(t));
					}
				}
			}

			if (mask.length > 0)
			{
				result += "." + mask;
			}
		}
		return result;
	}

	private function readSrc():String
	{
		var result:String = "";
		var a:Int = _data.readInt();
		var b:Int = _data.readInt();
		if (a != 0 || b != 0)
		{
			_data.position -= 8;

			var index:Int = _data.readShort();
			var offset:Int = _data.readUnsignedByte();
			var swizzleBits:Int = _data.readUnsignedByte();
			var code:Int = _data.readUnsignedByte();
			var accessCode:Int = _data.readUnsignedByte();
			var accessCompBits:Int = _data.readUnsignedByte();
			var direct:Bool = _data.readUnsignedByte() == 0;
			if (direct)
			{
				result = getRegPrex(code) + index;
			}
			else
			{
				result = getRegPrex(code) + "[";
				result += getRegPrex(accessCode) + index + "." + _swizzleMap.get(accessCompBits);
				result += "+" + offset + "]";
			}

			var swizzle:String = "";
			//如何最后几个字符相同的话，可以只保留一个
			if (swizzleBits != 0xe4)
			{
				for (i in 0...4)
				{
					var t:Int = swizzleBits >> (i * 2) & 3;
					swizzle += _swizzleMap.get(t);
				}
			}
			if (swizzle.length > 0)
			{
				result += "." + optimizeSwizzle(swizzle);
			}
		}
		return result;
	}

	/**
	 * 如何尾部有几个字符相同的话，去掉最后相同的部分,只保留一个
	 */
	private function optimizeSwizzle(swizzle:String):String
	{
		var size:Int = swizzle.length;
		if (size < 1)
		{
			return swizzle;
		}

		var char:String = swizzle.charAt(size - 1);
		while (swizzle.charAt(size - 2) == char)
		{
			swizzle = swizzle.substr(0, size - 1);
			size = swizzle.length;
			if (size < 2)
			{
				break;
			}
		}
		return swizzle;
	}
}

