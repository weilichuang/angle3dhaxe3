package org.angle3d.material.technique;
import flash.utils.ByteArray;
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

		_renderState.applyCullMode = true;
		_renderState.cullMode = CullMode.FRONT;

		_renderState.applyDepthTest = false;
		_renderState.depthTest = false;
		_renderState.compareMode = TestFunction.ALWAYS;


		_renderState.applyBlendMode = false;
		_renderState.blendMode = BlendMode.Off;
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
