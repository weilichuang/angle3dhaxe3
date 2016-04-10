package com.bulletphysics.collision.gimpact ;
import org.angle3d.math.Vector3f;

/**
 * ...
 
 */
class GImpactMassUtil
{

	public static function get_point_inertia(point:Vector3f, mass:Float, out:Vector3f):Vector3f
	{
        var x2:Float = point.x * point.x;
        var y2:Float = point.y * point.y;
        var z2:Float = point.z * point.z;
        out.setTo(mass * (y2 + z2), mass * (x2 + z2), mass * (x2 + y2));
        return out;
    }
	
}