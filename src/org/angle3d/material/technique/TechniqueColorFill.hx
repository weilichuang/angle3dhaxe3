package org.angle3d.material.technique;

import flash.utils.ByteArray;
import haxe.ds.StringMap;
import flash.Vector;
import org.angle3d.light.LightType;
import org.angle3d.material.BlendMode;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.material.shader.Uniform;
import org.angle3d.material.shader.UniformBinding;
import org.angle3d.material.shader.UniformBindingHelp;
import org.angle3d.material.TestFunction;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.MeshType;

/**
 * andy
 * @author andy
 */

class TechniqueColorFill extends Technique
{
	private var _color:Color;

	private var _influences:Vector<Float>;

	public function new(color:UInt = 0xFFFFF)
	{
		super();

		_renderState.applyDepthTest = true;
		_renderState.depthTest = true;
		_renderState.compareMode = TestFunction.LESS_EQUAL;

		_renderState.applyBlendMode = false;

		_color = new Color(0, 0, 0, 1);

		this.color = color;
	}
	
	override private function initSouce():Void
	{
		var vb:ByteArray = new ColorFillVS();
		mVertexSource =  vb.readUTFBytes(vb.length);
		
		var fb:ByteArray = new ColorFillFS();
		mFragmentSource = fb.readUTFBytes(fb.length);
	}
	
	public var influence(get, set):Float;
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

	public var color(get, set):UInt;
	private function get_color():UInt
	{
		return _color.getColor();
	}
	private function set_color(color:UInt):UInt
	{
		_color.setRGB(color);
		return color;
	}

	public var alpha(get, set):Float;
	private function set_alpha(alpha:Float):Float
	{
		_color.a = FastMath.clamp(alpha, 0.0, 1.0);

		if (alpha < 1)
		{
			_renderState.applyBlendMode = true;
			_renderState.blendMode = BlendMode.Alpha;
		}
		else
		{
			_renderState.applyBlendMode = false;
			_renderState.blendMode = BlendMode.Off;
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
	}

	override private function getOption(lightType:LightType, meshType:MeshType):Array<Array<String>>
	{
		return super.getOption(lightType, meshType);
	}

	override private function getBindAttributes(lightType:LightType, meshType:MeshType):StringMap<String>
	{
		var map:StringMap<String> = new StringMap<String>();
		map.set(BufferType.POSITION, "a_position");

		if (meshType == MeshType.KEYFRAME)
		{
			map.set(BufferType.POSITION1,"a_position1");
		}
		return map;
	}
}

@:file("org/angle3d/material/technique/data/colorfill.vs") 
class ColorFillVS extends flash.utils.ByteArray{}
@:file("org/angle3d/material/technique/data/colorfill.fs") 
class ColorFillFS extends flash.utils.ByteArray{}
