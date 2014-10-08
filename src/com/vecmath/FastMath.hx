package com.vecmath;

class FastMath
{
	public static inline function ONE_THIRD():Float
	{
		return 1.0 / 3.0;
	}
	
	public static inline function INVERT_255():Float 
	{
		return 1.0 / 255;
	}
	
	public static inline function INV_PI():Float
	{
		return 1 / Math.PI;
	}

	public static inline function HALF_PI():Float
	{ 
		return Math.PI * 0.5;
	}
	
	public static inline function TWO_PI():Float 
	{
		return Math.PI * 2.0;
	}

	public static inline function RADTODEG():Float 
	{
		return 180 / Math.PI;
	}
	
	public static inline function DEGTORAD():Float 
	{
		return Math.PI / 180;
	}

	public static inline var ROUNDING_ERROR:Float = 0.0001;

	public static inline var FLT_EPSILON:Float = 1.1920928955078125E-7;

	/**
	 * A "close to zero" float epsilon value for use
	 */
	public static inline var ZERO_TOLERANCE:Float = 0.0001;

	
	public static function nearEqual(a:Float, b:Float, roundError:Float = 0.0001):Bool
	{
		return (a + roundError >= b) && (a - roundError <= b);
	}

	
	public static function iRangeRandom(min:Int, max:Int):Int
	{
		return min + Std.int((max - min + 1) * Math.random());
	}

	
	public static function fRangeRandom(min:Float, max:Float):Float
	{
		return min + (max - min) * Math.random();
	}

	public static function fclamp(value:Float, low:Float, high:Float):Float
	{
		if (value < low)
		{
			return low;
		}
		else if (value > high)
		{
			return high;
		}
		else
		{
			return value;
		}
	}

	public static inline function fabs(x:Float):Float
	{
		return (x < 0) ? -x : x;
	}
	
	public static inline function iabs(x:Int):Int
	{
		return (x < 0) ? -x : x;
	}

	public static inline function fmin(a:Float, b:Float):Float
	{
		return (a < b) ? a : b;
	}

	public static inline function fmax(a:Float, b:Float):Float
	{
		return (a > b) ? a : b;
	}
	
	public static inline function imin(a:Int, b:Int):Int
	{
		return (a < b) ? a : b;
	}

	public static inline function imax(a:Int, b:Int):Int
	{
		return (a > b) ? a : b;
	}
}


