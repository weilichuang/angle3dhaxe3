package com.vecmath;

/**
 * A 3-element vector that is represented by single-precision floating point 
 * x,y,z coordinates.  If this value represents a normal, then it should
 * be normalized.
 *
 */
class Vector3i
{
	/**
     * The x coordinate.
     */
	public var x:Int;
	
	/**
     * The y coordinate.
     */
	public var y:Int;
	
	/**
     * The z coordinate.
     */
	public var z:Int;

	public function new(x:Int = 0, y:Int = 0, z:Int = 0)
	{
		this.x = x;
		this.y = y;
		this.z = z;
	}
	
	public function absolute(vec:Vector3i = null):Void
	{
		if (vec != null)
		{
			this.x = FastMath.iabs(vec.x);
			this.y = FastMath.iabs(vec.y);
			this.z = FastMath.iabs(vec.z);
		}
		else
		{
			this.x = FastMath.iabs(this.x);
			this.y = FastMath.iabs(this.y);
			this.z = FastMath.iabs(this.z);
		}
	}
	
	public inline function fromVector3i(vec:Vector3i):Void
	{
		this.x = vec.x;
		this.y = vec.y;
		this.z = vec.z;
	}
	
	public inline function fromArray(a:Array<Int>):Void
	{
		this.x = a[0];
		this.y = a[1];
		this.z = a[2];
	}
	
	public function toArray(a:Array<Int>):Void
	{
		a[0] = this.x;
		a[1] = this.y;
		a[2] = this.z;
	}
	
	public inline function setTo(x:Int, y:Int, z:Int):Void
	{
		this.x = x;
		this.y = y;
		this.z = z;
	}
	
	public function add(vec1:Vector3i,vec2:Vector3i = null):Void
	{
		if (vec2 != null)
		{
			this.x = vec1.x + vec2.x;
			this.y = vec1.y + vec2.y;
			this.z = vec1.z + vec2.z;
		}
		else
		{
			this.x += vec1.x;
			this.y += vec1.y;
			this.z += vec1.z;
		}
	}

	public function sub(vec1:Vector3i, vec2:Vector3i = null):Void
	{
		if (vec2 != null)
		{
			this.x = vec1.x - vec2.x;
			this.y = vec1.y - vec2.y;
			this.z = vec1.z - vec2.z;
		}
		else
		{
			this.x -= vec1.x;
			this.y -= vec1.y;
			this.z -= vec1.z;
		}
	}
	
	public function negate(vec:Vector3i = null):Void
	{
		if (vec != null)
		{
			this.x = -vec.x;
			this.y = -vec.y;
			this.z = -vec.z;
		}
		else
		{
			this.x = -this.x;
			this.y = -this.y;
			this.z = -this.z;
		}
	}

	public function scale(s:Int, vec:Vector3i = null):Void
	{
		if (vec != null)
		{
			this.x = s * vec.x;
			this.y = s * vec.y;
			this.z = s * vec.z;
		}
		else
		{
			this.x *= s;
			this.y *= s;
			this.z *= s;
		}	
	}

	public function scaleAdd(s:Int, sVec:Vector3i, aVec:Vector3i):Void
	{
		this.x = s * sVec.x + aVec.x;
		this.y = s * sVec.y + aVec.y;
		this.z = s * sVec.z + aVec.z;
	}
	
	public function equals(vec:Vector3i):Bool
	{
		return this.x == vec.x && this.y == vec.y && this.z == vec.z;
	}

	public inline function clone():Vector3i
	{
		return new Vector3i(x, y, z);
	}
	
	public function toString():String
	{
		return '($x, $y, $z )';
	}
	
}