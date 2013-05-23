package org.angle3d.material.technique;

import haxe.ds.StringMap;
import org.angle3d.light.LightType;
import org.angle3d.manager.ShaderManager;
import org.angle3d.material.RenderState;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.TechniqueDef;
import org.angle3d.scene.mesh.MeshType;

/**
 * Technique可能对应多个Shader
 * @author andy
 */
class Technique
{
	public var def:TechniqueDef;
	
	public var name(default, null):String;
	public var renderState(get, null):RenderState;
	public var requiresLight(get,set):Bool;

	private var mShaderMap:StringMap<Shader>;
	private var mOptionMap:StringMap<Array<Array<String>>>;

	private var mRenderState:RenderState;

	private var mRequiresLight:Bool;

	private var _keys:Array<String>;
	
	private var mVertexSource:String;
	private var mFragmentSource:String;

	public function new()
	{
		initialize();
	}
	
	private function initSouce():Void
	{
		
	}
	
	private function get_renderState():RenderState
	{
		return mRenderState;
	}

	/**
	 * 更新Shader属性
	 *
	 * @param	shader
	 */
	public function updateShader(shader:Shader):Void
	{

	}

	/**
	 * 获取Shader时，需要更新其UniformBinding
	 * @param	lightType
	 * @param	meshKey
	 * @return
	 */
	public function getShader(lightType:LightType, meshType:MeshType):Shader
	{
		var key:String = getKey(lightType, meshType);

		var shader:Shader = mShaderMap.get(key);

		if (shader == null)
		{
			if (!mOptionMap.exists(key))
			{
				mOptionMap.set(key, getOption(lightType, meshType));
			}

			var vstr:String = getVertexSource();
			var fstr:String = getFragmentSource();

			var option:Array<Array<String>> = mOptionMap.get(key);

			shader = ShaderManager.instance.registerShader(key, [vstr, fstr], option);

			mShaderMap.set(key,shader);
		}

		return shader;
	}

	private function initialize():Void
	{
		name = Type.getClassName(Type.getClass(this));
		
		_keys = [];
		
		mShaderMap = new StringMap<Shader>();
		mOptionMap = new StringMap<Array<Array<String>>>();

		mRenderState = new RenderState();
		mRequiresLight = false;
		
		initSouce();
	}

	
	private function get_requiresLight():Bool
	{
		return mRequiresLight;
	}

	private function set_requiresLight(value:Bool):Bool
	{
		mRequiresLight = value;
		return mRequiresLight;
	}

	
	private function getVertexSource():String
	{
		return mVertexSource;
	}

	private function getFragmentSource():String
	{
		return mFragmentSource;
	}

	private function getOption(lightType:LightType, meshType:MeshType):Array<Array<String>>
	{
		var results:Array<Array<String>> = new Array<Array<String>>();
		results[0] = [];
		results[1] = [];

		if (meshType == MeshType.KEYFRAME)
		{
			results[0].push("USE_KEYFRAME");
		}
		else if (meshType == MeshType.SKINNING)
		{
			results[0].push("USE_SKINNING");
		}

		return results;
	}

	private function getKey(lightType:LightType, meshType:MeshType):String
	{
		return "";
	}

	/**
	 * Called by the material to tell the technique a parameter was modified.
	 * Specify <code>null</code> for value if the param is to be cleared.
	 */
	public function notifyParamChanged(paramName:String, type:String, value:Dynamic):Void
	{
		// Check if there's a define binding associated with this
		// parameter.
		var defineName:String = def.getShaderParamDefine(paramName);
		if (defineName != null)
		{
			// There is a define. Change it on the define list.
			// The "needReload" variable will determine
			// if the shader will be reloaded when the material
			// is rendered.

//				if (value == null)
//				{
//					// Clear the define.
//					needReload = defines.remove(defineName) || needReload;
//				}
//				else
//				{
//					// set_the define.
//					needReload = defines.set(defineName, type, value) || needReload;
//				}
		}
	}
}

