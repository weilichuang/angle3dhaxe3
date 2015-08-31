package com.bulletphysics.collision.gimpact ;
import com.bulletphysics.linearmath.LinearMathUtil;
import org.angle3d.math.Vector3f;
import org.angle3d.math.Vector4f;

/**
 * ...
 * @author weilichuang
 */
class GeometryOperations
{

	public static inline var PLANEDIREPSILON:Float = 0.0000001;
    public static inline var PARALELENORMALS:Float = 0.000001;

    public static inline function CLAMP(number:Float, minval:Float, maxval:Float):Float
	{
        return (number < minval ? minval : (number > maxval ? maxval : number));
    }

    /**
     * Calc a plane from a triangle edge an a normal.
     */
    public static function edge_plane(e1:Vector3f, e2:Vector3f, normal:Vector3f, plane:Vector4f):Void
	{
        var planenormal:Vector3f = new Vector3f();
        planenormal.subtractBy(e2, e1);
        planenormal.crossBy(planenormal, normal);
        planenormal.normalizeLocal();

		plane.setTo(planenormal.x, planenormal.y, planenormal.z, 0);
        plane.w = e2.dot(planenormal);
    }

    /**
     * Finds the closest point(cp) to (v) on a segment (e1,e2).
     */
    public static function closest_point_on_segment(cp:Vector3f, v:Vector3f, e1:Vector3f, e2:Vector3f):Void
	{
        var n:Vector3f = new Vector3f();
        n.subtractBy(e2, e1);
        cp.subtractBy(v, e1);
        var _scalar:Float = cp.dot(n) / n.dot(n);
        if (_scalar < 0.0)
		{
            cp = e1;
        } 
		else if (_scalar > 1.0) 
		{
            cp = e2;
        } 
		else 
		{
            cp.scaleAddBy(_scalar, n, e1);
        }
    }

    /**
     * Line plane collision.
     *
     * @return -0 if the ray never intersects, -1 if the ray collides in front, -2 if the ray collides in back
     */
    public static function line_plane_collision(plane:Vector4f, vDir:Vector3f, vPoint:Vector3f, pout:Vector3f, tparam:Array<Float>, tmin:Float, tmax:Float):Int
	{
        var _dotdir:Float = LinearMathUtil.dot3(vDir, plane);

        if (Math.abs(_dotdir) < PLANEDIREPSILON)
		{
            tparam[0] = tmax;
            return 0;
        }

        var _dis:Float = ClipPolygon.distance_point_plane(plane, vPoint);
        var returnvalue:Int = _dis < 0.0 ? 2 : 1;
        tparam[0] = -_dis / _dotdir;

        if (tparam[0] < tmin)
		{
            returnvalue = 0;
            tparam[0] = tmin;
        } 
		else if (tparam[0] > tmax) 
		{
            returnvalue = 0;
            tparam[0] = tmax;
        }
        pout.scaleAddBy(tparam[0], vDir, vPoint);
        return returnvalue;
    }

    /**
     * Find closest points on segments.
     */
    public static function segment_collision(vA1:Vector3f, vA2:Vector3f, vB1:Vector3f, vB2:Vector3f, vPointA:Vector3f, vPointB:Vector3f):Void
	{
        var AD:Vector3f = new Vector3f();
        AD.subtractBy(vA2, vA1);

        var BD:Vector3f = new Vector3f();
        BD.subtractBy(vB2, vB1);

        var N:Vector3f = new Vector3f();
        N.crossBy(AD, BD);
		
        var tp:Array<Float> = [];//new float[]{N.lengthSquared()};

        var _M:Vector4f = new Vector4f();//plane

        if (tp[0] < BulletGlobals.SIMD_EPSILON)//ARE PARALELE
        {
            // project B over A
            var invert_b_order:Bool = false;
            _M.x = vB1.dot(AD);
            _M.y = vB2.dot(AD);

            if (_M.x > _M.y) 
			{
                invert_b_order = true;
                //BT_SWAP_NUMBERS(_M[0],_M[1]);
                _M.x = _M.x + _M.y;
                _M.y = _M.x - _M.y;
                _M.x = _M.x - _M.y;
            }
            _M.z = vA1.dot(AD);
            _M.w = vA2.dot(AD);
            // mid points
            N.x = (_M.x + _M.y) * 0.5;
            N.y = (_M.z + _M.w) * 0.5;

            if (N.x < N.y)
			{
                if (_M.y < _M.z)
				{
                    vPointB = invert_b_order ? vB1 : vB2;
                    vPointA = vA1;
                } 
				else if (_M.y < _M.w)
				{
                    vPointB = invert_b_order ? vB1 : vB2;
                    closest_point_on_segment(vPointA, vPointB, vA1, vA2);
                } 
				else
				{
                    vPointA = vA2;
                    closest_point_on_segment(vPointB, vPointA, vB1, vB2);
                }
            } 
			else 
			{
                if (_M.w < _M.x)
				{
                    vPointB = invert_b_order ? vB2 : vB1;
                    vPointA = vA2;
                } 
				else if (_M.w < _M.y) 
				{
                    vPointA = vA2;
                    closest_point_on_segment(vPointB, vPointA, vB1, vB2);
                } 
				else
				{
                    vPointB = invert_b_order ? vB1 : vB2;
                    closest_point_on_segment(vPointA, vPointB, vA1, vA2);
                }
            }
            return;
        }

        N.crossBy(N, BD);
        _M.setTo(N.x, N.y, N.z, vB1.dot(N));

        // get point A as the plane collision point
        line_plane_collision(_M, AD, vA1, vPointA, tp, 0, 1);

		/*Closest point on segment*/
        vPointB.subtractBy(vPointA, vB1);
        tp[0] = vPointB.dot(BD);
        tp[0] /= BD.dot(BD);
        tp[0] = CLAMP(tp[0], 0.0, 1.0);

        vPointB.scaleAddBy(tp[0], BD, vB1);
    }
}