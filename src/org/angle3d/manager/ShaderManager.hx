package org.angle3d.manager;

#if flash
import flash.display3D.Context3D;
import flash.display3D.Program3D;
import flash.utils.ByteArray;
import flash.Vector;
#end

import haxe.ds.StringMap;
import org.angle3d.material.sgsl.node.FunctionNode;
import org.angle3d.material.sgsl.OpCode;
import org.angle3d.material.sgsl.OpCodeManager;
import org.angle3d.material.sgsl.parser.SgslParser;
import org.angle3d.material.sgsl.SgslCompiler;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderProfile;
import org.angle3d.utils.Logger;


/**
 * 注册和注销Shader管理
 * @author andy
 */
class ShaderManager
{
	public static var instance:ShaderManager;
	public static function init(context3D:Context3D, profile:ShaderProfile):Void
	{
		instance = new ShaderManager(context3D, profile);
	}
	
	public var opCodeManager:OpCodeManager;

	private var mShaderMap:StringMap<Shader>;
	private var mProgramMap:StringMap<Program3D>;
	private var mShaderRegisterCount:StringMap<Int>;

	private var mContext3D:Context3D;
	private var mProfile:ShaderProfile;

	private var mSgslParser:SgslParser;
	private var mShaderCompiler:SgslCompiler;

	private var mNativeFunctionMap:StringMap<String>;
	private var mCustomFunctionMap:StringMap<FunctionNode>;

	public function new(context3D:Context3D, profile:ShaderProfile)
	{
		mContext3D = context3D;
		mProfile = profile;
		
		opCodeManager = new OpCodeManager(mProfile);

		mShaderMap = new StringMap<Shader>();
		mProgramMap = new StringMap<Program3D>();
		mShaderRegisterCount = new StringMap<Int>();

		
		mSgslParser = new SgslParser();
		mShaderCompiler = new SgslCompiler(mProfile, mSgslParser, opCodeManager);

		initCustomFunctions();
	}

	public function getCustomFunctionMap():StringMap<FunctionNode>
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
		var defines:Array<String> = new Array<String>();
		
		var profile:String = Std.string(mProfile);
		if (profile == "standard")
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
		
		mNativeFunctionMap = new StringMap<String>();
		
		var ba:ByteArray = new AgalLibAsset();
		ba.position = 0;
		var source:String = ba.readUTFBytes(ba.length);
		ba.clear();
		ba = null;
		
		var functionList:Array<FunctionNode> = mSgslParser.execFunctions(source, defines);
		for (funcNode in functionList)
		{
			var overloadName:String = funcNode.getNameWithParamType();
			if (mNativeFunctionMap.exists(overloadName))
			{
				throw 'Cant define same function name : ${funcNode.name} with same params';
			}
			
			mNativeFunctionMap.set(overloadName, funcNode.dataType);
		}
		
		mCustomFunctionMap = new StringMap<FunctionNode>();
		
		ba = new SgslLibAsset();
		ba.position = 0;
		source = ba.readUTFBytes(ba.length);
		ba.clear();
		ba = null;

		
		functionList = mSgslParser.execFunctions(source, defines);
		for (funcNode in functionList)
		{
			funcNode.renameTempVar();
			
			var overloadName:String = funcNode.getNameWithParamType();
			if (mCustomFunctionMap.exists(overloadName))
			{
				throw 'Cant define same function name : ${funcNode.name} with same params';
			}
			
			mCustomFunctionMap.set(overloadName, funcNode);
		}

		//need fix replaceCustomFunction
		//for (funcNode in functionList)
		//{
			//funcNode.replaceCustomFunction(mCustomFunctionMap);
		//}
	}

	public inline function isRegistered(key:String):Bool
	{
		return mShaderMap.exists(key);
	}

	public inline function getShader(key:String):Shader
	{
		return mShaderMap.get(key);
	}

	/**
	 * 注册一个Shader
	 * @param	key
	 * @param	sources Array<String>
	 * @param	conditions Array<Array<String>>
	 */
	public function registerShader(key:String, sources:Vector<String>, conditions:Array<Array<String>> = null):Shader
	{
		var shader:Shader = mShaderMap.get(key);
		if (shader == null)
		{
			shader = mShaderCompiler.complie(sources, conditions);
			shader.name = key;
			mShaderMap.set(key, shader);
		}

		//使用次数+1
		if (mShaderRegisterCount.exists(key) && !Math.isNaN(mShaderRegisterCount.get(key)))
		{
			mShaderRegisterCount.set(key, mShaderRegisterCount.get(key) + 1);
		}
		else
		{
			mShaderRegisterCount.set(key, 1);
		}

		Logger.log("[REGISTER SHADER]" + key + " count:" + mShaderRegisterCount.get(key));

		return shader;
	}

	/**
	 * 注销一个Shader,Shader引用为0时销毁对应的Progame3D
	 * @param	key
	 */
	public function unregisterShader(key:String):Void
	{
		if (!mProgramMap.exists(key))
		{
			return;
		}

		var registerCount:Int = mShaderRegisterCount.get(key);
		if (registerCount == 1)
		{
			mShaderMap.remove(key);
			mShaderRegisterCount.remove(key);

			var program:Program3D = mProgramMap.get(key);
			if (program != null)
			{
				program.dispose();
			}
			mProgramMap.remove(key);
		}
		else
		{
			mShaderRegisterCount.set(key,registerCount - 1);

			Logger.log("[UNREGISTER SHADER]" + key + " count:" + mShaderRegisterCount.get(key));
		}
	}

	public function getProgram(key:String):Program3D
	{
		if (!mProgramMap.exists(key))
		{
			var shader:Shader = mShaderMap.get(key);
			if (shader == null)
			{
				return null;
			}

			var program:Program3D = mContext3D.createProgram();
			program.upload(shader.vertexData, shader.fragmentData);
			mProgramMap.set(key,program);
		}
		return mProgramMap.get(key);
	}
}

@:file("org/angle3d/manager/sgsl.lib") class SgslLibAsset extends flash.utils.ByteArray { }
@:file("org/angle3d/manager/agal.lib") class AgalLibAsset extends flash.utils.ByteArray{}