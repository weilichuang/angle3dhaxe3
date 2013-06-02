package org.angle3d.material.shader;

import org.angle3d.material.VarType;
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
class Uniform extends ShaderParam
{
	/**
	 * Binding to a renderer value, or null if user-defined uniform
	 */
	public var binding:UniformBinding;

	public var data(get, null):Vector<Float>;

	private var _data:Vector<Float>;
	
	public var needUpdated:Bool;

	public function new(name:String, size:Int, binding:UniformBinding)
	{
		super(name, size);
		
		this.binding = binding;

		this.size = Std.int(this.size / 4);

		_data = new Vector<Float>(this.size * 4, true);
		
		needUpdated = true;
	}
	
	public function setValue(varType:String, value:Dynamic):Void
	{
		switch(varType)
		{
			case VarType.VECTOR2:
				setVector2(cast(value, Vector2f));
			case VarType.VECTOR3:
				setVector3(cast(value, Vector3f));
			case VarType.VECTOR4:	
				setVector4(cast(value, Vector4f));
			case VarType.MATRIX3:
				setMatrix3(cast(value, Matrix3f));
			case VarType.MATRIX4:
				setMatrix4(cast(value, Matrix4f));
			case VarType.COLOR:
				setColor(cast(value, Color));
			case VarType.QUATERNION:
				setColor(cast(value, Color));	
			case VarType.VECTOR:
				setVector(cast value);
			case VarType.FLOAT:
				setFloat(cast(value, Float));
		}
	}

	public function setVector(data:Vector<Float>):Void
	{
		var count:Int = size * 4;
		for (i in 0...count)
		{
			_data[i] = data[i];
		}
		needUpdated = true;
	}
	
	public function setMatrix4(mat:Matrix4f):Void
	{
		mat.toUniform(_data);
		needUpdated = true;
	}

	
	public function setMatrix3(mat:Matrix3f):Void
	{
		mat.toUniform(_data);
		needUpdated = true;
	}

	
	public function setColor(c:Color):Void
	{
		c.toUniform(_data);
		needUpdated = true;
	}

	
	public function setFloat(value:Float):Void
	{
		_data[0] = value;
		needUpdated = true;
	}

	
	public function setVector2(vec:Vector2f):Void
	{
		vec.toUniform(_data);
		needUpdated = true;
	}

	
	public function setVector3(vec:Vector3f):Void
	{
		vec.toUniform(_data);
		needUpdated = true;
	}

	
	public function setVector4(vec:Vector4f):Void
	{
		vec.toUniform(_data);
		needUpdated = true;
	}

	
	public function setQuaterion(q:Quaternion):Void
	{
		q.toUniform(_data);
		needUpdated = true;
	}

	private inline function get_data():Vector<Float>
	{
		return _data;
	}
}

