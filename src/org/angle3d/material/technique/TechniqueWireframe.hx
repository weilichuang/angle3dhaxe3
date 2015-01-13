package org.angle3d.material.technique;

import org.angle3d.light.LightType;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.scene.mesh.MeshType;
import org.angle3d.utils.FileUtil;

/**
 * wireframe,only support static object.
 * @author weilichuang
 */
class TechniqueWireframe extends Technique
{
	public var color(get, set):UInt;
	public var alpha(get, set):Float;
	public var thickness(get, set):Float;
	public var useVertexColor(get, set):Bool;
	
	private var _color:Color;
	private var _thickness:Float;
	
	private var _useVertexColor:Bool = false;

	public function new(color:UInt = 0xFFFFFFFF, thickness:Float = 1)
	{
		super();

		renderState.setDepthTest(true);

		_color = new Color();

		this.color = color;
		this.thickness = thickness;
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
	
	private function get_useVertexColor():Bool
	{
		return _useVertexColor;
	}
	
	private function set_useVertexColor(value:Bool):Bool
	{
		return _useVertexColor = value;
	}

	
	private function get_alpha():Float
	{
		return _color.a;
	}
	private function set_alpha(alpha:Float):Float
	{
		return _color.a = FastMath.clamp(alpha, 0.0, 1.0);
	}

	
	private function get_thickness():Float
	{
		return _thickness;
	}
	private function set_thickness(thickness:Float):Float
	{
		return _thickness = thickness * 0.001;
	}

	override public function updateShader(shader:Shader):Void
	{
		if(!useVertexColor)
			shader.getUniform(ShaderType.VERTEX, "u_color").setColor(_color);
			
		shader.getUniform(ShaderType.VERTEX, "u_thickness").setFloat(_thickness);
	}
	
	override private function getVertexSource():String
	{
		return FileUtil.getFileContent("shader/wireframe.vs");
	}

	override private function getFragmentSource():String
	{
		return FileUtil.getFileContent("shader/wireframe.fs");
	}
	
	override private function getOption(lightType:LightType, meshType:MeshType):Array<Array<String>>
	{
		var results:Array<Array<String>> = new Array<Array<String>>();
		results[0] = [];
		results[1] = [];

		if (useVertexColor)
		{
			results[0].push("USE_VERTEX_COLOR");
		}

		return results;
	}
}