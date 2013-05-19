package org.angle3d.material.technique;

import flash.utils.ByteArray;
import haxe.ds.StringMap;
import org.angle3d.light.LightType;
import org.angle3d.material.BlendMode;
import org.angle3d.material.CullMode;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.material.shader.UniformBinding;
import org.angle3d.material.shader.UniformBindingHelp;
import org.angle3d.material.TestFunction;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.MeshType;
import org.angle3d.texture.TextureMapBase;


/**
 * andy
 * @author andy
 */

class TechniqueCPUParticle extends Technique
{
	private var _texture:TextureMapBase;

	public function new()
	{
		super();

		_renderState.applyCullMode = true;
		_renderState.cullMode = CullMode.FRONT;

		_renderState.applyDepthTest = true;
		_renderState.depthTest = false;
		_renderState.compareMode = TestFunction.LESS_EQUAL;

		_renderState.applyBlendMode = true;
		_renderState.blendMode = BlendMode.AlphaAdditive;
	}

	public var texture(get, set):TextureMapBase;
	private function get_texture():TextureMapBase
	{
		return _texture;
	}

	private function set_texture(value:TextureMapBase):TextureMapBase
	{
		return _texture = value;
	}

	/**
	 * 更新Uniform属性
	 * @param	shader
	 */
	override public function updateShader(shader:Shader):Void
	{
		shader.getTextureVar("s_texture").textureMap = _texture;
	}
	
	override private function initSouce():Void
	{
		var vb:ByteArray = new CPUParticleVS();
		mVertexSource =  vb.readUTFBytes(vb.length);
		
		var fb:ByteArray = new CPUParticleFS();
		mFragmentSource = fb.readUTFBytes(fb.length);
	}

	override private function getOption(lightType:LightType, meshType:MeshType):Array<Array<String>>
	{
		var results:Array<Array<String>> = super.getOption(lightType, meshType);
		return results;
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
		map.set(BufferType.COLOR, "a_color");
		return map;
	}
}

@:file("org/angle3d/material/technique/data/cpuparticle.vs") 
class CPUParticleVS extends flash.utils.ByteArray{}
@:file("org/angle3d/material/technique/data/cpuparticle.fs") 
class CPUParticleFS extends flash.utils.ByteArray{}

