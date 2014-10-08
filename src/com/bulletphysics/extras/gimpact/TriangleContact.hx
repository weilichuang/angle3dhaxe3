
package com.bulletphysics.extras.gimpact;

import com.bulletphysics.BulletGlobals;
import com.bulletphysics.util.ObjectArrayList;
import com.vecmath.Vector3f;
import com.vecmath.Vector4f;


/**
 * @author weilichuang
 */
class TriangleContact
{
    public static inline var MAX_TRI_CLIPPING:Int = 16;

    public var penetration_depth:Float;
    public var point_count:Int;
    public var separating_normal:Vector4f = new Vector4f();
    public var points:Array<Vector3f>;

    public function new() 
	{
		points = [];
        for (i in 0...MAX_TRI_CLIPPING)
		{
            points[i] = new Vector3f();
        }
    }

    public function copyFrom(other:TriangleContact):Void
	{
        penetration_depth = other.penetration_depth;
        separating_normal.fromVector4f(other.separating_normal);
        point_count = other.point_count;
        var i:Int = point_count;
        while ((i--) != 0)
		{
            points[i].fromVector3f(other.points[i]);
        }
    }

    /**
     * Classify points that are closer.
     */
    public function merge_points(plane:Vector4f, margin:Float, points:ObjectArrayList<Vector3f>, point_count:Int):Void
	{
        this.point_count = 0;
        penetration_depth = -1000.0;

        var point_indices:Array<Int> = [];

        for (_k in 0...point_count) 
		{
            var _dist:Float = -ClipPolygon.distance_point_plane(plane, points.getQuick(_k)) + margin;

            if (_dist >= 0.0)
			{
                if (_dist > penetration_depth)
				{
                    penetration_depth = _dist;
                    point_indices[0] = _k;
                    this.point_count = 1;
                } 
				else if ((_dist + BulletGlobals.SIMD_EPSILON) >= penetration_depth)
				{
                    point_indices[this.point_count] = _k;
                    this.point_count++;
                }
            }
        }

        for (_k in 0...this.point_count)
		{
            this.points[_k].fromVector3f(points.getQuick(point_indices[_k]));
        }
    }

}
