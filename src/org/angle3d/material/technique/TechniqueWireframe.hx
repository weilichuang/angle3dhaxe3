package org.angle3d.material.technique;

import flash.utils.ByteArray;
import org.angle3d.material.CullMode;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.material.TestFunction;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;

/**
 * andy
 * @author andy
 */
//TODO 算法可能有些问题，线条过于不平滑了。Away3D中好像没这种现象
class TechniqueWireframe extends Technique
{
	public var color(get, set):UInt;
	public var alpha(get, set):Float;
	public var thickness(get, set):Float;
	
	private var _color:Color;
	private var _thickness:Float;

	public function new(color:UInt = 0xFFFFFFFF, thickness:Float = 1)
	{
		super();

		renderState.applyCullMode = true;
		renderState.cullMode = CullMode.FRONT;

		renderState.applyDepthTest = true;
		renderState.depthTest = true;
		renderState.compareMode = TestFunction.LESS_EQUAL;

		renderState.applyBlendMode = false;

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
		shader.getUniform(ShaderType.VERTEX, "u_color").setColor(_color);
		shader.getUniform(ShaderType.VERTEX, "u_thickness").setFloat(_thickness);
	}
	
	override private function initSouce():Void
	{
		var vb:ByteArray = new WireframeVS();
		mVertexSource =  vb.readUTFBytes(vb.length);
		
		var fb:ByteArray = new WireframeFS();
		mFragmentSource = fb.readUTFBytes(fb.length);
	}
}

@:file("org/angle3d/material/technique/data/wireframe.vs") 
class WireframeVS extends flash.utils.ByteArray{}
@:file("org/angle3d/material/technique/data/wireframe.fs") 
class WireframeFS extends flash.utils.ByteArray{}