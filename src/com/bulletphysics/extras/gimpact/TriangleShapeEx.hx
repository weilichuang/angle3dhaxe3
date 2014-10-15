
package com.bulletphysics.extras.gimpact;

import com.bulletphysics.collision.shapes.TriangleShape;
import com.bulletphysics.extras.gimpact.BoxCollision.AABB;
import com.bulletphysics.linearmath.Transform;

import vecmath.Vector3f;
import vecmath.Vector4f;

/**
 * @author weilichuang
 */
class TriangleShapeEx extends TriangleShape
{
    public function new(p0:Vector3f, p1:Vector3f, p2:Vector3f) 
	{
        super(p0, p1, p2);
    }
	
	override public function getAabb(trans:Transform, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		var tv0:Vector3f = vertices1[0].clone();
        trans.transform(tv0);
        var tv1:Vector3f = vertices1[1].clone();
        trans.transform(tv1);
        var tv2:Vector3f = vertices1[2].clone();
        trans.transform(tv2);

        var trianglebox:AABB = new AABB();
        trianglebox.init(tv0, tv1, tv2, collisionMargin);

        aabbMin.fromVector3f(trianglebox.min);
        aabbMax.fromVector3f(trianglebox.max);
	}

    public function applyTransform(t:Transform):Void
	{
        t.transform(vertices1[0]);
        t.transform(vertices1[1]);
        t.transform(vertices1[2]);
    }

    public function buildTriPlane(plane:Vector4f):Void
	{
        var tmp1:Vector3f = new Vector3f();
        var tmp2:Vector3f = new Vector3f();

        var normal:Vector3f = new Vector3f();
        tmp1.sub(vertices1[1], vertices1[0]);
        tmp2.sub(vertices1[2], vertices1[0]);
        normal.cross(tmp1, tmp2);
        normal.normalize();

        plane.setTo(normal.x, normal.y, normal.z, vertices1[0].dot(normal));
    }

    public function overlap_test_conservative(other:TriangleShapeEx):Bool
	{
        var total_margin:Float = getMargin() + other.getMargin();

        var plane0:Vector4f = new Vector4f();
        buildTriPlane(plane0);
        var plane1:Vector4f = new Vector4f();
        other.buildTriPlane(plane1);

        // classify points on other triangle
        var dis0:Float = ClipPolygon.distance_point_plane(plane0, other.vertices1[0]) - total_margin;

        var dis1:Float = ClipPolygon.distance_point_plane(plane0, other.vertices1[1]) - total_margin;

        var dis2:Float = ClipPolygon.distance_point_plane(plane0, other.vertices1[2]) - total_margin;

        if (dis0 > 0.0 && dis1 > 0.0 && dis2 > 0.0) 
		{
            return false; // classify points on this triangle
        }
		
        dis0 = ClipPolygon.distance_point_plane(plane1, vertices1[0]) - total_margin;

        dis1 = ClipPolygon.distance_point_plane(plane1, vertices1[1]) - total_margin;

        dis2 = ClipPolygon.distance_point_plane(plane1, vertices1[2]) - total_margin;

        if (dis0 > 0.0 && dis1 > 0.0 && dis2 > 0.0)
		{
            return false;
        }
        return true;
    }

}
