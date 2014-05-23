package org.angle3d.material.technique;

import flash.Vector;
import org.angle3d.light.LightType;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.material.shader.Uniform;
import org.angle3d.scene.mesh.MeshType;
import org.angle3d.texture.CubeTextureMap;
import org.angle3d.texture.TextureMapBase;
import org.angle3d.utils.FileUtil;

/**
 * Reflection mapping
 * @author andy
 * @see http://developer.nvidia.com/book/export/html/86
 * @see http://en.wikipedia.org/wiki/Reflection_mapping
 */
class TechniqueReflective extends Technique
{
	public var influence(get, set):Float;
	/**
	 * 反射率，一般应该设置在0~1之间
	 */
	public var reflectivity(get, set):Float;
	public var decalMap(get, set):TextureMapBase;
	public var environmentMap(get, set):CubeTextureMap;
	
	private var _influences:Vector<Float>;

	private var _decalMap:TextureMapBase;

	private var _environmentMap:CubeTextureMap;

	private var _reflectivity:Float;

	public function new(decalMap:TextureMapBase, environmentMap:CubeTextureMap, reflectivity:Float = 0.5)
	{
		super();
		
		renderState.setDepthTest(true);

		this.decalMap = decalMap;
		this.environmentMap = environmentMap;
		this.reflectivity = reflectivity;
	}

	
	private function get_influence():Float
	{
		return _influences[1];
	}
	
	private function set_influence(value:Float):Float
	{
		if (_influences == null)
			_influences = new Vector<Float>(4);
		_influences[0] = 1 - value;
		_influences[1] = value;
		return value;
	}

	private function get_reflectivity():Float
	{
		return _reflectivity;
	}
	private function set_reflectivity(value:Float):Float
	{
		_reflectivity = value;
		if (_reflectivity < 0)
			_reflectivity = 0;
		return _reflectivity;
	}

	private function get_decalMap():TextureMapBase
	{
		return _decalMap;
	}

	private function set_decalMap(value:TextureMapBase):TextureMapBase
	{
		return _decalMap = value;
	}

	private function get_environmentMap():CubeTextureMap
	{
		return _environmentMap;
	}

	private function set_environmentMap(value:CubeTextureMap):CubeTextureMap
	{
		return _environmentMap = value;
	}

	override public function updateShader(shader:Shader):Void
	{
		shader.getUniform(ShaderType.FRAGMENT, "u_reflectivity").setFloat(_reflectivity);
		shader.getTextureParam("u_decalMap").textureMap = _decalMap;
		shader.getTextureParam("u_environmentMap").textureMap = _environmentMap;

		var uniform:Uniform = shader.getUniform(ShaderType.VERTEX, "u_influences");
		if (uniform != null)
		{
			uniform.setVector(_influences);
		}
	}
	
	override private function getVertexSource():String
	{
		return FileUtil.getFileContent("shader/reflective.vs");
	}

	override private function getFragmentSource():String
	{
		return FileUtil.getFileContent("shader/reflective.fs");
	}

	override private function getKey(lightType:LightType, meshType:MeshType):String
	{
		var result:Array<String> = [name, meshType.getName()];
		return result.join("_");
	}
}