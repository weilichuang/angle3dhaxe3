package org.angle3d.manager;

import flash.Vector;
import flash.display3D.Context3D;
import flash.utils.ByteArray;
import haxe.ds.IntMap;
import haxe.ds.StringMap;
import org.angle3d.ds.FastStringMap;
import org.angle3d.material.sgsl.OpCode;
import org.angle3d.material.sgsl.OpCodeManager;
import org.angle3d.material.sgsl.SgslCompiler;
import org.angle3d.material.sgsl.node.FunctionNode;
import org.angle3d.material.sgsl.node.ProgramNode;
import org.angle3d.material.sgsl.parser.SgslParser;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderProfile;
import org.angle3d.utils.Logger;

/**
 * 注册和注销Shader管理
 */
class ShaderManager
{
	public static var instance:ShaderManager;
	public static function init(context3D:Context3D, profile:ShaderProfile):Void
	{
		instance = new ShaderManager(context3D, profile);
	}
	
	public var opCodeManager:OpCodeManager;

	private var mContext3D:Context3D;
	private var mProfile:ShaderProfile;

	private var mSgslParser:SgslParser;
	private var mShaderCompiler:SgslCompiler;

	private var mNativeFunctionMap:FastStringMap<String>;
	private var mCustomFunctionMap:FastStringMap<FunctionNode>;
	
	private var _shaderCode2Id:FastStringMap<Int>;
	private var _compiledShaderCount : Int = 0;
	private var _shaderCache:IntMap<Shader>;

	private function new(context3D:Context3D, profile:ShaderProfile)
	{
		mContext3D = context3D;
		mProfile = profile;
		
		opCodeManager = new OpCodeManager(mProfile);

		_shaderCode2Id = new FastStringMap<Int>();
		_compiledShaderCount = 0;
		_shaderCache = new IntMap<Shader>();

		mSgslParser = new SgslParser();
		mShaderCompiler = new SgslCompiler(mProfile, mSgslParser, opCodeManager);

		initCustomFunctions();
	}
	
	public var sgslParser(get, null):SgslParser;
	private inline function get_sgslParser():SgslParser
	{
		return mSgslParser;
	}

	public function getCustomFunctionMap():FastStringMap<FunctionNode>
	{
		return mCustomFunctionMap;
	}
	
	public function isNativeFunction(funcName:String):Bool
	{
		return opCodeManager.getCode(funcName) != null;
	}
	
	public function hasFunction(funcName:String,paramName:String):Bool
	{
		var opCode:OpCode = opCodeManager.getCode(funcName);
		if (opCode != null)
		{
			funcName = opCode.names[0];
		}
		
		var key:String = paramName.length > 0 ? funcName + "_" + paramName : funcName;
		
		return mNativeFunctionMap.exists(key) || mCustomFunctionMap.exists(key);
	}
	
	public function getCustomFunction(nameWithParamType:String):FunctionNode
	{
		return mCustomFunctionMap.get(nameWithParamType);
	}
	
	public function getFunctionDataType(funcName:String, paramName:String):String
	{
		var opCode:OpCode = opCodeManager.getCode(funcName);
		if (opCode != null)
		{
			funcName = opCode.names[0];
		}
		
		var key:String = paramName.length > 0 ? funcName + "_" + paramName : funcName;
		
		if (mNativeFunctionMap.exists(key))
		{
			return mNativeFunctionMap.get(key);
		}
		
		if (mCustomFunctionMap.exists(key))
			return mCustomFunctionMap.get(key).dataType;
			
		return null;
	}
	
	/**
	 * 编译自定义函数
	 * 约束模式有几个函数用不了，需要自己自定义这几个函数
	 */
	private function initCustomFunctions():Void
	{
		var defines:Vector<String>;
		
		var allProfiles:Array<String> = ["baselineConstrained", "baseline", "baselineExtended",
		"standardConstrained", "standard", "standardExtended"];
		
		var profile:String = cast mProfile;
		defines = Vector.ofArray(allProfiles.slice(0, allProfiles.indexOf(profile) + 1));
		
		//原生函数，用于语法检查，函数内并不包含实际内容
		mNativeFunctionMap = new FastStringMap<String>();
		
		var ba:ByteArray = new AgalLibAsset();
		ba.position = 0;
		var source:String = ba.readUTFBytes(ba.length);
		ba.clear();
		ba = null;

		var programNode:ProgramNode = mSgslParser.execFunctions(source, defines);
		for (i in 0...programNode.numChildren)
		{
			var funcNode:FunctionNode = cast programNode.children[i];
			var overloadName:String = funcNode.getNameWithParamType();
			if (mNativeFunctionMap.exists(overloadName))
			{
				throw 'Cant define same function name : ${funcNode.name} with same params';
			}
			
			mNativeFunctionMap.set(overloadName, funcNode.dataType);
		}
		
		mCustomFunctionMap = new FastStringMap<FunctionNode>();
		
		ba = new SgslLibAsset();
		ba.position = 0;
		source = ba.readUTFBytes(ba.length);
		ba.clear();
		ba = null;

		//这里只解析出基本的结构体，不进行进一步处理，具体的语法判断放到真正Shader解析的地方处理
		programNode = mSgslParser.execFunctions(source, defines);
		for (i in 0...programNode.numChildren)
		{
			var funcNode:FunctionNode = cast programNode.children[i];
			var overloadName:String = funcNode.getNameWithParamType();
			if (mCustomFunctionMap.exists(overloadName))
			{
				throw 'Cant define same function name : ${funcNode.name} with same params';
			}
			mCustomFunctionMap.set(overloadName, funcNode);
		}
	}

	/**
	 * 注册一个Shader
	 * @param vertexSource
	 * @param fragmentSource
	 */
	public function registerShader(vertexSource:String, fragmentSource:String):Shader
	{
		var vertexCodeId : Int = shaderCode2Id( vertexSource );
		if ( vertexCodeId == -1) 
		{
			vertexCodeId = _compiledShaderCount;
			_shaderCode2Id.set(vertexSource, vertexCodeId);
			_compiledShaderCount++;
		}
		
		var fragCodeId : Int = shaderCode2Id( fragmentSource );
		if ( fragCodeId == -1) 
		{
			fragCodeId = _compiledShaderCount;
			_shaderCode2Id.set(fragmentSource, fragCodeId);
			_compiledShaderCount++;
		}
		
		var shader:Shader = null;
		var programeKey : Int = getShaderKey( vertexCodeId, fragCodeId );
		if ( !_shaderCache.exists(programeKey) )
		{
			shader = mShaderCompiler.complie(vertexSource, fragmentSource);
			shader.id = programeKey;
			_shaderCache.set(programeKey, shader);
		}
		else
		{
			shader = _shaderCache.get(programeKey);
		}

		shader.registerCount++;

		//#if debug
		//Logger.log("[REGISTER SHADER]\n" + vertexSource+"\n" + fragmentSource + "\n" + " count:" + shader.registerCount);
		//#end

		return shader;
	}

	/**
	 * 注销一个Shader,Shader引用为0时销毁对应的Progame3D
	 * @param shader
	 */
	public function unregisterShader(shader:Shader):Void
	{
		if (shader.registerCount > 0)
		{
			shader.registerCount--;

			//#if debug
			//Logger.log("[UNREGISTER SHADER]" + shader + " count:" + shader.registerCount);
			//#end
		}
	}
	
	private inline function getShaderKey( vertexId : Int, fragmentId : Int ) : Int
	{
		#if debug
		if ( vertexId <= -1 || fragmentId <= -1 )
		{
			throw "NoShaderFindError";
		}
		if ( vertexId >= 65536 || fragmentId >= 65536 ) 
		{
			throw "ShaderExceedsIdxError";
		}
		#end
		
		return (vertexId << 16) + fragmentId;
	}
	
	private function shaderCode2Id( code : String ) : Int 
	{
		if ( _shaderCode2Id.exists(code) )
		{
			return _shaderCode2Id.get(code);
		}
		return -1;
	}
}

@:file("org/angle3d/manager/sgsl.lib") class SgslLibAsset extends flash.utils.ByteArray{}
@:file("org/angle3d/manager/agal.lib") class AgalLibAsset extends flash.utils.ByteArray{}