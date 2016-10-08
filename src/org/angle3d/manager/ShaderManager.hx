package org.angle3d.manager;

import flash.display3D.Context3D;
import flash.utils.ByteArray;
import flash.Vector;
import org.angle3d.asset.cache.SimpleAssetCache;
import org.angle3d.material.sgsl.node.FunctionNode;
import org.angle3d.material.sgsl.node.ProgramNode;
import org.angle3d.material.sgsl.OpCode;
import org.angle3d.material.sgsl.OpCodeManager;
import org.angle3d.material.sgsl.parser.SgslParser;
import org.angle3d.material.sgsl.SgslCompiler;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderKey;
import org.angle3d.material.shader.ShaderProfile;
import org.angle3d.utils.FastStringMap;
import org.angle3d.utils.Logger;



/**
 * 注册和注销Shader管理
 
 */
class ShaderManager
{
	private static var SHADER_ID:Int = 0;
	
	public static var instance:ShaderManager;
	public static function init(context3D:Context3D, profile:ShaderProfile):Void
	{
		instance = new ShaderManager(context3D, profile);
	}
	
	public var opCodeManager:OpCodeManager;

	private var mShaderCache:SimpleAssetCache<Shader>;

	private var mContext3D:Context3D;
	private var mProfile:ShaderProfile;

	private var mSgslParser:SgslParser;
	private var mShaderCompiler:SgslCompiler;

	private var mNativeFunctionMap:FastStringMap<String>;
	private var mCustomFunctionMap:FastStringMap<FunctionNode>;

	private function new(context3D:Context3D, profile:ShaderProfile)
	{
		mContext3D = context3D;
		mProfile = profile;
		
		opCodeManager = new OpCodeManager(mProfile);

		mShaderCache = new SimpleAssetCache<Shader>();

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
		var defines:Vector<String> = new Vector<String>();
		
		var profile:String = cast mProfile;
		if (profile == "standardExtended")
		{
			defines.push("baselineConstrained");
			defines.push("baseline");
			defines.push("baselineExtended");
			defines.push("standardConstrained");
			defines.push("standard");
			defines.push("standardExtended");
		}
		else if (profile == "standard")
		{
			defines.push("baselineConstrained");
			defines.push("baseline");
			defines.push("baselineExtended");
			defines.push("standardConstrained");
			defines.push("standard");
		}
		else if (profile == "standardConstrained")
		{
			defines.push("baselineConstrained");
			defines.push("baseline");
			defines.push("baselineExtended");
			defines.push("standardConstrained");
		}
		else if (profile == "baselineExtended")
		{
			defines.push("baselineConstrained");
			defines.push("baseline");
			defines.push("baselineExtended");
		}
		else if (profile == "baseline")
		{
			defines.push("baselineConstrained");
			defines.push("baseline");
		}
		else if (profile == "baselineConstrained")
		{
			defines.push("baselineConstrained");
		}
		
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

	public inline function isRegistered(key:ShaderKey):Bool
	{
		return mShaderCache.getFromCache(key) != null;
	}

	public inline function getShader(key:ShaderKey):Shader
	{
		return mShaderCache.getFromCache(key);
	}

	/**
	 * 注册一个Shader
	 * @param key
	 * @param vertexSource
	 * @param fragmentSource
	 * @param textureFormatMap 纹理格式Map
	 */
	public function registerShader(key:ShaderKey, vertexSource:String, fragmentSource:String, textureFormatMap:FastStringMap<String>):Shader
	{
		var shader:Shader = mShaderCache.getFromCache(key);
		//if (shader == null)
		//{
			//var defines:Vector<String> = key.defines.getDefines();
			//shader = mShaderCompiler.complie(vertexSource, fragmentSource, defines, defines, textureFormatMap);
			//shader.id = SHADER_ID++;
			//mShaderCache.addToCache(key, shader);
		//}

		shader.registerCount++;

		#if debug
		Logger.log("[REGISTER SHADER]" + key + " count:" + shader.registerCount);
		#end

		return shader;
	}

	/**
	 * 注销一个Shader,Shader引用为0时销毁对应的Progame3D
	 * @param	key
	 */
	public function unregisterShader(key:ShaderKey):Void
	{
		var shader:Shader = mShaderCache.getFromCache(key);
		if (shader == null)
		{
			return;
		}

		if (shader.registerCount <= 1)
		{
			shader.dispose();
			mShaderCache.deleteFromCache(key);
		}
		else
		{
			shader.registerCount--;

			#if debug
			Logger.log("[UNREGISTER SHADER]" + key + " count:" + shader.registerCount);
			#end
		}
	}
}

@:file("org/angle3d/manager/sgsl.lib") class SgslLibAsset extends flash.utils.ByteArray { }
@:file("org/angle3d/manager/agal.lib") class AgalLibAsset extends flash.utils.ByteArray{}