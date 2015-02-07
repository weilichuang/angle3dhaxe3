package org.angle3d.material.technique;

import flash.Vector;
import org.angle3d.animation.Skeleton;
import org.angle3d.light.LightType;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.material.shader.Uniform;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.mesh.MeshType;
import org.angle3d.utils.FileUtil;


/**
 * andy
 * @author weilichuang
 */

class TechniqueNormalColor extends Technique
{
	public var influence(get, set):Float;
	public var normalScale(null, set):Vector3f;
	
	private var _influences:Vector<Float>;

	private var _normalScales:Vector<Float>;
	
	private var _skinningMatrices:Vector<Float>;

	public function new()
	{
		super();

		renderState.setDepthTest(true);

		_normalScales = new Vector<Float>(4, true);
		_normalScales[3] = 1.0;

		normalScale = new Vector3f(0.5, 0.5, 0.5);
	}

	private function set_skinningMatrices(data:Vector<Float>):Vector<Float>
	{
		return _skinningMatrices = data;
	}
	
	private function set_influence(value:Float):Float
	{
		if (_influences == null)
			_influences = new Vector<Float>(4, true);
		_influences[0] = 1 - value;
		_influences[1] = value;
		return value;
	}

	private function get_influence():Float
	{
		return _influences[1];
	}

	
	private function set_normalScale(value:Vector3f):Vector3f
	{
		_normalScales[0] = value.x;
		_normalScales[1] = value.y;
		_normalScales[2] = value.z;
		return value;
	}

	/**
	 * 更新Uniform属性
	 * @param	shader
	 */
	override public function updateShader(shader:Shader):Void
	{
		shader.getUniform(ShaderType.FRAGMENT, "u_scale").setVector(_normalScales);

		var uniform:Uniform = shader.getUniform(ShaderType.VERTEX, "u_influences");
		if (uniform != null)
		{
			uniform.setVector(_influences);
		}
	
		uniform = shader.getUniform(ShaderType.VERTEX, "u_boneMatrixs");
		if (uniform != null)
		{
			uniform.setVector(_skinningMatrices);
		}
	}
	
	override private function getVertexSource():String
	{
		var source:String = FileUtil.getFileContent("../assets/shader/normalcolor.vs");
		//source = StringUtil.format(source, Skeleton.MAX_BONE_COUNT * 3);
		var size:Int = Skeleton.MAX_BONE_COUNT * 3;
		return StringTools.replace(source, "{0}", size + "");
	}

	override private function getFragmentSource():String
	{
		return FileUtil.getFileContent("../assets/shader/normalcolor.fs");
	}

	override private function getKey(lightType:LightType, meshType:MeshType):String
	{
		return '${name}_${meshType.getName()}';
	}
}