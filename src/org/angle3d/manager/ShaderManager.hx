package org.angle3d.manager;

#if flash
import flash.display3D.Context3D;
import flash.display3D.Program3D;
import flash.utils.ByteArray;
import flash.Vector;
#end

import haxe.ds.StringMap;
import org.angle3d.material.sgsl.node.FunctionNode;
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
	public static var instance(get, null):ShaderManager;
	
	private static var _instance:ShaderManager;
	private static inline function get_instance():ShaderManager
	{
		return _instance;
	}

	public static function init(context3D:Context3D, profile:ShaderProfile):Void
	{
		_instance = new ShaderManager(context3D, profile);
	}

	private var mShaderMap:StringMap<Shader>;
	private var mProgramMap:StringMap<Program3D>;
	private var mShaderRegisterCount:StringMap<Int>;

	private var mContext3D:Context3D;
	private var mProfile:ShaderProfile;

	private var mSgslParser:SgslParser;
	private var mShaderCompiler:SgslCompiler;
	private var mOpCodeManager:OpCodeManager;

	private var mCustomFunctionMap:StringMap<FunctionNode>;

	public function new(context3D:Context3D, profile:ShaderProfile)
	{
		mContext3D = context3D;
		mProfile = profile;

		mShaderMap = new StringMap<Shader>();
		mProgramMap = new StringMap<Program3D>();
		mShaderRegisterCount = new StringMap<Int>();

		mOpCodeManager = new OpCodeManager(mProfile);
		mSgslParser = new SgslParser();
		mShaderCompiler = new SgslCompiler(mProfile, mSgslParser, mOpCodeManager);

		_initCustomFunctions();
	}

	public function getCustomFunctionMap():StringMap<FunctionNode>
	{
		return mCustomFunctionMap;
	}

	/**
	 * 编译自定义函数
	 *
	 * etaRatio2 = etaRatio*etaRatio;
	 * etaRatio3 = 1 - etaRatio2;
	 * function refract(vec3 incident,vec3 normal,vec3 etaRatio)
	 */
	//		function refract(vec3 incident,vec3 normal,float etaRatio,float etaRatio2,float etaRatio3){
	//			float t_dotNI = dot3(normal,incident);
	//			float t_dotNI2 = mul(t_dotNI,t_dotNI);
	//			float t_eta2dot2 = mul(etaRatio2,t_dotNI2);
	//			float t_k = add(etaRatio3,t_eta2dot2);
	//			float t_bool = greaterThanEqual(t_k,0.0);
	//			float t_sqrtk = sqrt(t_k);
	//			float t_tmp = mul(etaRatio,t_dotNI);
	//			t_tmp = add(t_tmp,t_sqrtk);
	//			vec3 t_vec0 = mul(incident,etaRatio);
	//			vec3 t_vec1 = mul(t_tmp,normal);
	//			vec3 t_result = sub(t_vec0,t_vec1);
	//			return mul(t_result,t_bool);  //乘以t_bool就会出现结果不正确，为什么？
	//		}
	//TODO 约束模式有几个函数用不了，需要自己自定义这几个函数
	//[Embed(source = "customOpCode.txt", mimeType = "application/octet-stream")]
	//private static var CustomOpCodeAsset:Class;

	private function _initCustomFunctions():Void
	{
		mCustomFunctionMap = new StringMap<FunctionNode>();
		
		var ba:ByteArray = new CustomOpCodeAsset();
		var source:String = ba.readUTFBytes(ba.length);

		var defines:Array<String> = new Array<String>();
		#if flash11_8
		if (mProfile == ShaderProfile.BASELINE_EXTENDED)
		{
			defines.push(cast(ShaderProfile.BASELINE, String) );
			defines.push(cast(ShaderProfile.BASELINE_EXTENDED, String) );
		}
		else if (mProfile == ShaderProfile.BASELINE)
		{
			defines.push(cast(ShaderProfile.BASELINE, String) );
		}
		else if (mProfile == ShaderProfile.BASELINE_CONSTRAINED)
		{
			defines.push(cast(ShaderProfile.BASELINE_CONSTRAINED, String) );
		}
		#else
		if (mProfile == ShaderProfile.BASELINE)
		{
			defines.push(cast(ShaderProfile.BASELINE, String) );
		}
		else if (mProfile == ShaderProfile.BASELINE_CONSTRAINED)
		{
			defines.push(cast(ShaderProfile.BASELINE_CONSTRAINED, String) );
		}
		#end

		var functionList:Array<FunctionNode> = mSgslParser.execFunctions(source, defines);

		var fLength:Int = functionList.length;
		for (i in 0...fLength)
		{
			functionList[i].renameTempVar();
			mCustomFunctionMap.set(functionList[i].name, functionList[i]);
		}

		for (i in 0...fLength)
		{
			functionList[i].replaceCustomFunction(mCustomFunctionMap);
		}
	}

	public var opCodeManager(get, null):OpCodeManager;
	private function get_opCodeManager():OpCodeManager
	{
		return mOpCodeManager;
	}

	public function isRegistered(key:String):Bool
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

@:file("org/angle3d/manager/customOpCode.lib") class CustomOpCodeAsset extends flash.utils.ByteArray{}