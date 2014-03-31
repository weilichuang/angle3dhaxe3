package org.angle3d.material.technique;

import flash.Vector;
import org.angle3d.light.LightType;
import org.angle3d.material.CompareMode;
import org.angle3d.material.CullMode;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderType;
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
class TechniqueRefraction extends Technique
{
	public var etaRatio(get, set):Float;
	/**
	 * 反射率，一般应该设置在0~1之间
	 */
	public var transmittance(get, set):Float;
	public var decalMap(get, set):TextureMapBase;
	public var environmentMap(get, set):CubeTextureMap;
	
	private var _decalMap:TextureMapBase;

	private var _environmentMap:CubeTextureMap;

	private var _transmittance:Float;

	private var _etaRatios:Vector<Float>;

	public function new(decalMap:TextureMapBase, environmentMap:CubeTextureMap, etaRatio:Float = 1.5, transmittance:Float = 0.5)
	{
		super();

		renderState.applyCullMode = true;
		renderState.cullMode = CullMode.FRONT;

		renderState.applyDepthTest = true;
		renderState.depthTest = true;
		renderState.compareMode = CompareMode.LESS_EQUAL;

		renderState.applyBlendMode = false;

		_etaRatios = new Vector<Float>(4);

		this.decalMap = decalMap;
		this.environmentMap = environmentMap;
		this.etaRatio = etaRatio;
		this.transmittance = transmittance;
	}

	
	private function get_etaRatio():Float
	{
		return _etaRatios[0];
	}
	
	private function set_etaRatio(value:Float):Float
	{
//			if (value < 1.0)
//				value = 1.0;
		_etaRatios[0] = value;
		_etaRatios[1] = value * value;
		_etaRatios[2] = 1.0 - _etaRatios[1];
		return _etaRatios[0];
	}

	private function get_transmittance():Float
	{
		return _transmittance;
	}
	
	private function set_transmittance(value:Float):Float
	{
		_transmittance = value;
		if (_transmittance < 0)
			_transmittance = 0;
		return _transmittance;
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
		shader.getUniform(ShaderType.VERTEX, "u_etaRatio").setVector(_etaRatios);
		shader.getUniform(ShaderType.FRAGMENT, "u_transmittance").setFloat(_transmittance);
		shader.getTextureParam("u_decalMap").textureMap = _decalMap;
		shader.getTextureParam("u_environmentMap").textureMap = _environmentMap;
	}
	
	override private function getVertexSource():String
	{
		return FileUtil.getFileContent("shader/refraction.vs");
	}

	override private function getFragmentSource():String
	{
		return FileUtil.getFileContent("shader/refraction.fs");
	}

	override private function getKey(lightType:LightType, meshType:MeshType):String
	{
		var result:Array<String> = [name, meshType.getName()];
		return result.join("_");
	}
}