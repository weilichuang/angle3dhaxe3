package org.angle3d.math;

import flash.Vector;
import org.angle3d.math.Vector3f;

/**
 * <code>Vector4f</code> defines a Vector for a four float value tuple.
 * <code>Vector4f</code> can represent any four dimensional value, such as a
 * vertex, a normal, etc. Utility methods are also included to aid in
 * mathematical calculations.
 *
 * @author Maarten Steur
 */
class Vector4f
{
	/**
	 * Check a vector... if it is null or its floats are NaN or infinite,
	 * return false.  Else return true.
	 * @param vector the vector to check
	 * @return true or false as stated above.
	 */
	public static function isValid(vector:Vector4f):Bool
	{
		if (vector == null)
			return false;

		if (FastMath.isNaN(vector.x) || FastMath.isNaN(vector.y) || 
			FastMath.isNaN(vector.z) || FastMath.isNaN(vector.w))
			return false;

		if (!Math.isFinite(vector.x) || !Math.isFinite(vector.y) || 
			!Math.isFinite(vector.z) || !Math.isFinite(vector.w))
			return false;

		return true;
	}
	
	public var length(get, null):Float;
	public var lengthSquared(get, null):Float;

	/**
	 * the x value of the vector.
	 */
	public var x:Float;

	/**
	 * the y value of the vector.
	 */
	public var y:Float;

	/**
	 * the z value of the vector.
	 */
	public var z:Float;

	/**
	 * the w value of the vector.
	 */
	public var w:Float;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 0)
	{
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}

	public inline function copyFrom(other:Vector4f):Void
	{
		this.x = other.x;
		this.y = other.y;
		this.z = other.z;
		this.w = other.w;
	}

	public inline function setTo(x:Float, y:Float, z:Float, w:Float):Void
	{
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}

	public inline function add(vec:Vector4f):Vector4f
	{
		return new Vector4f(x + vec.x, y + vec.y, z + vec.z, w + vec.w);
	}

	public inline function addLocal(vec:Vector4f):Void
	{
		x += vec.x;
		y += vec.y;
		z += vec.z;
		w += vec.w;
	}

	/**
	 *
	 * <code>scaleAdd</code> multiplies this vector by a scalar then adds the
	 * given Vector3f.
	 *
	 * @param scalar
	 *            the value to multiply this vector by.
	 * @param add
	 *            the value to add
	 */
	
	public inline function scaleAdd(scalar:Float, add:Vector4f):Void
	{
		x = x * scalar + add.x;
		y = y * scalar + add.y;
		z = z * scalar + add.z;
		w = w * scalar + add.w;
	}

	/**
	 *
	 * <code>dot</code> calculates the dot product of this vector with a
	 * provided vector. If the provided vector is null, 0 is returned.
	 *
	 * @param vec
	 *            the vector to dot with this vector.
	 * @return the resultant dot product of this vector and a given vector.
	 */
	
	public inline function dot(vec:Vector4f):Float
	{
		return x * vec.x + y * vec.y + z * vec.z + w * vec.w;
	}

	public inline function project(other:Vector4f):Vector4f
	{
		var n:Float = this.dot(other);
		var d:Float = other.lengthSquared;
		var result:Vector4f = other.clone();
		result.normalize();
		result.scaleLocal(n / d);
		return result;
	}

	/**
	 * Returns true if this vector is a unit vector (length() ~= 1),
	 * returns false otherwise.
	 *
	 * @return true if this vector is a unit vector (length() ~= 1),
	 * or false otherwise.
	 */
	
	public inline function isUnitVector():Bool
	{
		var len:Float = length;
		return 0.99 < len && len < 1.01;
	}

	/**
	 * <code>length</code> calculates the magnitude of this vector.
	 *
	 * @return the length or magnitude of the vector.
	 */
	
	private inline function get_length():Float
	{
		return Math.sqrt(x * x + y * y + z * z + w * w);
	}

	/**
	 * <code>lengthSquared</code> calculates the squared value of the
	 * magnitude of the vector.
	 *
	 * @return the magnitude squared of the vector.
	 */
	
	private inline function get_lengthSquared():Float
	{
		return x * x + y * y + z * z + w * w;
	}

	/**
	 * <code>distanceSquared</code> calculates the distance squared between
	 * this vector and vector v.
	 *
	 * @param v the second vector to determine the distance squared.
	 * @return the distance squared between the two vectors.
	 */
	
	public inline function distanceSquared(v:Vector4f):Float
	{
		var dx:Float = x - v.x;
		var dy:Float = y - v.y;
		var dz:Float = z - v.z;
		var dw:Float = w - v.w;
		return (dx * dx + dy * dy + dz * dz + dw * dw);
	}

	/**
	 * <code>distance</code> calculates the distance between
	 * this vector and vector v.
	 *
	 * @param v the second vector to determine the distance.
	 * @return the distance between the two vectors.
	 */
	
	public inline function distance(v:Vector4f):Float
	{
		return Math.sqrt(distanceSquared(v));
	}
	
	public inline function scale(scalar:Float):Vector4f
	{
		return new Vector4f(x * scalar, y * scalar, z * scalar, w * scalar);
	}

	public inline function scaleLocal(scalar:Float):Void
	{
		x *= scalar;
		y *= scalar;
		z *= scalar;
		w *= scalar;
	}

	public inline function multiply(vec:Vector4f, result:Vector4f = null):Vector4f
	{
		if (result == null)
		{
			result = new Vector4f();
		}
		result.x = x * vec.x;
		result.y = y * vec.y;
		result.z = z * vec.z;
		result.w = w * vec.w;
		return result;
	}

	public inline function multiplyLocal(vec:Vector4f):Void
	{
		x *= vec.x;
		y *= vec.y;
		z *= vec.z;
		w *= vec.w;
	}
	
	public inline function absoluteLocal():Void
	{
		this.x = FastMath.abs(this.x);
		this.y = FastMath.abs(this.y);
		this.z = FastMath.abs(this.z);
		this.w = FastMath.abs(this.w);
	}

	/**
	 *
	 * <code>negate</code> returns the negative of this vector. All values are
	 * negated and set_to a new vector.
	 *
	 * @return the negated vector.
	 */
	
	public inline function negate():Vector4f
	{
		return new Vector4f(-x, -y, -z, -w);
	}

	public inline function negateLocal():Void
	{
		x = -x;
		y = -y;
		z = -z;
		w = -w;
	}

	/**
	 *
	 * <code>subtract</code> subtracts the values of a given vector from those
	 * of this vector creating a new vector object. If the provided vector is
	 * null, null is returned.
	 *
	 * @param vec
	 *            the vector to subtract from this vector.
	 * @return the result vector.
	 */
	
	public inline function subtract(vec:Vector4f):Vector4f
	{
		return new Vector4f(x - vec.x, y - vec.y, z - vec.z, w - vec.w);
	}
	
	public inline function decrementBy(vec:Vector4f):Void
	{
		x -= vec.x;
		y -= vec.y;
		z -= vec.z;
		w -= vec.w;
	}

	/**
	 * <code>normalize</code> returns the unit vector of this vector.
	 *
	 * @return unit vector of this vector.
	 */
	public function normalize():Void
	{
		var len:Float = x * x + y * y + z * z + w * w;
		if (len != 1 && len != 0)
		{
			len = 1 / Math.sqrt(len);
			x *= len;
			y *= len;
			z *= len;
			w *= len;
		}
	}

	/**
	 * <code>angleBetween</code> returns (in radians) the angle between two vectors.
	 * It is assumed that both this vector and the given vector are unit vectors (iow, normalized).
	 *
	 * @param otherVector a unit vector to find the angle against
	 * @return the angle in radians.
	 */
	
	public inline function angleBetween(other:Vector4f):Float
	{
		var dot:Float = this.dot(other);
		var angle:Float = Math.acos(dot);
		return angle;
	}

	public inline function lerp(v1:Vector4f, v2:Vector4f, interp:Float):Void
	{
		var t:Float = 1 - interp;
		this.x = t * v1.x + interp * v2.x;
		this.y = t * v1.y + interp * v2.y;
		this.z = t * v1.z + interp * v2.z;
		this.w = t * v1.w + interp * v2.w;
	}

	public inline function clone():Vector4f
	{
		return new Vector4f(x, y, z, w);
	}
	
	public inline function toVector(arr:Vector<Float>):Void
	{
		arr[0] = x;
		arr[1] = y;
		arr[2] = z;
		arr[3] = w;
	}
	
	public inline function toVector3f(vec3:Vector3f):Void
	{
		vec3.x = x;
		vec3.y = y;
		vec3.z = z;
	}
	
	public inline function fromVector3f(vec:Vector3f):Void
	{
		this.x = vec.x;
		this.y = vec.y;
		this.z = vec.z;
		this.w = 0.0;
	}

	public function toString():String
	{
		return 'Vector4f($x,$y,$z,$w)';
	}
}

