package org.angle3d.material.technique;

import flash.utils.ByteArray;
import org.angle3d.light.LightType;
import org.angle3d.material.BlendMode;
import org.angle3d.material.CullMode;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.TestFunction;
import org.angle3d.scene.mesh.MeshType;
import org.angle3d.texture.TextureMapBase;
import org.angle3d.utils.FileUtil;


/**
 * andy
 * @author weilichuang
 */

class TechniqueCPUParticle extends Technique
{
	public var texture(get, set):TextureMapBase;
	
	private var _texture:TextureMapBase;

	public function new()
	{
		super();

		renderState.setDepthWrite(false);
		renderState.setDepthTest(true);
		renderState.setBlendMode(BlendMode.AlphaAdditive);
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
		shader.getTextureParam("s_texture").textureMap = _texture;
	}

	override private function getVertexSource():String
	{
		return FileUtil.getFileContent("shader/cpuparticle.vs");
	}

	override private function getFragmentSource():String
	{
		return FileUtil.getFileContent("shader/cpuparticle.fs");
	}

	override private function getKey(lightType:LightType, meshType:MeshType):String
	{
		var result:Array<String> = [name, meshType.getName()];
		return result.join("_");
	}
}