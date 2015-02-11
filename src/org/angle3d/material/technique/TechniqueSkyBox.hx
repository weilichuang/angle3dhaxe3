package org.angle3d.material.technique;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.Technique;
import org.angle3d.material.TestFunction;
import org.angle3d.texture.CubeTextureMap;
import org.angle3d.utils.FileUtil;


/**
 * 天空体
 * @author weilichuang
 */

class TechniqueSkyBox extends Technique
{
	private var mCubeTexture:CubeTextureMap;

	public function new(cubeTexture:CubeTextureMap)
	{
		super();

		mCubeTexture = cubeTexture;
		
		renderState.setCullMode(CullMode.FRONT);
		renderState.setDepthWrite(false);
		renderState.setDepthTest(true);
		renderState.setDepthFunc(TestFunction.ALWAYS);
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
		return FileUtil.getFileContent("../assets/shader/skybox_new.vs");
	}

	override private function getFragmentSource():String
	{
		return FileUtil.getFileContent("../assets/shader/skybox_new.fs");
	}
}