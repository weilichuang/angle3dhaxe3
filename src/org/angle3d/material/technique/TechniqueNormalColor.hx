package org.angle3d.material.technique;

import flash.utils.ByteArray;
import flash.Vector;
import org.angle3d.light.LightType;
import org.angle3d.material.CullMode;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.material.shader.Uniform;
import org.angle3d.material.TestFunction;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.mesh.MeshType;


/**
 * andy
 * @author andy
 */

class TechniqueNormalColor extends Technique
{
	public var influence(get, set):Float;
	public var normalScale(null, set):Vector3f;
	
	private var _influences:Vector<Float>;

	private var _normalScales:Vector<Float>;

	public function new()
	{
		super();

		renderState.applyCullMode = true;
		renderState.cullMode = CullMode.FRONT;

		renderState.applyDepthTest = true;
		renderState.depthTest = true;
		renderState.compareMode = TestFunction.LESS_EQUAL;

		renderState.applyBlendMode = false;

		_normalScales = new Vector<Float>(4, true);
		_normalScales[3] = 1.0;

		normalScale = new Vector3f(1, 1, 1);
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
	}
	
	override private function getVertexSource():String
	{
		var vb:ByteArray = new NormalColorVS();
		return vb.readUTFBytes(vb.length);
	}

	override private function getFragmentSource():String
	{
		var fb:ByteArray = new NormalColorFS();
		return fb.readUTFBytes(fb.length);
	}

	override private function getOption(lightType:LightType, meshType:MeshType):Array<Array<String>>
	{
		return super.getOption(lightType, meshType);
	}

	override private function getKey(lightType:LightType, meshType:MeshType):String
	{
		var result:Array<String> = [name, meshType.getName()];
		return result.join("_");
	}
}

@:file("org/angle3d/material/technique/data/normalcolor.vs") 
class NormalColorVS extends flash.utils.ByteArray{}
@:file("org/angle3d/material/technique/data/normalcolor.fs") 
class NormalColorFS extends flash.utils.ByteArray{}