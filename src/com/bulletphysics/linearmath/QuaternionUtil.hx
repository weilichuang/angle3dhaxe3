package com.bulletphysics.linearmath;
import de.polygonal.core.math.Mathematics;
import vecmath.Quat4f;
import vecmath.Vector3f;

/**
 * Utility functions for quaternions.
 * @author weilichuang
 */
class QuaternionUtil
{

	public static function getAngle(q:Quat4f):Float 
	{
        var s:Float = 2 * Math.acos(q.w);
        return s;
    }

    public static function setRotation(q:Quat4f, axis:Vector3f, angle:Float):Void 
	{
        var d:Float = axis.length();
        //assert (d != 0f);
        var s:Float = Math.sin(angle * 0.5) / d;
        q.setTo(axis.x * s, axis.y * s, axis.z * s, Math.cos(angle * 0.5));
    }

    // Game Programming Gems 2.10. make sure v0,v1 are normalized
    public static function shortestArcQuat(v0:Vector3f, v1:Vector3f, out:Quat4f):Quat4f 
	{
        var c:Vector3f = new Vector3f();
        c.cross(v0, v1);
        var d:Float = v0.dot(v1);

        if (d < -1.0 + BulletGlobals.FLT_EPSILON)
		{
            // just pick any vector
            out.setTo(0.0, 1.0, 0.0, 0.0);
            return out;
        }

        var s:Float = Mathematics.sqrt((1.0 + d) * 2.0);
        var rs:Float = 1.0 / s;

        out.setTo(c.x * rs, c.y * rs, c.z * rs, s * 0.5);
        return out;
    }

    public static function mul(q:Quat4f, w:Vector3f):Void
	{
        var rx:Float = q.w * w.x + q.y * w.z - q.z * w.y;
        var ry:Float = q.w * w.y + q.z * w.x - q.x * w.z;
        var rz:Float = q.w * w.z + q.x * w.y - q.y * w.x;
        var rw:Float = -q.x * w.x - q.y * w.y - q.z * w.z;
        q.setTo(rx, ry, rz, rw);
    }

    public static function quatRotate(rotation:Quat4f, v:Vector3f, out:Vector3f):Vector3f
	{
        var q:Quat4f = rotation.clone();
        QuaternionUtil.mul(q, v);

        var tmp:Quat4f = new Quat4f();
        inverse(tmp, rotation);
        q.mul(tmp);

        out.setTo(q.x, q.y, q.z);
        return out;
    }

    public static function inverse(q:Quat4f, src:Quat4f = null):Void
	{
		if (src != null)
		{
			q.x = -src.x;
			q.y = -src.y;
			q.z = -src.z;
			q.w = src.w;
		}
		else
		{
			q.x = -q.x;
			q.y = -q.y;
			q.z = -q.z;
		}
    }

    public static function setEuler(q:Quat4f, yaw:Float, pitch:Float, roll:Float):Void
	{
        var halfYaw:Float = yaw * 0.5;
        var halfPitch:Float = pitch * 0.5;
        var halfRoll:Float = roll * 0.5;
        var cosYaw:Float = Math.cos(halfYaw);
        var sinYaw:Float = Math.sin(halfYaw);
        var cosPitch:Float = Math.cos(halfPitch);
        var sinPitch:Float = Math.sin(halfPitch);
        var cosRoll:Float = Math.cos(halfRoll);
        var sinRoll:Float = Math.sin(halfRoll);
        q.x = cosRoll * sinPitch * cosYaw + sinRoll * cosPitch * sinYaw;
        q.y = cosRoll * cosPitch * sinYaw - sinRoll * sinPitch * cosYaw;
        q.z = sinRoll * cosPitch * cosYaw - cosRoll * sinPitch * sinYaw;
        q.w = cosRoll * cosPitch * cosYaw + sinRoll * sinPitch * sinYaw;
    }
	
}