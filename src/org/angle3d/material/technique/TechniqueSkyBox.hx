package org.angle3d.material.technique;
import flash.utils.ByteArray;
import org.angle3d.material.CullMode;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.TestFunction;
import org.angle3d.texture.CubeTextureMap;


/**
 * 天空体
 * @author andy
 */

class TechniqueSkyBox extends Technique
{
	private var _cubeTexture:CubeTextureMap;

	public function new(cubeTexture:CubeTextureMap)
	{
		super();

		_cubeTexture = cubeTexture;

		renderState.applyCullMode = true;
		renderState.cullMode = CullMode.FRONT;

		renderState.applyDepthTest = false;
		renderState.depthTest = false;
		renderState.compareMode = TestFunction.ALWAYS;


		renderState.applyBlendMode = false;
		renderState.blendMode = BlendMode.Off;
	}

	/**
	 * 更新Uniform属性
	 * @param	shader
	 */
	override public function updateShader(shader:Shader):Void
	{
		shader.getTextureVar("t_cubeTexture").textureMap = _cubeTexture;
	}
	
	override private function initSouce():Void
	{
		var vb:ByteArray = new SkyBoxVS();
		mVertexSource =  vb.readUTFBytes(vb.length);
		
		var fb:ByteArray = new SkyBoxFS();
		mFragmentSource = fb.readUTFBytes(fb.length);
	}
}

@:file("org/angle3d/material/technique/data/skybox.vs") 
class SkyBoxVS extends flash.utils.ByteArray{}
@:file("org/angle3d/material/technique/data/skybox.fs") 
class SkyBoxFS extends flash.utils.ByteArray{}
