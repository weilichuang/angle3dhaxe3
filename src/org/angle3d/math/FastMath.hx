package org.angle3d.math;

import org.angle3d.math.Vector3f;

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
	
	public static inline function toRadians(angle:Float):Float
	{
		return angle * Math.PI / 180;
	}
	
	public static inline function toDegrees(angle:Float):Float
	{
		return angle * 180 / Math.PI;
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

	
	public static function randomInt(min:Int, max:Int):Int
	{
		return min + Std.int((max - min + 1) * Math.random());
	}

	
	public static function rangeRandom(min:Float, max:Float):Float
	{
		return min + (max - min) * Math.random();
	}

	
	public static function signum(f:Float):Float
	{
		if (Math.isNaN(f))
		{
			return Math.NaN;
		}
		else if (f > 0)
		{
			return 1;
		}
		else if (f < 0)
		{
			return -1;
		}
		else
		{
			return 0;
		}
	}

	
	public static function clamp(value:Float, low:Float, high:Float):Float
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

	public static inline function abs(x:Float):Float
	{
		return (x < 0) ? -x : x;
	}

	public static inline function min(a:Float, b:Float):Float
	{
		return (a < b) ? a : b;
	}

	public static inline function max(a:Float, b:Float):Float
	{
		return (a > b) ? a : b;
	}
	
	public static inline function minInt(a:Int, b:Int):Int
	{
		return (a < b) ? a : b;
	}

	public static inline function maxInt(a:Int, b:Int):Int
	{
		return (a > b) ? a : b;
	}

	public static function getPowerOfTwo(value:Int):Int
	{
		var tmp:Int = 1;
		while (tmp < value)
			tmp <<= 1;
		return tmp;
	}

	public static function log2(value:Int):Int
	{
		var result:Int = -1;
		while (value > 0)
		{
			value >>= 1;
			result++;
		}
		return result;
	}

	/**
	* test 100000 times,this 4ms,and Math.pow 18ms
	* This method produces results which are nearly identical to Math.pow(), although the
	* last few digits may be different due to numerical error.  Unlike Math.pow(), this
	* method requires the exponent to be an integer.
	*/
	public static function pow(base:Float, exponent:Int):Float
	{
		if (exponent < 0)
		{
			exponent = -exponent;
			base = 1.0 / base;
		}
		var result:Float = 1.0;
		while (exponent != 0)
		{
			if ((exponent & 1) == 1)
				result *= base;
			base *= base;
			exponent = exponent >> 1;
		}
		return result;
	}

	/**
	 * Linear interpolation from startValue to endValue by the given percent.
	 * Basically: ((1 - percent) * startValue) + (percent * endValue)
	 *
	 * @param scale
	 *            scale value to use. if 1, use endValue, if 0, use startValue.
	 * @param startValue
	 *            Begining value. 0% of f
	 * @param endValue
	 *            ending value. 100% of f
	 * @return The interpolated value between startValue and endValue.
	 */
	public static function lerp(startValue:Float, endValue:Float, interp:Float):Float
	{
		if (interp <= 0)
		{
			return startValue;
		}
		else if (interp >= 1)
		{
			return endValue;
		}
		else
		{
			return startValue + (endValue - startValue) * interp;
		}
	}

	/**
	 * Linear interpolation from startValue to endValue by the given percent.
	 * Basically: ((1 - percent) * startValue) + (percent * endValue)
	 *
	 * @param scale
	 *            scale value to use. if 1, use endValue, if 0, use startValue.
	 * @param startValue
	 *            Begining value. 0% of f
	 * @param endValue
	 *            ending value. 100% of f
	 * @param store a vector3f to store the result
	 * @return The interpolated value between startValue and endValue.
	 */
	public static function lerpVector3(startValue:Vector3f, endValue:Vector3f, interp:Float, store:Vector3f = null):Vector3f
	{
		if (store == null)
		{
			store = new Vector3f();
		}
		store.x = lerp(startValue.x, endValue.x, interp);
		store.y = lerp(startValue.y, endValue.y, interp);
		store.z = lerp(startValue.z, endValue.z, interp);
		return store;
	}
}


