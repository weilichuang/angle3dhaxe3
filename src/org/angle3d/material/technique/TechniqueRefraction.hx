package org.angle3d.material.technique;

import flash.utils.ByteArray;
import flash.Vector;
import haxe.ds.StringMap;
import org.angle3d.light.LightType;
import org.angle3d.material.CullMode;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.material.shader.UniformBinding;
import org.angle3d.material.shader.UniformBindingHelp;
import org.angle3d.material.TestFunction;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.MeshType;
import org.angle3d.texture.CubeTextureMap;
import org.angle3d.texture.TextureMapBase;

/**
 * Reflection mapping
 * @author andy
 * @see http://developer.nvidia.com/book/export/html/86
 * @see http://en.wikipedia.org/wiki/Reflection_mapping
 */
class TechniqueRefraction extends Technique
{
	private var _decalMap:TextureMapBase;

	private var _environmentMap:CubeTextureMap;

	private var _transmittance:Float;

	private var _etaRatios:Vector<Float>;

	public function new(decalMap:TextureMapBase, environmentMap:CubeTextureMap, etaRatio:Float = 1.5, transmittance:Float = 0.5)
	{
		super();

		_renderState.applyCullMode = true;
		_renderState.cullMode = CullMode.FRONT;

		_renderState.applyDepthTest = true;
		_renderState.depthTest = true;
		_renderState.compareMode = TestFunction.LESS_EQUAL;

		_renderState.applyBlendMode = false;

		_etaRatios = new Vector<Float>(4);

		this.decalMap = decalMap;
		this.environmentMap = environmentMap;
		this.etaRatio = etaRatio;
		this.transmittance = transmittance;
	}

	public var etaRatio(get, set):Float;
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

	

	/**
	 * 反射率，一般应该设置在0~1之间
	 */
	public var transmittance(get, set):Float;
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

	
	public var decalMap(get, set):TextureMapBase;
	private function get_decalMap():TextureMapBase
	{
		return _decalMap;
	}

	private function set_decalMap(value:TextureMapBase):TextureMapBase
	{
		return _decalMap = value;
	}

	public var environmentMap(get, set):CubeTextureMap;
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
		shader.getTextureVar("u_decalMap").textureMap = _decalMap;
		shader.getTextureVar("u_environmentMap").textureMap = _environmentMap;
	}
	
	override private function initSouce():Void
	{
		var vb:ByteArray = new RefractionVS();
		mVertexSource =  vb.readUTFBytes(vb.length);
		
		var fb:ByteArray = new RefractionFS();
		mFragmentSource = fb.readUTFBytes(fb.length);
	}

	override private function getKey(lightType:LightType, meshType:MeshType):String
	{
		var result:Array<String> = [name, meshType.getName()];
		return result.join("_");
	}

	override private function getBindAttributes(lightType:LightType, meshType:MeshType):StringMap<String>
	{
		var map:StringMap<String> = new StringMap<String>();
		map.set(BufferType.POSITION, "a_position");
		map.set(BufferType.TEXCOORD, "a_texCoord");
		map.set(BufferType.NORMAL, "a_normal");
		return map;
	}

	override private function getBindUniforms(lightType:LightType, meshType:MeshType):Array<UniformBindingHelp>
	{
		var list:Array<UniformBindingHelp> = new Array<UniformBindingHelp>();
		list.push(new UniformBindingHelp(ShaderType.VERTEX, "u_WorldViewProjectionMatrix", UniformBinding.WorldViewProjectionMatrix));
		list.push(new UniformBindingHelp(ShaderType.VERTEX, "u_worldMatrix", UniformBinding.WorldMatrix));
		list.push(new UniformBindingHelp(ShaderType.VERTEX, "u_camPosition", UniformBinding.CameraPosition));
		
		return list;
	}
}


@:file("org/angle3d/material/technique/data/refraction.vs") 
class RefractionVS extends flash.utils.ByteArray{}
@:file("org/angle3d/material/technique/data/refraction.fs") 
class RefractionFS extends flash.utils.ByteArray{}
