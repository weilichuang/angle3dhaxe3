/*
Copyright (c) 2012-2014 Michael Baczynski, http://www.polygonal.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
package de.polygonal.core.math;

import de.polygonal.core.math.Coord3f;
import de.polygonal.core.math.Mathematics.M;

/**
	A 3d vector; a geometric object that has both a magnitude (or length) and direction.
**/
class Vec3 extends Coord3f
{
	/**
		`output` = `a` + `b`.
	**/
	inline public static function add(a:Vec3, b:Vec3, output:Vec3):Vec3
	{
		output.x = a.x + b.x;
		output.y = a.y + b.y;
		output.z = a.z + b.z;
		return output;
	}
	
	/**
		`output` = `a` - `b`.
	**/
	inline public static function sub(a:Vec3, b:Vec3, output:Vec3):Vec3
	{
		output.x = a.x - b.x;
		output.y = a.y - b.y;
		output.z = a.z - b.z;
		return output;
	}
	
	/**
		`output` = `a` · `b`.
	**/
	inline public static function dot(a:Vec3, b:Vec3, output:Vec3):Float
	{
		return a.x * b.x + a.y * b.y + a.z * b.z;
	}
	
	/**
		`output` = `a` × `b`.
	**/
	inline public static function cross(a:Vec3, b:Vec3, output:Vec3):Vec3
	{
		output.x = a.y * b.z - a.z * b.y;
		output.y = a.z * b.x - a.x * b.z;
		output.z = a.x * b.y - a.y * b.x;
		return output;
	}
	
	/**
		Homogeneous coordinate. Default is 1.
	**/
	public var w:Float;
	
	public function new(x:Float = 0, y:Float = 0, z:Float = 0)
	{
		super(x, y, z);
		w = 1;
	}
	
	inline public function flip()
	{
		x = -x;
		y = -y;
		z = -z;
	}
	
	/**
		The vector length.
	**/
	inline function length():Float
	{
		return Math.sqrt(lengthSq());
	}
	
	/**
		The squared vector length.
	**/
	inline function lengthSq():Float
	{
		return x * x + y * y + z * z;
	}
	
	/**
		Converts this vector to unit length and returns the original vector length.
	**/
	public function normalize():Float
	{
		var l = length();
		l = l < M.EPS ? 0 : 1 / l;
		x *= l;
		y *= l;
		z *= l;
		return l;
	}
	
	/**
		Scales this vector by `value`.
	**/
	inline public function scale(value:Float)
	{
		x *= value;
		y *= value;
		z *= value;
	}
	
	/**
		Clamps this vector to `max` length.
	**/
	inline public function clamp(max:Float)
	{
		var l = lengthSq();
		if (l > max * max)
		{
			l = 1 / Math.sqrt(l);
			x = (x * l) * max;
			y = (y * l) * max;
			z = (z * l) * max;
		}
	}
	
	override public function clone():Vec3
	{
		return new Vec3(x, y, z);
	}
	
	override public function toString():String
	{
		return Printf.format("{ Vec3 %-.4f %-.4f %-.4f %-.4f }", [x, y, z, w]);
	}
}