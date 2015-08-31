package com.vecmath;
import org.angle3d.math.FastMath;
import de.polygonal.core.math.Mathematics;

/**
 * A 3-element vector that is represented by single-precision floating point 
 * x,y,z coordinates.  If this value represents a normal, then it should
 * be normalized.
 *
 */
@:final class Vector3f
{
	/**
     * The x coordinate.
     */
	public var x:Float;
	
	/**
     * The y coordinate.
     */
	public var y:Float;
	
	/**
     * The z coordinate.
     */
	public var z:Float;
	
	public var length(get, null):Float;
	public var lengthSquared(get, null):Float;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0)
	{
		this.x = x;
		this.y = y;
		this.z = z;
	}
	
	private inline function get_length():Float
	{
		return Math.sqrt(x * x + y * y + z * z);
	}

	private inline function get_lengthSquared():Float
	{
		return x * x + y * y + z * z;
	}
	
	public function absoluteLocal():Vector3f
	{
		this.x = FastMath.abs(this.x);
		this.y = FastMath.abs(this.y);
		this.z = FastMath.abs(this.z);
		return this;
	}
	
	public function absoluteFrom(fromVec:Vector3f):Vector3f
	{
		this.x = FastMath.abs(fromVec.x);
		this.y = FastMath.abs(fromVec.y);
		this.z = FastMath.abs(fromVec.z);
		return this;
	}
	
	public inline function copyFrom(vec:Vector3f):Void
	{
		this.x = vec.x;
		this.y = vec.y;
		this.z = vec.z;
	}
	
	//public inline function fromArray(a:Array<Float>):Void
	//{
		//this.x = a[0];
		//this.y = a[1];
		//this.z = a[2];
	//}
	
	//public function toArray(a:Array<Float>):Void
	//{
		//a[0] = this.x;
		//a[1] = this.y;
		//a[2] = this.z;
	//}
	
	public inline function setTo(x:Float, y:Float, z:Float):Void
	{
		this.x = x;
		this.y = y;
		this.z = z;
	}
	
	public inline function addLocal(vec1:Vector3f):Void
	{
		this.x += vec1.x;
		this.y += vec1.y;
		this.z += vec1.z;
	}
	
	public inline function add2(vec1:Vector3f,vec2:Vector3f):Void
	{
		this.x = vec1.x + vec2.x;
		this.y = vec1.y + vec2.y;
		this.z = vec1.z + vec2.z;
	}
	
	public inline function subtractLocal(vec1:Vector3f):Void
	{
		this.x -= vec1.x;
		this.y -= vec1.y;
		this.z -= vec1.z;
	}

	public inline function sub2(vec1:Vector3f, vec2:Vector3f):Void
	{
		this.x = vec1.x - vec2.x;
		this.y = vec1.y - vec2.y;
		this.z = vec1.z - vec2.z;
	}
	
	public inline function negateLocal():Vector3f
	{
		this.x = -this.x;
		this.y = -this.y;
		this.z = -this.z;
		return this;
	}
	
	public inline function negateBy(vec:Vector3f):Void
	{
		this.x = -vec.x;
		this.y = -vec.y;
		this.z = -vec.z;
	}

	public inline function scaleLocal(s:Float):Vector3f
	{
		this.x *= s;
		this.y *= s;
		this.z *= s;
		return this;
	}
	
	public inline function scale2(s:Float, vec:Vector3f):Void
	{
		this.x = s * vec.x;
		this.y = s * vec.y;
		this.z = s * vec.z;
	}

	public inline function scaleAdd(s:Float, sVec:Vector3f, aVec:Vector3f):Void
	{
		this.x = s * sVec.x + aVec.x;
		this.y = s * sVec.y + aVec.y;
		this.z = s * sVec.z + aVec.z;
	}
	
	public inline function equals(vec:Vector3f):Bool
	{
		return this.x == vec.x && this.y == vec.y && this.z == vec.z;
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
	
	public inline function cross(v1:Vector3f, v2:Vector3f):Void
	{
		var tx:Float = v1.y * v2.z - v1.z * v2.y;
		var ty:Float = v2.x * v1.z - v2.z * v1.x;
		this.z = v1.x * v2.y - v1.y * v2.x;
		this.x = tx;
		this.y = ty;
	}
	
	public inline function dot(v1:Vector3f):Float
	{
		return x * v1.x + y * v1.y + z * v1.z;
	}
	
	public inline function normalize(vec:Vector3f = null):Void
	{
		if (vec != null)
			this.copyFrom(vec);
			
        var norm:Float = Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
		if (norm != 0)
			norm = 1 / norm;
        this.x *= norm;
        this.y *= norm;
        this.z *= norm;
	}
	
	//public function angle(v1:Vector3f):Float
	//{
		//var vDot:Float = this.dot(v1) / ( this.length * v1.length);
        //if( vDot < -1.0) vDot = -1.0;
        //if( vDot >  1.0) vDot =  1.0;
        //return Math.acos(vDot);
	//}
	
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
	
	public function toString():String
	{
		return '($x, $y, $z )';
	}
	
}