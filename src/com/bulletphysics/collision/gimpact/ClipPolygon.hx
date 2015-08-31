package com.bulletphysics.collision.gimpact ;
import com.bulletphysics.linearmath.LinearMathUtil;
import com.bulletphysics.util.ObjectArrayList;
import com.vecmath.Vector3f;
import org.angle3d.math.Vector4f;

/**
 * ...
 * @author weilichuang
 */
class ClipPolygon
{

	public static function distance_point_plane(plane:Vector4f, point:Vector3f):Float
	{
        return LinearMathUtil.dot3(point, plane) - plane.w;
    }

    /**
     * Vector blending. Takes two vectors a, b, blends them together.
     */
    public static function vec_blend( vr:Vector3f, va:Vector3f, vb, blend_factor:Float):Void 
	{
        vr.scale2(1 - blend_factor, va);
        vr.scaleAdd(blend_factor, vb, vr);
    }

    /**
     * This function calcs the distance from a 3D plane.
     */
    public static function plane_clip_polygon_collect(point0:Vector3f, point1:Vector3f, dist0:Float, dist1:Float, clipped:ObjectArrayList<Vector3f>, clipped_count:Array<Int>):Void 
	{
        var _prevclassif:Bool = (dist0 > BulletGlobals.SIMD_EPSILON);
        var _classif:Bool = (dist1 > BulletGlobals.SIMD_EPSILON);
        if (_classif != _prevclassif)
		{
            var blendfactor:Float = -dist0 / (dist1 - dist0);
            vec_blend(clipped.getQuick(clipped_count[0]), point0, point1, blendfactor);
            clipped_count[0]++;
        }
        if (!_classif) 
		{
            clipped.getQuick(clipped_count[0]).copyFrom(point1);
            clipped_count[0]++;
        }
    }

    /**
     * Clips a polygon by a plane.
     *
     * @return The count of the clipped counts
     */
    public static function plane_clip_polygon(plane:Vector4f, polygon_points:ObjectArrayList<Vector3f>, 
											polygon_point_count:Int, clipped:ObjectArrayList<Vector3f>):Int
	{
        var clipped_count:Array<Int> = [];
        clipped_count[0] = 0;

        // clip first point
        var firstdist:Float = distance_point_plane(plane, polygon_points.getQuick(0));
        if (!(firstdist > BulletGlobals.SIMD_EPSILON))
		{
            clipped.getQuick(clipped_count[0]).copyFrom(polygon_points.getQuick(0));
            clipped_count[0]++;
        }

        var olddist:Float = firstdist;
        for (i in 1...polygon_point_count)
		{
            var dist:Float = distance_point_plane(plane, polygon_points.getQuick(i));

            plane_clip_polygon_collect(
                    polygon_points.getQuick(i - 1), polygon_points.getQuick(i),
                    olddist,
                    dist,
                    clipped,
                    clipped_count);


            olddist = dist;
        }

        // RETURN TO FIRST point

        plane_clip_polygon_collect(
                polygon_points.getQuick(polygon_point_count - 1), polygon_points.getQuick(0),
                olddist,
                firstdist,
                clipped,
                clipped_count);

        var ret:Int = clipped_count[0];
        return ret;
    }

    /**
     * Clips a polygon by a plane.
     *
     * @param clipped must be an array of 16 points.
     * @return the count of the clipped counts
     */
    public static function plane_clip_triangle(plane:Vector4f, point0:Vector3f, point1:Vector3f, point2:Vector3f, clipped:ObjectArrayList<Vector3f>):Int
	{
        var clipped_count:Array<Int> = [];
        clipped_count[0] = 0;

        // clip first point0
        var firstdist:Float = distance_point_plane(plane, point0);
        if (!(firstdist > BulletGlobals.SIMD_EPSILON)) 
		{
            clipped.getQuick(clipped_count[0]).copyFrom(point0);
            clipped_count[0]++;
        }

        // point 1
        var olddist:Float = firstdist;
        var dist:Float = distance_point_plane(plane, point1);

        plane_clip_polygon_collect(
                point0, point1,
                olddist,
                dist,
                clipped,
                clipped_count);

        olddist = dist;


        // point 2
        dist = distance_point_plane(plane, point2);

        plane_clip_polygon_collect(
                point1, point2,
                olddist,
                dist,
                clipped,
                clipped_count);
        olddist = dist;


        // RETURN TO FIRST point0
        plane_clip_polygon_collect(
                point2, point0,
                olddist,
                firstdist,
                clipped,
                clipped_count);

        var ret:Int = clipped_count[0];
        return ret;
    }
}