package com.bulletphysics.collision.narrowphase;
import com.bulletphysics.collision.shapes.TriangleCallback;
import com.bulletphysics.linearmath.LinearMathUtil;
import com.vecmath.Vector3f;

/**
 * ...
 * @author weilichuang
 */
class TriangleRaycastCallback implements TriangleCallback
{
	public var from:Vector3f = new Vector3f();
    public var to:Vector3f = new Vector3f();

    public var hitFraction:Float;

    public function new(from:Vector3f, to:Vector3f)
	{
        this.from.fromVector3f(from);
        this.to.fromVector3f(to);
        this.hitFraction = 1;
    }

    public function processTriangle(triangle:Array<Vector3f>, partId:Int, triangleIndex:Int):Void
	{
        var vert0:Vector3f = triangle[0];
        var vert1:Vector3f = triangle[1];
        var vert2:Vector3f = triangle[2];

        var v10:Vector3f = new Vector3f();
        v10.sub2(vert1, vert0);

        var v20:Vector3f = new Vector3f();
        v20.sub2(vert2, vert0);

        var triangleNormal:Vector3f = new Vector3f();
        triangleNormal.cross(v10, v20);

        var dist:Float = vert0.dot(triangleNormal);
        var dist_a:Float = triangleNormal.dot(from);
        dist_a -= dist;
        var dist_b:Float = triangleNormal.dot(to);
        dist_b -= dist;

        if (dist_a * dist_b >= 0) 
		{
            return; // same sign
        }

        var proj_length:Float = dist_a - dist_b;
        var distance:Float = (dist_a) / (proj_length);
        // Now we have the intersection point on the plane, we'll see if it's inside the triangle
        // Add an epsilon as a tolerance for the raycast,
        // in case the ray hits exacly on the edge of the triangle.
        // It must be scaled for the triangle size.

        if (distance < hitFraction) 
		{
            var edge_tolerance:Float = triangleNormal.lengthSquared();
            edge_tolerance *= -0.0001;
            var point:Vector3f = new Vector3f();
            LinearMathUtil.setInterpolate3(point, from, to, distance);
            {
                var v0p:Vector3f = new Vector3f();
                v0p.sub2(vert0, point);
                var v1p:Vector3f = new Vector3f();
                v1p.sub2(vert1, point);
                var cp0:Vector3f = new Vector3f();
                cp0.cross(v0p, v1p);

                if (cp0.dot(triangleNormal) >= edge_tolerance)
				{
                    var v2p:Vector3f = new Vector3f();
                    v2p.sub2(vert2, point);
                    var cp1:Vector3f = new Vector3f();
                    cp1.cross(v1p, v2p);
                    if (cp1.dot(triangleNormal) >= edge_tolerance)
					{
                        var cp2:Vector3f = new Vector3f();
                        cp2.cross(v2p, v0p);

                        if (cp2.dot(triangleNormal) >= edge_tolerance)
						{

                            if (dist_a > 0) 
							{
                                hitFraction = reportHit(triangleNormal, distance, partId, triangleIndex);
                            } 
							else 
							{
                                var tmp:Vector3f = new Vector3f();
                                tmp.negateBy(triangleNormal);
                                hitFraction = reportHit(tmp, distance, partId, triangleIndex);
                            }
                        }
                    }
                }
            }
        }
    }

    public function reportHit(hitNormalLocal:Vector3f, hitFraction:Float, partId:Int, triangleIndex:Int):Float
	{
		return 0;
	}

}