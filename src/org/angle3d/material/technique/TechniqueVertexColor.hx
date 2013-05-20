package org.angle3d.material.technique;

import flash.utils.ByteArray;
import flash.utils.Dictionary;
import flash.Vector;
import haxe.ds.StringMap;
import org.angle3d.light.LightType;
import org.angle3d.material.BlendMode;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.material.shader.UniformBinding;
import org.angle3d.material.shader.UniformBindingHelp;
import org.angle3d.material.TestFunction;
import org.angle3d.math.FastMath;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.MeshType;


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

		_renderState.applyDepthTest = true;
		_renderState.depthTest = true;
		_renderState.compareMode = TestFunction.LESS_EQUAL;

		_renderState.applyBlendMode = false;

		_alpha = new Vector<Float>(4, true);
	}

	public function setAlpha(alpha:Float):Void
	{
		_alpha[0] = FastMath.clamp(alpha, 0.0, 1.0);

		if (_alpha[0] < 1)
		{
			_renderState.depthTest = false;
			_renderState.applyBlendMode = true;
			_renderState.blendMode = BlendMode.Alpha;
		}
		else
		{
			_renderState.depthTest = true;
			_renderState.applyBlendMode = false;
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
	
	override private function initSouce():Void
	{
		var vb:ByteArray = new VertexColorVS();
		mVertexSource =  vb.readUTFBytes(vb.length);
		
		var fb:ByteArray = new VertexColorFS();
		mFragmentSource = fb.readUTFBytes(fb.length);
	}
}

@:file("org/angle3d/material/technique/data/vertexcolor.vs") 
class VertexColorVS extends flash.utils.ByteArray{}
@:file("org/angle3d/material/technique/data/vertexcolor.fs") 
class VertexColorFS extends flash.utils.ByteArray{}
