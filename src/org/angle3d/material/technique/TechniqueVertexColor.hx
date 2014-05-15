package org.angle3d.material.technique;

import flash.Vector;
import org.angle3d.material.BlendMode;
import org.angle3d.material.TestFunction;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.math.FastMath;
import org.angle3d.utils.FileUtil;


/**
 * andy
 * @author andy
 */

class TechniqueVertexColor extends Technique
{
	private var _alpha:Vector<Float>;

	public function new()
	{
		super();
		
		renderState.setDepthTest(true);

		_alpha = new Vector<Float>(4, true);
	}

	public function setAlpha(alpha:Float):Void
	{
		_alpha[0] = FastMath.clamp(alpha, 0.0, 1.0);

		if (_alpha[0] < 1)
		{
			renderState.depthTest = false;
			renderState.applyBlendMode = true;
			renderState.blendMode = BlendMode.Alpha;
		}
		else
		{
			renderState.depthTest = true;
			renderState.applyBlendMode = false;
		}
	}

	public function getAlpha():Float
	{
		return _alpha[0];
	}

	/**
	 * 更新Uniform属性
	 * @param	shader
	 */
	override public function updateShader(shader:Shader):Void
	{
		shader.getUniform(ShaderType.VERTEX, "u_alpha").setVector(_alpha);
	}
	
	override private function getVertexSource():String
	{
		return FileUtil.getFileContent("shader/vertexcolor.vs");
	}

	override private function getFragmentSource():String
	{
		return FileUtil.getFileContent("shader/vertexcolor.fs");
	}
}
