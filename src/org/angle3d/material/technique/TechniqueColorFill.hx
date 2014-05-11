package org.angle3d.material.technique;

import flash.utils.ByteArray;
import flash.Vector;
import org.angle3d.animation.Skeleton;
import org.angle3d.light.LightType;
import org.angle3d.material.BlendMode;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.material.shader.Uniform;
import org.angle3d.material.TestFunction;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.scene.mesh.MeshType;
import org.angle3d.utils.FileUtil;

/**
 * andy
 * @author andy
 */

class TechniqueColorFill extends Technique
{
	public var influence(get, set):Float;
	public var skinningMatrices(null, set):Vector<Float>;
	public var color(get, set):UInt;
	public var alpha(get, set):Float;
	
	private var _color:Color;

	private var _influences:Vector<Float>;
	
	private var _skinningMatrices:Vector<Float>;

	public function new(color:UInt = 0xFFFFF)
	{
		super();

		renderState.applyDepthTest = true;
		renderState.depthTest = true;
		renderState.depthFunc = TestFunction.LESS_EQUAL;

		renderState.applyBlendMode = false;

		_color = new Color(0, 0, 0, 1);

		this.color = color;
	}
	
	private function set_skinningMatrices(data:Vector<Float>):Vector<Float>
	{
		return _skinningMatrices = data;
	}
	
	override private function getVertexSource():String
	{
		var source:String = FileUtil.getFileContent("shader/colorfill.vs");
		//source = StringUtil.format(source, Skeleton.MAX_BONE_COUNT * 3);
		var size:Int = Skeleton.MAX_BONE_COUNT * 3;
		return StringTools.replace(source, "{0}", size + "");
	}

	override private function getFragmentSource():String
	{
		return FileUtil.getFileContent("shader/colorfill.fs");
	}
	
	private function get_influence():Float
	{
		return _influences[1];
	}
	private function set_influence(value:Float):Float
	{
		if (_influences == null)
			_influences = new Vector<Float>(4);
		_influences[0] = 1 - value;
		_influences[1] = value;
		return value;
	}

	
	private function get_color():UInt
	{
		return _color.getColor();
	}
	private function set_color(color:UInt):UInt
	{
		_color.setRGB(color);
		return color;
	}

	private function set_alpha(alpha:Float):Float
	{
		_color.a = FastMath.clamp(alpha, 0.0, 1.0);

		if (alpha < 1)
		{
			renderState.applyBlendMode = true;
			renderState.blendMode = BlendMode.Alpha;
		}
		else
		{
			renderState.applyBlendMode = false;
			renderState.blendMode = BlendMode.Off;
		}
		
		return _color.a;
	}
	private function get_alpha():Float
	{
		return _color.a;
	}

	/**
	 * 更新Uniform属性
	 * @param	shader
	 */
	override public function updateShader(shader:Shader):Void
	{
		shader.getUniform(ShaderType.VERTEX, "u_color").setColor(_color);

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

	override private function getOption(lightType:LightType, meshType:MeshType):Array<Array<String>>
	{
		return super.getOption(lightType, meshType);
	}
}