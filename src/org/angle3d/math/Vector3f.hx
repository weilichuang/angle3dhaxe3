package org.angle3d.math;

import de.polygonal.ds.error.Assert;
import flash.Vector;

class Vector3f
{
	public static var ZERO:Vector3f = new Vector3f(0, 0, 0);

	public static var X_AXIS:Vector3f = new Vector3f(1, 0, 0);

	public static var Y_AXIS:Vector3f = new Vector3f(0, 1, 0);

	public static var Z_AXIS:Vector3f = new Vector3f(0, 0, 1);

	public static var UNIT_SCALE:Vector3f = new Vector3f(1, 1, 1);

		
	public static function checkMinMax(min:Vector3f, max:Vector3f, point:Vector3f):Void
	{
		if (point.x < min.x)
			min.x = point.x;
		if (point.x > max.x)
			max.x = point.x;
		if (point.y < min.y)
			min.y = point.y;
		if (point.y > max.y)
			max.y = point.y;
		if (point.z < min.z)
			min.z = point.z;
		if (point.z > max.z)
			max.z = point.z;
	}
	
	public var length(get, null):Float;
	public var lengthSquared(get, null):Float;
		
	public var x:Float;

	public var y:Float;
	
	public var z:Float;

	public inline function new(x:Float = 0, y:Float = 0, z:Float = 0)
	{
		this.x = x;
		this.y = y;
		this.z = z;
	}
	
	public inline function copyFrom(other:Vector3f):Vector3f
	{
		this.x = other.x;
		this.y = other.y;
		this.z = other.z;

		return this;
	}

	/**
	 *
	 * @param copyVec 复制copyVec
	 * @param addVec 然后加上addVec
	 * @return Vector3f
	 *
	 */
	public inline function copyAddLocal(copyVec:Vector3f, addVec:Vector3f):Void
	{
		this.x = copyVec.x + addVec.x;
		this.y = copyVec.y + addVec.y;
		this.z = copyVec.z + addVec.z;
	}

	/**
	 * <code>set</code> sets the x,y,z values of the vector based on passed
	 * parameters.
	 *
	 * @param x
	 *            the x value of the vector.
	 * @param y
	 *            the y value of the vector.
	 * @param z
	 *            the z value of the vector.
	 * @return this vector
	 */
	
	public inline function setTo(x:Float, y:Float, z:Float):Vector3f
	{
		this.x = x;
		this.y = y;
		this.z = z;
		return this;
	}

	public function getValueAt(index:Int):Float
	{
		Assert.assert(index >= 0 && index < 3, "the index out of bound");

		if (index == 0)
		{
			return x;
		}
		else if (index == 1)
		{
			return y;
		}
		else
		{
			return z;
		}
	}

	public function setValueAt(index:Int, value:Float):Void
	{
		Assert.assert(index >= 0 && index < 3, "the index out of bound");

		if (index == 0)
		{
			x = value;
		}
		else if (index == 1)
		{
			y = value;
		}
		else
		{
			z = value;
		}
	}

	/**
	 *
	 * <code>add</code> adds a provided vector to this vector creating a
	 * resultant vector which is returned. If the provided vector is null, null
	 * is returned.
	 *
	 * @param vec
	 *            the vector to add to this.
	 * @return the resultant vector.
	 */
	public function add(vec:Vector3f, result:Vector3f = null):Vector3f
	{
		if (result == null)
			result = new Vector3f();

		result.x = x + vec.x;
		result.y = y + vec.y;
		result.z = z + vec.z;
		return result;
	}
	
	public inline function addBy(vec1:Vector3f,vec2:Vector3f):Void
	{
		this.x = vec1.x + vec2.x;
		this.y = vec1.y + vec2.y;
		this.z = vec1.z + vec2.z;
	}

	
	public inline function addLocal(vec:Vector3f):Vector3f
	{
		x += vec.x;
		y += vec.y;
		z += vec.z;
		return this;
	}
	
	public inline function addXYZLocal(vx:Float,vy:Float,vz:Float):Vector3f
	{
		x += vx;
		y += vy;
		z += vz;
		return this;
	}

	/**
	 * result = this - vec
	 */
	public function subtract(vec:Vector3f, result:Vector3f = null):Vector3f
	{
		if (result == null)
			result = new Vector3f();

		result.x = x - vec.x;
		result.y = y - vec.y;
		result.z = z - vec.z;
		return result;
	}

	
	public inline function subtractLocal(vec:Vector3f):Vector3f
	{
		x -= vec.x;
		y -= vec.y;
		z -= vec.z;
		return this;
	}
	
	public inline function subtractBy(vec1:Vector3f, vec2:Vector3f):Void
	{
		this.x = vec1.x - vec2.x;
		this.y = vec1.y - vec2.y;
		this.z = vec1.z - vec2.z;
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
	public inline function scaleAdd(scalar:Float, addVec:Vector3f):Void
	{
		x = x * scalar + addVec.x;
		y = y * scalar + addVec.y;
		z = z * scalar + addVec.z;
	}
	
	public inline function scaleAddBy(s:Float, sVec:Vector3f, aVec:Vector3f):Void
	{
		this.x = s * sVec.x + aVec.x;
		this.y = s * sVec.y + aVec.y;
		this.z = s * sVec.z + aVec.z;
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
	public inline function dot(vec:Vector3f):Float
	{
		return x * vec.x + y * vec.y + z * vec.z;
	}

	public function cross(vec:Vector3f, result:Vector3f = null):Vector3f
	{
		if (result == null)
			result = new Vector3f();

		result.x = (y * vec.z - z * vec.y);
		result.y = (z * vec.x - x * vec.z);
		result.z = (x * vec.y - y * vec.x);

		return result;
	}
	
	public inline function crossBy(v1:Vector3f, v2:Vector3f):Void
	{
		var tx:Float = v1.y * v2.z - v1.z * v2.y;
		var ty:Float = v2.x * v1.z - v2.z * v1.x;
		this.z = v1.x * v2.y - v1.y * v2.x;
		this.x = tx;
		this.y = ty;
	}

	public inline function crossLocal(vec:Vector3f):Vector3f
	{
		var tx:Float = this.x;
		var ty:Float = this.y;
		var tz:Float = this.z;

		this.x = ty * vec.z - tz * vec.y;
		this.y = tz * vec.x - tx * vec.z;
		this.z = tx * vec.y - ty * vec.x;

		return this;
	}

	/**
	 * Returns true if this vector is a unit vector (length() ~= 1),
	 * returns false otherwise.
	 *
	 * @return true if this vector is a unit vector (length() ~= 1),
	 * or false otherwise.
	 */
	public function isUnitVector(roundError:Float = 0.01):Bool
	{
		return FastMath.nearEqual(length, 1.0, roundError);
	}

	/**
	 * <code>length</code> calculates the magnitude of this vector.
	 *
	 */
	
	private inline function get_length():Float
	{
		return Math.sqrt(x * x + y * y + z * z);
	}

	/**
	 * <code>lengthSquared</code> calculates the squared value of the
	 * magnitude of the vector.
	 *
	 */
	
	private inline function get_lengthSquared():Float
	{
		return x * x + y * y + z * z;
	}

	/**
	 * <code>distanceSquared</code> calculates the distance squared between
	 * this vector and vector v.
	 *
	 * @param v the second vector to determine the distance squared.
	 * @return the distance squared between the two vectors.
	 */
	public inline function distanceSquared(v:Vector3f):Float
	{
		var dx:Float = x - v.x;
		var dy:Float = y - v.y;
		var dz:Float = z - v.z;
		return (dx * dx + dy * dy + dz * dz);
	}

	/**
	 * <code>distance</code> calculates the distance between
	 * this vector and vector v.
	 *
	 * @param v the second vector to determine the distance.
	 * @return the distance between the two vectors.
	 */
	public inline function distance(v:Vector3f):Float
	{
		var dx:Float = x - v.x;
		var dy:Float = y - v.y;
		var dz:Float = z - v.z;
		return Math.sqrt(dx * dx + dy * dy + dz * dz);
	}

	public inline function scale(scalar:Float, result:Vector3f = null):Vector3f
	{
		if (result == null)
			result = new Vector3f();

		result.x = x * scalar;
		result.y = y * scalar;
		result.z = z * scalar;
		return result;
	}
	
	public inline function divide(scalar:Vector3f):Vector3f
	{
		return new Vector3f(x / scalar.x, y / scalar.y, z / scalar.z);
	}

	public inline function scaleLocal(scalar:Float):Vector3f
	{
		x *= scalar;
		y *= scalar;
		z *= scalar;
		return this;
	}
	
	public inline function scaleBy(s:Float, vec:Vector3f):Void
	{
		this.x = s * vec.x;
		this.y = s * vec.y;
		this.z = s * vec.z;
	}

	public inline function mult(vec:Vector3f, result:Vector3f = null):Vector3f
	{
		if (result == null)
			result = new Vector3f();

		result.x = x * vec.x;
		result.y = y * vec.y;
		result.z = z * vec.z;
		return result;
	}

	
	public inline function multLocal(vec:Vector3f):Vector3f
	{
		x *= vec.x;
		y *= vec.y;
		z *= vec.z;
		return this;
	}
	
	public inline function copyMultLocal(copyV:Vector3f,vec:Vector3f):Void
	{
		x = copyV.x * vec.x;
		y = copyV.y * vec.y;
		z = copyV.z * vec.z;
	}

	
	public inline function divideLocal(scalar:Vector3f):Vector3f
	{
		x /= scalar.x;
		y /= scalar.y;
		z /= scalar.z;
		return this;
	}

	
	public inline function negateLocal():Vector3f
	{
		x = -x;
		y = -y;
		z = -z;
		return this;
	}

	/**
	 *
	 * <code>negate</code> returns the negative of this vector. All values are
	 * negated and set_to a new vector.
	 *
	 * @return the negated vector.
	 */
	
	public inline function negate():Vector3f
	{
		return new Vector3f(-x, -y, -z);
	}
	
	public inline function negateBy(vec:Vector3f):Void
	{
		this.x = -vec.x;
		this.y = -vec.y;
		this.z = -vec.z;
	}

	/**
	 * <code>normalize</code> returns the unit vector of this vector.
	 *
	 * @return unit vector of this vector.
	 */
	public function normalizeLocal():Vector3f
	{
		var len:Float = x * x + y * y + z * z;
		if (len != 0)
		{
			len = 1 / Math.sqrt(len);
			x *= len;
			y *= len;
			z *= len;
		}
		return this;
	}
	
	public inline function normalize(result:Vector3f = null):Vector3f
	{
		if (result == null)
			result = new Vector3f();
			
		var length:Float = x * x + y * y + z * z;
        if (length != 1 && length != 0)
		{
            length = 1 / Math.sqrt(length);
			result.setTo(x * length, y * length, z * length);
        }
		else
		{
			result.setTo(x, y, z);
		}
        return result;
	}
	
	public inline function normalizeBy(vec:Vector3f):Void
	{
        var length:Float = Math.sqrt(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z);
		if (length != 0)
			length = 1 / length;
        this.x = vec.x * length;
        this.y = vec.y * length;
        this.z = vec.z * length;
	}

	/**
	 * <code>maxLocal</code> computes the maximum value for each
	 * component in this and <code>other</code> vector. The result is stored
	 * in this vector.
	 * @param other
	 */
	
	public inline function maxLocal(other:Vector3f):Void
	{
		x = other.x > x ? other.x : x;
		y = other.y > y ? other.y : y;
		z = other.z > z ? other.z : z;
	}

	/**
	 * <code>minLocal</code> computes the minimum value for each
	 * component in this and <code>other</code> vector. The result is stored
	 * in this vector.
	 * @param other
	 */
	
	public inline function minLocal(other:Vector3f):Void
	{
		x = other.x < x ? other.x : x;
		y = other.y < y ? other.y : y;
		z = other.z < z ? other.z : z;
	}

	public inline function isZero():Bool
	{
		return (x == 0 && y == 0 && z == 0);
	}

	/**
	 * <code>angleBetween</code> returns (in radians) the angle between two vectors.
	 * It is assumed that both this vector and the given vector are unit vectors (iow, normalized).
	 *
	 * @param otherVector a unit vector to find the angle against
	 * @return the angle in radians.
	 */
	public function angleBetween(vec:Vector3f):Float
	{
		return Math.acos(x * vec.x + y * vec.y + z * vec.z);
	}

	public inline function lerp(v1:Vector3f, v2:Vector3f, interp:Float):Void
	{
		var t:Float = 1 - interp;
		this.x = t * v1.x + interp * v2.x;
		this.y = t * v1.y + interp * v2.y;
		this.z = t * v1.z + interp * v2.z;
	}
	
	/**
     * Sets this vector to the interpolation by changeAmnt from this to the finalVec
     * this=(1-changeAmnt)*this + changeAmnt * finalVec
     * @param finalVec The final vector to interpolate towards
     * @param changeAmnt An amount between 0.0 - 1.0 representing a precentage
     *  change from this towards finalVec
     */
    public inline function interpolateLocal(finalVec:Vector3f, alpha:Float):Vector3f
	{
		var t:Float = 1 - alpha;
		
        this.x = t * this.x + alpha * finalVec.x;
        this.y = t * this.y + alpha * finalVec.y;
        this.z = t * this.z + alpha * finalVec.z;
		
        return this;
    }

	public inline function clone():Vector3f
	{
		return new Vector3f(x, y, z);
	}

	
	public inline function toVector(vec:Vector<Float>):Void
	{
		vec[0] = x;
		vec[1] = y;
		vec[2] = z;
	}
	
	public function equals(other:Vector3f):Bool
	{
		return x == other.x && y == other.y && z == other.z;
	}
	
	public function epsilonEquals(vec:Vector3f, epsilon:Float):Bool
	{
		var diff:Float = this.x - vec.x;
		if ((diff < 0 ? -diff : diff) > epsilon)
			return false;
			
		diff = this.y - vec.y;
		if ((diff < 0 ? -diff : diff) > epsilon)
			return false;
		
		diff = this.z - vec.z;
		if ((diff < 0 ? -diff : diff) > epsilon)
			return false;
		
		return true;
	}
	
	public function isValid():Bool
	{
		if (FastMath.isNaN(x) || 
			FastMath.isNaN(y) || 
			FastMath.isNaN(z))
			return false;

		if (!Math.isFinite(x) || 
			!Math.isFinite(y) || 
			!Math.isFinite(z))
			return false;

		return true;
	}
	
	
	public function absoluteLocal():Vector3f
	{
		this.x = FastMath.abs(this.x);
		this.y = FastMath.abs(this.y);
		this.z = FastMath.abs(this.z);
		return this;
	}
	
	public function absolute(result:Vector3f = null):Vector3f
	{
		if (result == null)
			result = new Vector3f();
			
		result.x = FastMath.abs(this.x);
		result.y = FastMath.abs(this.y);
		result.z = FastMath.abs(this.z);
		return result;
	}
	
	public function absoluteFrom(fromVec:Vector3f):Vector3f
	{
		this.x = FastMath.abs(fromVec.x);
		this.y = FastMath.abs(fromVec.y);
		this.z = FastMath.abs(fromVec.z);
		return this;
	}
	
	public function toString():String
	{
		return 'Vector3f($x,$y,$z)';
	}
	
}