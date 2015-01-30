package org.angle3d.material.technique;

import haxe.ds.StringMap;
import org.angle3d.light.LightType;
import org.angle3d.manager.ShaderManager;
import org.angle3d.material.RenderState;
import org.angle3d.material.shader.Shader;
import org.angle3d.scene.mesh.MeshType;

typedef TechniquePredefine = {
	var vertex:Array<String>;
	var fragment:Array<String>;
}

class Technique
{
	public var name(default, null):String;
	public var renderState(get, null):RenderState;
	public var requiresLight(get,set):Bool;

	private var mShaderMap:StringMap<Shader>;
	private var mPreDefineMap:StringMap<TechniquePredefine>;

	private var mRenderState:RenderState;

	private var mRequiresLight:Bool;

	private var _keys:Array<String>;
	
	private var vertexSource:String;
	private var fragmentSource:String;

	public function new()
	{
		initialize();
	}
	
	private function initSouce():Void
	{
		vertexSource = getVertexSource();
		fragmentSource = getFragmentSource();
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
			if (!mPreDefineMap.exists(key))
			{
				mPreDefineMap.set(key, getPredefine(lightType, meshType));
			}

			var option:TechniquePredefine = mPreDefineMap.get(key);

			shader = ShaderManager.instance.registerShader(key, vertexSource,fragmentSource,option.vertex,option.fragment);

			mShaderMap.set(key,shader);
		}

		return shader;
	}

	private function initialize():Void
	{
		name = Type.getClassName(Type.getClass(this)).split(".").pop();
		
		_keys = [];
		
		mShaderMap = new StringMap<Shader>();
		mPreDefineMap = new StringMap<TechniquePredefine>();

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
		return mRequiresLight = value;
	}

	
	private function getVertexSource():String
	{
		return "";
	}

	private function getFragmentSource():String
	{
		return "";
	}

	private function getPredefine(lightType:LightType, meshType:MeshType):TechniquePredefine
	{
		var predefine = { vertex:[], fragment:[] };

		if (meshType == MeshType.KEYFRAME)
		{
			predefine.vertex.push("USE_KEYFRAME");
		}
		else if (meshType == MeshType.SKINNING)
		{
			predefine.fragment.push("USE_SKINNING");
		}

		return predefine;
	}

	private function getKey(lightType:LightType, meshType:MeshType):String
	{
		return name + "_" + meshType.getName();
	}
}

