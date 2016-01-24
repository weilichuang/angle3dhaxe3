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

typedef M = de.polygonal.core.math.Mathematics;

/**
	Various math functions and constants.
**/
class Mathematics
{
	/**
		IEEE 754 NAN.
	**/
	#if !flash
	public static var NaN = Math.NaN;
	#else
	inline public static var NaN = 0. / 0.;
	#end
	
	/**
		IEEE 754 positive infinity.
	**/
	#if !flash
	public static var POSITIVE_INFINITY = Math.POSITIVE_INFINITY;
	#else
	inline public static var POSITIVE_INFINITY = 1. / 0.;
	#end
	
	/**
		IEEE 754 negative infinity.
	**/
	#if !flash
	public static var NEGATIVE_INFINITY = Math.NEGATIVE_INFINITY;
	#else
	inline public static var NEGATIVE_INFINITY = -1. / 0.;
	#end
	
	/**
		Values below `ZERO_TOLERANCE` are treated as zero.
	**/
	inline public static var ZERO_TOLERANCE = 1e-08;
	
	/**
		Multiply a value by this constant to convert from radians to degrees (180 / PI).
	**/
	inline public static var RAD_DEG = 57.29577951308232;
	
	/**
		Multiply a value by this constant to convert from degrees to radians (PI / 180).
	**/
	inline public static var DEG_RAD = 0.017453292519943295;
	
	/**
		The natural logarithm of 2.
	**/
	inline public static var LN2 = 0.6931471805599453;
	
	/**
		The natural logarithm of 10.
	**/
	inline public static var LN10 = 2.302585092994046;
	
	/**
		PI / 2.
	**/
	inline public static var PI_OVER_2 = 1.5707963267948966;
	
	/**
		PI / 4.
	**/
	inline public static var PI_OVER_4 = 0.7853981633974483;
	
	/**
		PI.
	**/
	inline public static var PI = 3.141592653589793;
	
	/**
		2 * PI.
	**/
	inline public static var PI2 = 6.283185307179586;
	
	/**
		Default system epsilon.
	**/
	inline public static var EPS = 1e-6;
	
	/**
		The square root of 2.
	**/
	inline public static var SQRT2 = 1.414213562373095;
	
	#if flash10
	/**
		Returns the 32-bit integer representation of a IEEE 754 single precision floating point.
	**/
	inline public static function floatToInt(x:Float):Int
	{
		flash.Memory.setFloat(0, x);
		return flash.Memory.getI32(0);
	}
	
	/**
		Returns the IEEE 754 single precision floating point representation of a 32-bit integer.
	**/
	inline public static function intToFloat(x:Int):Float
	{
		flash.Memory.setI32(0, x);
		return flash.Memory.getFloat(0);
	}
	#end
	
	/**
		Converts `deg` to radians.
	**/
	inline public static function toRad(deg:Float):Float
	{
		return deg * DEG_RAD;
	}
	
	/**
		Converts `rad` to degrees.
	**/
	inline public static function toDeg(rad:Float):Float
	{
		return rad * RAD_DEG;
	}
	
	/**
		Returns min(`x`,`y`).
	**/
	inline public static function min(x:Int, y:Int):Int
	{
		return x < y ? x : y;
	}
	
	/**
		Returns max(`x`,`y`).
	**/
	inline public static function max(x:Int, y:Int):Int
	{
		return x > y ? x : y;
	}
	
	/**
		Returns the absolute value of `x`.
	**/
	inline public static function abs(x:Int):Int
	{
		return x < 0 ? -x : x;
	}
	
	/**
		Returns the sign of `x` (sgn(0) = 0).
	**/
	inline public static function sgn(x:Int):Int
	{
		return (x > 0) ? 1 : (x < 0 ? -1 : 0);
	}
	
	/**
		Clamps `x` to the interval [`min`,`max`].
	**/
	inline public static function clamp(x:Int, min:Int, max:Int):Int
	{
		return (x < min) ? min : (x > max) ? max : x;
	}
	
	/**
		Clamps `x` to the interval [-`i`,`i`].
	**/
	inline public static function clampSym(x:Int, i:Int):Int
	{
		return (x < -i) ? -i : (x > i) ? i : x;
	}
	
	/**
		Normalize `x` to [0,`y`).
	**/
	inline public static function wrap(x:Float, y:Float)
	{
		x = x % y;
		if (x < 0) x += y;
		return x;
	}
	
	/**
		Normalize `x` to [-`y`,`y`).
	**/
	inline public static function wrapSym(x:Float, y:Float)
	{
		if (y < 0) y = -y;
		x = (x + y) % (2 * y);
		if (x < 0) x += (2 * y);
		return x - y;
	}
	
	/**
		Fast version of Math.min(`x`,`y`).
	**/
	inline public static function fmin(x:Float, y:Float):Float
	{
		return x < y ? x : y;
	}
	
	/**
		Returns max(`x`,`y`).
	**/
	inline public static function fmax(x:Float, y:Float):Float
	{
		return x > y ? x : y;
	}
	
	/**
		Fast version of Math.abs(`x`).
	**/
	inline public static function fabs(x:Float):Float
	{
		return x < 0 ? -x : x;
	}
	
	/**
		Extracts the sign of `x` (fsgn(0) = 0).
	**/
	inline public static function fsgn(x:Float):Int
	{
		return (x > 0.) ? 1 : (x < 0. ? -1 : 0);
	}
	
	/**
		Clamps `x` to the interval [`min`,`max`].
	**/
	inline public static function fclamp(x:Float, min:Float, max:Float):Float
	{
		return (x < min) ? min : (x > max) ? max : x;
	}
	
	/**
		Clamps `x` to the interval [-`i`,`i`].
	**/
	inline public static function fclampSym(x:Float, i:Float):Float
	{
		return (x < -i) ? -i : (x > i) ? i : x;
	}
	
	/**
		Returns true if the signs of `x` and `y` are equal.
	**/
	inline public static function eqSgn(x:Int, y:Int):Bool
	{
		return (x ^ y) >= 0;
	}
	
	/**
		Returns true if `x` is even.
	**/
	inline public static function isEven(x:Int):Bool
	{
		return (x & 1) == 0;
	}
	
	/**
		Returns true if `x` is a power of two.
	**/
	inline public static function isPow2(x:Int):Bool
	{
		return x > 0 && (x & (x - 1)) == 0;
	}
	
	/**
		Linear interpolation over interval [`a`,`b`] with `t` = [0,1].
	**/
	inline public static function lerp(a:Float, b:Float, t:Float):Float
	{
		return a + (b - a) * t;
	}
	
	/**
		Spherically interpolates between two angles.
	**/
	inline public static function slerp(a:Float, b:Float, t:Float)
	{
		var m = Math;
		var c1 = m.sin(a * .5);
		var r1 = m.cos(a * .5);
		var c2 = m.sin(b * .5);
		var r2 = m.cos(b * .5);
		var c = r1 * r2 + c1 * c2;
		if (c < 0.)
		{
			if ((1. + c) > EPS)
			{
				var o = m.acos(-c);
				var s = m.sin(o);
				var s0 = m.sin((1 - t) * o) / s;
				var s1 = m.sin(t * o) / s;
				return m.atan2(s0 * c1 - s1 * c2, s0 * r1 - s1 * r2) * 2.;
			}
			else
			{
				var s0 = 1 - t;
				var s1 = t;
				return m.atan2(s0 * c1 - s1 * c2, s0 * r1 - s1 * r2) * 2;
			}
		}
		else
		{
			if ((1 - c) > EPS)
			{
				var o = m.acos(c);
				var s = m.sin(o);
				var s0 = m.sin((1 - t) * o) / s;
				var s1 = m.sin(t * o) / s;
				return m.atan2(s0 * c1 + s1 * c2, s0 * r1 + s1 * r2) * 2.;
			}
			else
			{
				var s0 = 1 - t;
				var s1 = t;
				return m.atan2(s0 * c1 + s1 * c2, s0 * r1 + s1 * r2) * 2.;
			}
		}
	}
	
	/**
		Calculates the next highest power of 2 of `x`.
		
		- `x` must be in the range [0,2^30].
		- returns `x` if `x` is already a power of 2.
	**/
	inline public static function nextPow2(x:Int):Int
	{
		var t = x - 1;
		t |= (t >> 1);
		t |= (t >> 2);
		t |= (t >> 4);
		t |= (t >> 8);
		t |= (t >> 16);
		return t + 1;
	}
	
	/**
		Fast integer exponentiation for base `a` and exponent `n`.
	**/
	inline public static function exp(a:Int, n:Int):Int
	{
		var t = 1;
		var r = 0;
		while (true)
		{
			if (n & 1 != 0) t = a * t;
			n >>= 1;
			if (n == 0)
			{
				r = t;
				break;
			}
			else
				a *= a;
		}
		return r;
	}
	
	/**
		Returns the base-10 logarithm of `x`.
	**/
	inline public static function log10(x:Float):Float
	{
		return Math.log(x) * 0.4342944819032517;
	}
	
	/**
		Rounds `x` to the iterval `y`.
	**/
	inline public static function roundTo(x:Float, y:Float):Float
	{
		#if js
		return Math.round(x / y) * y;
		#elseif flash
		var t:Float = untyped __global__["Math"].round((x / y));
		return t * y;
		#else
		var t = x / y;
		if (t < Limits.INT32_MAX && t > Limits.INT32_MIN)
			return round(t) * y;
		else
		{
			t = (t > 0 ? t + .5 : (t < 0 ? t - .5 : t));
			return (t - t % 1) * y;
		}
		#end
	}
	
	/**
		Fast version of Math.round(`x`).
		
		Half-way cases are rounded away from zero.
	**/
	inline public static function round(x:Float):Int
	{
		return Std.int(x + (0x4000 + .5)) - 0x4000;
	}
	
	/**
		Fast version of Math.ceil(`x`).
	**/
	inline public static function ceil(x:Float):Int
	{
		var f:Int =
		#if cpp
		cast x;
		#else
		Std.int(x);
		#end
		if (x == f) return f;
		else
		{
			x += 1;
			var f:Int =
			#if cpp
			cast x;
			#else
			Std.int(x);
			#end
			if (x < 0 && f != x) f--;
			return f;
		}
	}
	
	/**
		Fast version of Math.floor(`x`).
	**/
	inline public static function floor(x:Float):Int
	{
		var f:Int =
		#if cpp
		cast x;
		#else
		Std.int(x);
		#end
		if (x < 0 && f != x) f--;
		return f;
	}
	
	/**
		Computes the "quake-style" fast inverse square root of `x`.
	**/
	inline public static function invSqrt(x:Float):Float
	{
		#if flash10
		var xt = x;
		var half = .5 * xt;
		var i = floatToInt(xt);
		i = 0x5F3759DF - (i >> 1);
		var xt = intToFloat(i);
		return xt * (1.5 - half * xt * xt);
		#else
		return 1 / Math.sqrt(x);
		#end
	}
	
	/**
		Compares `x` and `y` using an absolute tolerance of `eps`.
	**/
	inline public static function cmpAbs(x:Float, y:Float, eps:Float):Bool
	{
		var d = x - y;
		return d > 0 ? d < eps : -d < eps;
	}
	
	/**
		Compares `x` to zero using an absolute tolerance of `eps`.
	**/
	inline public static function cmpZero(x:Float, eps:Float):Bool
	{
		return x > 0 ? x < eps : -x < eps;
	}
	
	/**
		Snaps `x` to the grid `y`.
	**/
	inline public static function snap(x:Float, y:Float):Float
	{
		return (floor((x + y * .5) / y));
	}
	
	/**
		Returns true if `min` <= `x` <= `max`.
	**/
	inline public static function inRange(x:Float, min:Float, max:Float):Bool
	{
		return x >= min && x <= max;
	}
	
	/**
		Computes the greatest common divisor of `x` and `y`.
	**/
	inline public static function gcd(x:Int, y:Int):Int
	{
		var d = 0;
		var r = 0;
		x = abs(x);
		y = abs(y);
		while (true)
		{
			if (y == 0)
			{
				d = x;
				break;
			}
			else
			{
				r = x % y;
				x = y;
				y = r;
			}
		}
		return d;
	}
	
	/**
		Removes excess floating point decimal precision from `x`.
	**/
	inline public static function maxPrecision(x:Float, precision:Int):Float
	{
		return roundTo(x, Math.pow(10, -precision));
	}
}