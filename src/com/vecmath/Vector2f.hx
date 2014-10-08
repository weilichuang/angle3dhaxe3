package com.vecmath;

/**
 * A 2-element vector that is represented by single-precision floating 
 * point x,y coordinates.
 *
 */
class Vector2f
{
	/**
     * The x coordinate.
     */
	public var x:Float;
	
	/**
     * The y coordinate.
     */
	public var y:Float;

	public function new(x:Float = 0, y:Float = 0)
	{
		this.x = x;
		this.y = y;
	}
	
	public inline function fromVector2f(vec:Vector2f):Void
	{
		this.x = vec.x;
		this.y = vec.y;
	}
	
	public inline function fromArray(a:Array<Float>):Void
	{
		this.x = a[0];
		this.y = a[1];
	}
	
	public function toArray(a:Array<Float>):Void
	{
		a[0] = this.x;
		a[1] = this.y;
	}
	
	public inline function setTo(x:Float, y:Float):Void
	{
		this.x = x;
		this.y = y;
	}
	
	public function add(vec1:Vector2f, vec2:Vector2f = null):Void
	{
		if (vec2 != null)
		{
			this.x = vec1.x + vec2.x;
			this.y = vec1.y + vec2.y;
		}
		else
		{
			this.x += vec1.x;
			this.y += vec1.y;
		}
	}

	public function sub2(vec1:Vector2f, vec2:Vector2f = null):Void
	{
		if (vec2 != null) 
		{
			this.x = vec1.x - vec2.x;
			this.y = vec1.y - vec2.y;
		}
		else
		{
			this.x -= vec1.x;
			this.y -= vec1.y;
		}
	}
	
	public function negate(vec:Vector2f = null):Void
	{
		if (vec != null)
		{
			this.x = -vec.x;
			this.y = -vec.y;
		}
		else
		{
			this.x = -this.x;
			this.y = -this.y;
		}
	}

	public function scale(s:Float, vec:Vector2f = null):Void
	{
		if (vec != null)
		{
			this.x = s * vec.x;
			this.y = s * vec.y;
		}
		else
		{
			this.x *= s;
			this.y *= s;
		}
	}

	public function scaleAdd(s:Float, sVec:Vector2f, aVec:Vector2f):Void
	{
		this.x = s * sVec.x + aVec.x;
		this.y = s * sVec.y + aVec.y;
	}
	
	public function equals(vec:Vector2f):Bool
	{
		return this.x == vec.x && this.y == vec.y;
	}
	
	public function epsilonEquals(vec:Vector2f, epsilon:Float):Bool
	{
		var diff:Float = this.x - vec.x;
		if ((diff < 0 ? -diff : diff) > epsilon)
			return false;
			
		diff = this.y - vec.y;
		if ((diff < 0 ? -diff : diff) > epsilon)
			return false;
		
		return true;
	}
	
	public inline function lengthSquared():Float
	{
		return x * x + y * y;
	}
	
	public inline function length():Float
	{
		return Math.sqrt(x * x + y * y);
	}

	public function dot(v1:Vector2f):Float
	{
		return x * v1.x + y * v1.y;
	}
	
	public function normalize():Void
	{
        var norm:Float = Math.sqrt(this.x * this.x + this.y * this.y);
		if (norm != 0)
			norm = 1 / norm;
        this.x *= norm;
        this.y *= norm;
	}
	
	public function angle(v1:Vector2f):Float
	{
		var vDot:Float = this.dot(v1) / ( this.length() * v1.length());
        if( vDot < -1.0) vDot = -1.0;
        if( vDot >  1.0) vDot =  1.0;
        return Math.acos(vDot);
	}
	
	public inline function clone():Vector2f
	{
		return new Vector2f(x, y);
	}
	
	public function toString():String
	{
		return '($x, $y)';
	}
	
}