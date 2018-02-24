package com.bulletphysics.linearmath;
import angle3d.math.FastMath;

/**
 * Utility functions for scalars (floats).
 
 */
class ScalarUtil
{

	public static inline function fsel(a:Float, b:Float, c:Float):Float
	{
        return a >= 0 ? b : c;
    }

    public static function fuzzyZero(x:Float):Bool 
	{
        return FastMath.abs(x) < BulletGlobals.FLT_EPSILON;
    }

    public static function atan2Fast(y:Float, x:Float):Float
	{
        var coeff_1:Float = BulletGlobals.SIMD_PI / 4.0;
        var coeff_2:Float = 3.0 * coeff_1;
        var abs_y:Float = FastMath.abs(y);
        var angle:Float;
        if (x >= 0.0)
		{
            var r:Float = (x - abs_y) / (x + abs_y);
            angle = coeff_1 - coeff_1 * r;
        } 
		else
		{
            var r:Float = (x + abs_y) / (abs_y - x);
            angle = coeff_2 - coeff_1 * r;
        }
        return (y < 0.0) ? -angle : angle;
    }
	
}