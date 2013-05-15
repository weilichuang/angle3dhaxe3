package org.angle3d.material.technique;

import haxe.ds.StringMap;
import org.angle3d.light.LightType;
import org.angle3d.manager.ShaderManager;
import org.angle3d.material.RenderState;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.UniformBindingHelp;
import org.angle3d.material.TechniqueDef;
import org.angle3d.scene.mesh.MeshType;

/**
 * Technique可能对应多个Shader
 * @author andy
 */
class Technique
{
	public var def:TechniqueDef;

	private var _name:String;

	private var _shaderMap:StringMap<Shader>;
	private var _optionMap:StringMap<Array<Array<String>>>;

	private var _renderState:RenderState;

	private var _requiresLight:Bool;

	private var _keys:Array<String>;

	public function new()
	{
		_initInternal();

		_name = Type.getClassName(Type.getClass(this));
		
		_keys = [];
	}

	public var name(get, null):String;
	private function get_name():String
	{
		return _name;
	}

	public var renderState(get, null):RenderState;
	private function get_renderState():RenderState
	{
		return _renderState;
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

		var shader:Shader = _shaderMap.get(key);

		if (shader == null)
		{
			if (!_optionMap.exists(key))
			{
				_optionMap.set(key, getOption(lightType, meshType));
			}

			var vstr:String = getVertexSource();
			var fstr:String = getFragmentSource();

			var option:Array<Array<String>> = _optionMap.get(key);

			shader = ShaderManager.instance.registerShader(key, [vstr, fstr], option);

			shader.setUniformBindings(getBindUniforms(lightType, meshType));
			shader.setAttributeBindings(getBindAttributes(lightType, meshType));

			_shaderMap.set(key,shader);
		}

		return shader;
	}

	private function _initInternal():Void
	{
		_shaderMap = new StringMap<Shader>();
		_optionMap = new StringMap<Array<Array<String>>>();

		_renderState = new RenderState();
		_requiresLight = false;
	}

	public var requiresLight(get,set):Bool;
	private function get_requiresLight():Bool
	{
		return _requiresLight;
	}

	private function set_requiresLight(value:Bool):Bool
	{
		_requiresLight = value;
		return _requiresLight;
	}

	private function getBindUniforms(lightType:LightType, meshType:MeshType):Array<UniformBindingHelp>
	{
		return null;
	}

	private function getBindAttributes(lightType:LightType, meshType:MeshType):StringMap<String>
	{
		return null;
	}

	private function getVertexSource():String
	{
		return "";
	}

	private function getFragmentSource():String
	{
		return "";
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
		return _name;
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

