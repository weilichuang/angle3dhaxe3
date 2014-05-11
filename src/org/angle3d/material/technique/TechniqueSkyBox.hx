package org.angle3d.material.technique;
import flash.utils.ByteArray;
import org.angle3d.material.CullMode;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.TestFunction;
import org.angle3d.texture.CubeTextureMap;
import org.angle3d.utils.FileUtil;


/**
 * 天空体
 * @author andy
 */

class TechniqueSkyBox extends Technique
{
	private var mCubeTexture:CubeTextureMap;

	public function new(cubeTexture:CubeTextureMap)
	{
		super();

		mCubeTexture = cubeTexture;

		renderState.applyCullMode = true;
		renderState.cullMode = CullMode.FRONT;

		renderState.applyDepthTest = false;
		renderState.depthTest = false;
		renderState.depthFunc = TestFunction.ALWAYS;


		renderState.applyBlendMode = false;
		renderState.blendMode = BlendMode.Off;
	}

	/**
	 * 更新Uniform属性
	 * @param	shader
	 */
	override public function updateShader(shader:Shader):Void
	{
		shader.getTextureParam("t_cubeTexture").textureMap = mCubeTexture;
	}

	override private function getVertexSource():String
	{
		return FileUtil.getFileContent("shader/skybox_new.vs");
	}

	override private function getFragmentSource():String
	{
		return FileUtil.getFileContent("shader/skybox_new.fs");
	}
}