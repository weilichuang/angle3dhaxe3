
package com.bulletphysics.collision.gimpact ;

import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.util.ObjectArrayList;

import com.vecmath.Vector3f;
import org.angle3d.math.Vector4f;

/**
 * @author weilichuang
 */
class PrimitiveTriangle 
{

    private var tmpVecList1:ObjectArrayList<Vector3f> = new ObjectArrayList<Vector3f>(TriangleContact.MAX_TRI_CLIPPING);
    private var tmpVecList2:ObjectArrayList<Vector3f> = new ObjectArrayList<Vector3f>(TriangleContact.MAX_TRI_CLIPPING);
    private var tmpVecList3:ObjectArrayList<Vector3f> = new ObjectArrayList<Vector3f>(TriangleContact.MAX_TRI_CLIPPING);

    public var vertices:Array<Vector3f> = [];
    public var plane:Vector4f = new Vector4f();
    public var margin:Float = 0.01;

    public function new() 
	{
		for (i in 0...TriangleContact.MAX_TRI_CLIPPING)
		{
            tmpVecList1.add(new Vector3f());
            tmpVecList2.add(new Vector3f());
            tmpVecList3.add(new Vector3f());
        }
		
        for (i in 0...3)
		{
            vertices[i] = new Vector3f();
        }
    }

    public function set(tri:PrimitiveTriangle):Void
	{
        //throw new UnsupportedOperationException();
    }

    public function buildTriPlane():Void
	{
        var tmp1:Vector3f = new Vector3f();
        var tmp2:Vector3f = new Vector3f();

        var normal:Vector3f = new Vector3f();
        tmp1.sub2(vertices[1], vertices[0]);
        tmp2.sub2(vertices[2], vertices[0]);
        normal.cross(tmp1, tmp2);
        normal.normalize();

        plane.setTo(normal.x, normal.y, normal.z, vertices[0].dot(normal));
    }

    /**
     * Test if triangles could collide.
     */
    public function overlap_test_conservative(other:PrimitiveTriangle):Bool
	{
        var total_margin:Float = margin + other.margin;
        // classify points on other triangle
        var dis0:Float = ClipPolygon.distance_point_plane(plane, other.vertices[0]) - total_margin;

        var dis1:Float = ClipPolygon.distance_point_plane(plane, other.vertices[1]) - total_margin;

        var dis2:Float = ClipPolygon.distance_point_plane(plane, other.vertices[2]) - total_margin;

        if (dis0 > 0.0 && dis1 > 0.0 && dis2 > 0.0)
		{
            return false; // classify points on this triangle
        }

        dis0 = ClipPolygon.distance_point_plane(other.plane, vertices[0]) - total_margin;

        dis1 = ClipPolygon.distance_point_plane(other.plane, vertices[1]) - total_margin;

        dis2 = ClipPolygon.distance_point_plane(other.plane, vertices[2]) - total_margin;

        if (dis0 > 0.0 && dis1 > 0.0 && dis2 > 0.0)
		{
            return false;
        }
        return true;
    }

    /**
     * Calcs the plane which is paralele to the edge and perpendicular to the triangle plane.
     * This triangle must have its plane calculated.
     */
    public function get_edge_plane(edge_index:Int,  plane:Vector4f):Void
	{
        var e0:Vector3f = vertices[edge_index];
        var e1:Vector3f = vertices[(edge_index + 1) % 3];

        var tmp:Vector3f = new Vector3f();
        tmp.setTo(this.plane.x, this.plane.y, this.plane.z);

        GeometryOperations.edge_plane(e0, e1, tmp, plane);
    }

    public function applyTransform(t:Transform):Void
	{
        t.transform(vertices[0]);
        t.transform(vertices[1]);
        t.transform(vertices[2]);
    }

    /**
     * Clips the triangle against this.
     *
     * @param clipped_points must have MAX_TRI_CLIPPING size, and this triangle must have its plane calculated.
     * @return the number of clipped points
     */
    public function clip_triangle(other:PrimitiveTriangle, clipped_points:ObjectArrayList<Vector3f>):Int
	{
        // edge 0
        var temp_points:ObjectArrayList<Vector3f> = tmpVecList1;

        var edgeplane:Vector4f = new Vector4f();

        get_edge_plane(0, edgeplane);

        var clipped_count:Int = ClipPolygon.plane_clip_triangle(edgeplane, other.vertices[0], other.vertices[1], other.vertices[2], temp_points);

        if (clipped_count == 0) 
		{
            return 0;
        }
        var temp_points1:ObjectArrayList<Vector3f> = tmpVecList2;

        // edge 1
        get_edge_plane(1, edgeplane);

        clipped_count = ClipPolygon.plane_clip_polygon(edgeplane, temp_points, clipped_count, temp_points1);

        if (clipped_count == 0)
		{
            return 0; // edge 2
        }
        get_edge_plane(2, edgeplane);

        clipped_count = ClipPolygon.plane_clip_polygon(edgeplane, temp_points1, clipped_count, clipped_points);

        return clipped_count;
    }

    /**
     * Find collision using the clipping method.
     * This triangle and other must have their triangles calculated.
     */
    public function find_triangle_collision_clip_method(other:PrimitiveTriangle, contacts:TriangleContact):Bool
	{
        var margin:Float = this.margin + other.margin;

        var clipped_points:ObjectArrayList<Vector3f> = tmpVecList3;

        var clipped_count:Int;
        //create planes
        // plane v vs U points

        var contacts1:TriangleContact = new TriangleContact();

        contacts1.separating_normal.copyFrom(plane);

        clipped_count = clip_triangle(other, clipped_points);

        if (clipped_count == 0)
		{
            return false; // Reject
        }

        // find most deep interval face1
        contacts1.merge_points(contacts1.separating_normal, margin, clipped_points, clipped_count);
        if (contacts1.point_count == 0)
		{
            return false; // too far
            // Normal pointing to this triangle
        }
        contacts1.separating_normal.x *= -1.;
        contacts1.separating_normal.y *= -1.;
        contacts1.separating_normal.z *= -1.;

        // Clip tri1 by tri2 edges
        var contacts2:TriangleContact = new TriangleContact();
        contacts2.separating_normal.copyFrom(other.plane);

        clipped_count = other.clip_triangle(this, clipped_points);

        if (clipped_count == 0)
		{
            return false; // Reject
        }

        // find most deep interval face1
        contacts2.merge_points(contacts2.separating_normal, margin, clipped_points, clipped_count);
        if (contacts2.point_count == 0)
		{
            return false; // too far

            // check most dir for contacts
        }
        if (contacts2.penetration_depth < contacts1.penetration_depth) 
		{
            contacts.copyFrom(contacts2);
        } 
		else
		{
            contacts.copyFrom(contacts1);
        }
        return true;
    }

}
