package com.bulletphysics.linearmath;
import com.vecmath.Vector3f;
import com.vecmath.Vector4f;

/**
 * ...
 * @author weilichuang
 */
class VectorUtil
{

	public function new() 
	{
		
	}
	
	public static function maxAxis(v:Vector3f):Int
	{
        var maxIndex:Int = -1;
        var maxVal:Float = -1e30;
        if (v.x > maxVal)
		{
            maxIndex = 0;
            maxVal = v.x;
        }
        if (v.y > maxVal) 
		{
            maxIndex = 1;
            maxVal = v.y;
        }
        if (v.z > maxVal)
		{
            maxIndex = 2;
            maxVal = v.z;
        }

        return maxIndex;
    }

    public static function maxAxis4(v:Vector4f):Int 
	{
        var maxIndex:Int = -1;
        var maxVal:Float = -1e30;
        if (v.x > maxVal)
		{
            maxIndex = 0;
            maxVal = v.x;
        }
        if (v.y > maxVal) 
		{
            maxIndex = 1;
            maxVal = v.y;
        }
        if (v.z > maxVal)
		{
            maxIndex = 2;
            maxVal = v.z;
        }
        if (v.w > maxVal)
		{
            maxIndex = 3;
            maxVal = v.w;
        }

        return maxIndex;
    }

    public static function closestAxis4(vec:Vector4f):Int
	{
        var tmp:Vector4f = vec.clone();
        tmp.absolute();
        return maxAxis4(tmp);
    }

    public static function getCoord(vec:Vector3f, num:Int):Float
	{
        switch (num) 
		{
            case 0:
                return vec.x;
            case 1:
                return vec.y;
            case 2:
                return vec.z;
            default:
                throw 'OutOfBound $num';
        }
    }

    public static function setCoord(vec:Vector3f, num:Int, value:Float):Void 
	{
        switch (num) 
		{
            case 0:
                vec.x = value;
            case 1:
                vec.y = value;
            case 2:
                vec.z = value;
        }
    }

    public static function mulCoord(vec:Vector3f, num:Int, value:Float):Void
	{
        switch (num) 
		{
            case 0:
                vec.x *= value;
            case 1:
                vec.y *= value;
            case 2:
                vec.z *= value;
        }
    }

    public static function setInterpolate3(dest:Vector3f, v0:Vector3f, v1:Vector3f, rt:Float):Void
	{
        var s:Float = 1 - rt;
        dest.x = s * v0.x + rt * v1.x;
        dest.y = s * v0.y + rt * v1.y;
        dest.z = s * v0.z + rt * v1.z;
    }

    public static function add(dest:Vector3f, v1:Vector3f, v2:Vector3f):Void
	{
        dest.x = v1.x + v2.x;
        dest.y = v1.y + v2.y;
        dest.z = v1.z + v2.z;
    }

    public static function add3(dest:Vector3f, v1:Vector3f, v2:Vector3f, v3:Vector3f):Void
	{
        dest.x = v1.x + v2.x + v3.x;
        dest.y = v1.y + v2.y + v3.y;
        dest.z = v1.z + v2.z + v3.z;
    }

    public static function add4(dest:Vector3f, v1:Vector3f, v2:Vector3f, v3:Vector3f, v4:Vector3f):Void 
	{
        dest.x = v1.x + v2.x + v3.x + v4.x;
        dest.y = v1.y + v2.y + v3.y + v4.y;
        dest.z = v1.z + v2.z + v3.z + v4.z;
    }

    public static function mul(dest:Vector3f, v1:Vector3f, v2:Vector3f):Void 
	{
        dest.x = v1.x * v2.x;
        dest.y = v1.y * v2.y;
        dest.z = v1.z * v2.z;
    }

    public static function div(dest:Vector3f, v1:Vector3f, v2:Vector3f):Void
	{
        dest.x = v1.x / v2.x;
        dest.y = v1.y / v2.y;
        dest.z = v1.z / v2.z;
    }

    public static function setMin(a:Vector3f, b:Vector3f):Void 
	{
        a.x = Math.min(a.x, b.x);
        a.y = Math.min(a.y, b.y);
        a.z = Math.min(a.z, b.z);
    }

    public static function setMax(a:Vector3f, b:Vector3f):Void 
	{
        a.x = Math.max(a.x, b.x);
        a.y = Math.max(a.y, b.y);
        a.z = Math.max(a.z, b.z);
    }

    public static function dot3(v0:{x:Float,y:Float,z:Float}, v1:{x:Float,y:Float,z:Float}):Float
	{
        return (v0.x * v1.x + v0.y * v1.y + v0.z * v1.z);
    }

    public static inline function lengthSquared3(v:Vector4f):Float
	{
        return (v.x * v.x + v.y * v.y + v.z * v.z);
    }

    public static function normalize3(v:Vector4f):Void 
	{
        var norm:Float = (1.0 / Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z));
        v.x *= norm;
        v.y *= norm;
        v.z *= norm;
    }

    public static function cross3(dest:Vector3f, v1:Vector4f, v2:Vector4f):Void 
	{
        var x:Float, y:Float;
        x = v1.y * v2.z - v1.z * v2.y;
        y = v2.x * v1.z - v2.z * v1.x;
        dest.z = v1.x * v2.y - v1.y * v2.x;
        dest.x = x;
        dest.y = y;
    }
	
}