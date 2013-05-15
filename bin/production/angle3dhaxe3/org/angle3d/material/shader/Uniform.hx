package org.angle3d.material.shader;

import org.angle3d.math.Color;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.math.Vector4f;
import flash.Vector;
/**
 * andy
 * @author
 */
//uniform mat4 u_boneMatrix[32]
class Uniform extends ShaderVariable
{
	/**
	 * Binding to a renderer value, or null if user-defined uniform
	 */
	public var binding:UniformBinding;

	public var data(get, null):Vector<Float>;

	private var _data:Vector<Float>;

	public function new(name:String, size:Int)
	{
		super(name, size);

		_size = Std.int(_size / 4);

		_data = new Vector<Float>(_size * 4,true);
	}

	override private function get_size():Int
	{
		return _size;
	}

	public function setVector(data:Vector<Float>):Void
	{
		var count:Int = _size * 4;
		for (i in 0...count)
		{
			_data[i] = data[i];
		}
	}

	
	public function setMatrix4(mat:Matrix4f):Void
	{
		mat.toUniform(_data);
	}

	
	public function setMatrix3(mat:Matrix3f):Void
	{
		mat.toUniform(_data);
	}

	
	public function setColor(c:Color):Void
	{
		c.toUniform(_data);
	}

	
	public function setFloat(value:Float):Void
	{
		_data[0] = value;
	}

	
	public function setVector2(vec:Vector2f):Void
	{
		vec.toUniform(_data);
	}

	
	public function setVector3(vec:Vector3f):Void
	{
		vec.toUniform(_data);
	}

	
	public function setVector4(vec:Vector4f):Void
	{
		vec.toUniform(_data);
	}

	
	public function setQuaterion(q:Quaternion):Void
	{
		q.toUniform(_data);
	}

	private function get_data():Vector<Float>
	{
		return _data;
	}
}

