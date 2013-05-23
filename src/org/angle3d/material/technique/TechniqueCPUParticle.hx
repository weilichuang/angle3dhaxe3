package org.angle3d.material.technique;

import flash.utils.ByteArray;
import org.angle3d.light.LightType;
import org.angle3d.material.BlendMode;
import org.angle3d.material.CullMode;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.TestFunction;
import org.angle3d.scene.mesh.MeshType;
import org.angle3d.texture.TextureMapBase;


/**
 * andy
 * @author andy
 */

class TechniqueCPUParticle extends Technique
{
	public var texture(get, set):TextureMapBase;
	
	private var _texture:TextureMapBase;

	public function new()
	{
		super();

		renderState.applyCullMode = true;
		renderState.cullMode = CullMode.FRONT;

		renderState.applyDepthTest = true;
		renderState.depthTest = false;
		renderState.compareMode = TestFunction.LESS_EQUAL;

		renderState.applyBlendMode = true;
		renderState.blendMode = BlendMode.AlphaAdditive;
	}

	
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

	override private function getVertexSource():String
	{
		var vb:ByteArray = new CPUParticleVS();
		return vb.readUTFBytes(vb.length);
	}

	override private function getFragmentSource():String
	{
		var fb:ByteArray = new CPUParticleFS();
		return fb.readUTFBytes(fb.length);
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
}

@:file("org/angle3d/material/technique/data/cpuparticle.vs") 
class CPUParticleVS extends flash.utils.ByteArray{}
@:file("org/angle3d/material/technique/data/cpuparticle.fs") 
class CPUParticleFS extends flash.utils.ByteArray{}

