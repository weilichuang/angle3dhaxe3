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
	
	/**
     * Given 3 points in a 2d plane, this function computes if the points going from A-B-C
     * are moving counter clock wise.
     * @param p0 Point 0.
     * @param p1 Point 1.
     * @param p2 Point 2.
     * @return 1 If they are CCW, -1 if they are not CCW, 0 if p2 is between p0 and p1.
     */
    public static function counterClockwise(p0:Vector2f, p1:Vector2f, p2:Vector2f):Int
	{
        var dx1:Float, dx2:Float, dy1:Float, dy2:Float;
        dx1 = p1.x - p0.x;
        dy1 = p1.y - p0.y;
        dx2 = p2.x - p0.x;
        dy2 = p2.y - p0.y;
        if (dx1 * dy2 > dy1 * dx2)
		{
            return 1;
        }
        if (dx1 * dy2 < dy1 * dx2)
		{
            return -1;
        }
        if ((dx1 * dx2 < 0) || (dy1 * dy2 < 0))
		{
            return -1;
        }
        if ((dx1 * dx1 + dy1 * dy1) < (dx2 * dx2 + dy2 * dy2)) 
		{
            return 1;
        }
        return 0;
    }

    /**
     * Test if a point is inside a triangle.  1 if the point is on the ccw side,
     * -1 if the point is on the cw side, and 0 if it is on neither.
     * @param t0 First point of the triangle.
     * @param t1 Second point of the triangle.
     * @param t2 Third point of the triangle.
     * @param p The point to test.
     * @return Value 1 or -1 if inside triangle, 0 otherwise.
     */
    public static function pointInsideTriangle(t0:Vector2f, t1:Vector2f, t2:Vector2f, p:Vector2f):Int
	{
        var val1:Int = counterClockwise(t0, t1, p);
        if (val1 == 0) {
            return 1;
        }
        var val2:Int = counterClockwise(t1, t2, p);
        if (val2 == 0) {
            return 1;
        }
        if (val2 != val1) {
            return 0;
        }
        var val3:Int = counterClockwise(t2, t0, p);
        if (val3 == 0) {
            return 1;
        }
        if (val3 != val1) {
            return 0;
        }
        return val3;
    }
}


