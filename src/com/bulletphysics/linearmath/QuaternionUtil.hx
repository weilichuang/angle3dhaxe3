package com.bulletphysics.linearmath;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;

/**
 * Utility functions for quaternions.
 
 */
class QuaternionUtil
{

	public static inline function getAngle(q:Quaternion):Float 
	{
        return 2 * Math.acos(q.w);
    }

    public static inline function setRotation(q:Quaternion, axis:Vector3f, angle:Float):Void 
	{
        var d:Float = axis.length;
        //assert (d != 0f);
        var s:Float = Math.sin(angle * 0.5) / d;
        q.setTo(axis.x * s, axis.y * s, axis.z * s, Math.cos(angle * 0.5));
    }

    // Game Programming Gems 2.10. make sure v0,v1 are normalized
    public static function shortestArcQuat(v0:Vector3f, v1:Vector3f, out:Quaternion):Quaternion 
	{
        var c:Vector3f = new Vector3f();
        c.crossBy(v0, v1);
        var d:Float = v0.dot(v1);

        if (d < -1.0 + BulletGlobals.FLT_EPSILON)
		{
            // just pick any vector
            out.setTo(0.0, 1.0, 0.0, 0.0);
            return out;
        }

        var s:Float = Math.sqrt((1.0 + d) * 2.0);
        var rs:Float = 1.0 / s;

        out.setTo(c.x * rs, c.y * rs, c.z * rs, s * 0.5);
        return out;
    }

    public static inline function mul(q:Quaternion, w:Vector3f):Void
	{
        var rx:Float = q.w * w.x + q.y * w.z - q.z * w.y;
        var ry:Float = q.w * w.y + q.z * w.x - q.x * w.z;
        var rz:Float = q.w * w.z + q.x * w.y - q.y * w.x;
        var rw:Float = -q.x * w.x - q.y * w.y - q.z * w.z;
        q.setTo(rx, ry, rz, rw);
    }

	private static var tmpQuat:Quaternion = new Quaternion();
	private static var tmpQuat2:Quaternion = new Quaternion();
    public static inline function quatRotate(rotation:Quaternion, v:Vector3f, out:Vector3f):Vector3f
	{
        tmpQuat.copyFrom(rotation);
        QuaternionUtil.mul(tmpQuat, v);

        inverse(tmpQuat2, rotation);
        tmpQuat.multLocal(tmpQuat2);

        out.setTo(tmpQuat.x, tmpQuat.y, tmpQuat.z);
        return out;
    }

    public static inline function inverse(q:Quaternion, src:Quaternion = null):Void
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

    public static function setEuler(q:Quaternion, yaw:Float, pitch:Float, roll:Float):Void
	{
		var M = Math;
        var halfYaw:Float = yaw * 0.5;
        var halfPitch:Float = pitch * 0.5;
        var halfRoll:Float = roll * 0.5;
        var cosYaw:Float = M.cos(halfYaw);
        var sinYaw:Float = M.sin(halfYaw);
        var cosPitch:Float = M.cos(halfPitch);
        var sinPitch:Float = M.sin(halfPitch);
        var cosRoll:Float = M.cos(halfRoll);
        var sinRoll:Float = M.sin(halfRoll);
        q.x = cosRoll * sinPitch * cosYaw + sinRoll * cosPitch * sinYaw;
        q.y = cosRoll * cosPitch * sinYaw - sinRoll * sinPitch * cosYaw;
        q.z = sinRoll * cosPitch * cosYaw - cosRoll * sinPitch * sinYaw;
        q.w = cosRoll * cosPitch * cosYaw + sinRoll * sinPitch * sinYaw;
    }
	
}