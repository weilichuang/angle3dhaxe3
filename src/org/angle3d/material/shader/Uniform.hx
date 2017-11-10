package org.angle3d.material.shader;


import org.angle3d.material.VarType;
import org.angle3d.math.Color;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.math.Vector4f;


class Uniform extends ShaderVariable
{
	public var needUpdated:Bool;
	
	/**
	 * Binding to a renderer value, or null if user-defined uniform
	 */
	public var binding:Int;

	public var data(get, null):Array<Float>;

	private var _data:Array<Float>;
	
	/**
     * Type of uniform
     */
	private var varType:VarType;
	
	/**
     * Used to track which uniforms to clear to avoid
     * values leaking from other materials that use that shader.
     */
    private var setByCurrentMaterial:Bool = false;
	
	public function new(name:String, size:Int, binding:Int = -1)
	{
		super(name, size);
		
		this.binding = binding;

		this.size = Math.ceil(this.size / 4);
		
		_data = new Array<Float>(this.size * 4);
		
		needUpdated = true;
	}
	
	public inline function getVarType():VarType
	{
		return varType;
	}
	
	public function setValue(varType:VarType, value:Dynamic):Void
	{
		switch(varType)
		{
			case VarType.VECTOR2:
				setVector2(cast value);
			case VarType.VECTOR3:
				setVector3(cast value);
			case VarType.VECTOR4:	
				setVector4(cast value);
			case VarType.MATRIX3:
				setMatrix3(cast value);
			case VarType.MATRIX4:
				setMatrix4(cast value);
			case VarType.COLOR:
				setColor(cast value);
			case VarType.QUATERNION:
				setQuaterion(cast value);	
			case VarType.Vector4Array:
				setVector(cast value);
			case VarType.FLOAT:
				setFloat(cast value);
			case VarType.INT:
				setInt(cast value);
			default:
		}
		
		this.varType = varType;
		needUpdated = true;
	}
	
	public function clearValue():Void
	{
		needUpdated = true;
		
		switch(varType)
		{
			case VarType.FLOAT:
				_data[0] = 0;
			case VarType.INT:
				_data[0] = 0;
			case VarType.VECTOR2:
				_data[0] = 0;
				_data[1] = 0;
			case VarType.VECTOR3:
				_data[0] = 0;
				_data[1] = 0;
				_data[2] = 0;
			case VarType.VECTOR4:	
				_data[0] = 0;
				_data[1] = 0;
				_data[2] = 0;
				_data[3] = 0;
			case VarType.MATRIX3:
				_data[0] = 1;
				_data[1] = 0;
				_data[2] = 0;
				_data[3] = 0;
				_data[4] = 0;
				_data[5] = 1;
				_data[6] = 0;
				_data[7] = 0;
				_data[8] = 0;
				_data[9] = 0;
				_data[10] = 1;
				_data[11] = 0;
			case VarType.MATRIX4:
				_data[0] = 1;
				_data[1] = 0;
				_data[2] = 0;
				_data[3] = 0;

				_data[4] = 0;
				_data[5] = 1;
				_data[6] = 0;
				_data[7] = 0;

				_data[8] = 0;
				_data[9] = 0;
				_data[10] = 1;
				_data[11] = 0;

				_data[12] = 0;
				_data[13] = 0;
				_data[14] = 0;
				_data[15] = 1;
			case VarType.COLOR:
				_data[0] = 0;
				_data[1] = 0;
				_data[2] = 0;
				_data[3] = 0;	
			case VarType.QUATERNION:
				_data[0] = 0;
				_data[1] = 0;
				_data[2] = 0;
				_data[3] = 1;
			case VarType.Vector4Array:
				for (i in 0...size * 4)
				{
					_data[i] = 0;
				}
			default:
		}
	}

	public inline function setVector(data:Array<Float>):Void
	{
		_data = data;
		this.varType = VarType.Vector4Array;
		setByCurrentMaterial = true;
		needUpdated = true;
	}
	
	public inline function setMatrix4(mat:Matrix4f):Void
	{
		mat.toVector(_data);
		this.varType = VarType.MATRIX4;
		setByCurrentMaterial = true;
		needUpdated = true;
	}

	
	public inline function setMatrix3(mat:Matrix3f):Void
	{
		mat.toVector(_data);
		this.varType = VarType.MATRIX3;
		setByCurrentMaterial = true;
		needUpdated = true;
	}

	
	public inline function setColor(c:Color):Void
	{
		c.toVector(_data);
		this.varType = VarType.COLOR;
		setByCurrentMaterial = true;
		needUpdated = true;
	}
	
	public inline function setQuaterion(c:Quaternion):Void
	{
		c.toVector(_data);
		this.varType = VarType.QUATERNION;
		setByCurrentMaterial = true;
		needUpdated = true;
	}

	public inline function setFloat(value:Float):Void
	{
		_data[0] = value;
		this.varType = VarType.FLOAT;
		setByCurrentMaterial = true;
		needUpdated = true;
	}
	
	public inline function setInt(value:Int):Void
	{
		_data[0] = value;
		this.varType = VarType.INT;
		setByCurrentMaterial = true;
		needUpdated = true;
	}
	
	public inline function setVector2(vec:Vector2f):Void
	{
		vec.toVector(_data);
		this.varType = VarType.VECTOR2;
		setByCurrentMaterial = true;
		needUpdated = true;
	}

	public inline function setVector3(vec:Vector3f):Void
	{
		vec.toArray(_data);
		this.varType = VarType.VECTOR3;
		setByCurrentMaterial = true;
		needUpdated = true;
	}
	
	public inline function setVector4(vec:Vector4f):Void
	{
		vec.toVector(_data);
		this.varType = VarType.VECTOR4;
		setByCurrentMaterial = true;
		needUpdated = true;
	}
	
	public function setVector4Length(length:Int):Void
	{
		this.size = length;
		
		if(_data == null)
			_data = new Array<Float>(this.size * 4);
		else
			_data.length = this.size * 4;
		
		this.varType = VarType.Vector4Array;
		setByCurrentMaterial = true;
		needUpdated = true;
	}
	
	public inline function setVector4InArray(x:Float, y:Float, z:Float, w:Float, index:Int):Void
	{
		#if debug
		if (this.varType != VarType.Vector4Array)
		{
			throw "Expected a Vector4Array value!";
		}
		#end
		
		var index4:Int = index * 4;
		_data[index4] = x;
		_data[index4 + 1] = y;
		_data[index4 + 2] = z;
		_data[index4 + 3] = w;
		
		setByCurrentMaterial = true;
		needUpdated = true;
	}
	
	public inline function reset():Void
	{
		setByCurrentMaterial = false;
		needUpdated = true;
	}

	private inline function get_data():Array<Float>
	{
		return _data;
	}
	
	public inline function isUpdateNeeded():Bool
	{
        return needUpdated;
    }

    public inline function clearUpdateNeeded():Void
	{
        needUpdated = false;
    }
	
	public inline function isSetByCurrentMaterial():Bool
	{
		return setByCurrentMaterial;
	}
	
	public inline function clearSetByCurrentMaterial():Void
	{
		setByCurrentMaterial = false;
	}
}

