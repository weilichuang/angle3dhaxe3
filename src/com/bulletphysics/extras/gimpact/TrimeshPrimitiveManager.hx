
package com.bulletphysics.extras.gimpact;

import com.bulletphysics.collision.shapes.StridingMeshInterface;
import com.bulletphysics.collision.shapes.VertexData;
import com.bulletphysics.extras.gimpact.BoxCollision.AABB;
import com.bulletphysics.extras.gimpact.PrimitiveTriangle;
import com.bulletphysics.linearmath.VectorUtil;

import vecmath.Vector3f;

/**
 * @author weilichuang
 */
class TrimeshPrimitiveManager extends PrimitiveManagerBase
{

    public var margin:Float;
    public var meshInterface:StridingMeshInterface;
    public var scale:Vector3f = new Vector3f();
    public var part:Int;
    public var lock_count:Int;

    private var tmpIndices:Array<Int> = [];

    private var vertexData:VertexData;

    public function new()
	{
        meshInterface = null;
        part = 0;
        margin = 0.01;
        scale.setTo(1, 1, 1);
        lock_count = 0;
    }

    public function copyFrom(manager:TrimeshPrimitiveManager)
	{
        meshInterface = manager.meshInterface;
        part = manager.part;
        margin = manager.margin;
        scale.fromVector3f(manager.scale);
        lock_count = 0;
    }

    public function init(meshInterface:StridingMeshInterface, part:Int):Void
	{
        this.meshInterface = meshInterface;
        this.part = part;
        this.meshInterface.getScaling(scale);
        margin = 0.1;
        lock_count = 0;
    }

    public function lock():Void
	{
        if (lock_count > 0) {
            lock_count++;
            return;
        }
        vertexData = meshInterface.getLockedReadOnlyVertexIndexBase(part);

        lock_count = 1;
    }

    public function unlock():Void
	{
        if (lock_count == 0) {
            return;
        }
        if (lock_count > 1) {
            --lock_count;
            return;
        }
        meshInterface.unLockReadOnlyVertexBase(part);
        vertexData = null;
        lock_count = 0;
    }
	
	override public function is_trimesh():Bool 
	{
		return true;
	}

    override public function get_primitive_count():Int 
	{
		return Std.int(vertexData.getIndexCount() / 3);
	}

    public function get_vertex_count():Int
	{
        return vertexData.getVertexCount();
    }

    public function get_indices(face_index:Int, out:Array<Int>):Void
	{
        out[0] = vertexData.getIndex(face_index * 3 + 0);
        out[1] = vertexData.getIndex(face_index * 3 + 1);
        out[2] = vertexData.getIndex(face_index * 3 + 2);
    }

    public function get_vertex(vertex_index:Int, vertex:Vector3f):Void
	{
        vertexData.getVertex(vertex_index, vertex);
        VectorUtil.mul(vertex, vertex, scale);
    }
	
	override public function get_primitive_box(prim_index:Int, primbox:AABB):Void 
	{
		var triangle:PrimitiveTriangle = new PrimitiveTriangle();
        get_primitive_triangle(prim_index, triangle);
        primbox.calc_from_triangle_margin(
                triangle.vertices[0],
                triangle.vertices[1], triangle.vertices[2], triangle.margin);
	}

    override public function get_primitive_triangle(prim_index:Int, triangle:PrimitiveTriangle):Void 
	{
		get_indices(prim_index, tmpIndices);
        get_vertex(tmpIndices[0], triangle.vertices[0]);
        get_vertex(tmpIndices[1], triangle.vertices[1]);
        get_vertex(tmpIndices[2], triangle.vertices[2]);
        triangle.margin = margin;
	}

    public function get_bullet_triangle(prim_index:Int, triangle:TriangleShapeEx):Void
	{
        get_indices(prim_index, tmpIndices);
        get_vertex(tmpIndices[0], triangle.vertices1[0]);
        get_vertex(tmpIndices[1], triangle.vertices1[1]);
        get_vertex(tmpIndices[2], triangle.vertices1[2]);
        triangle.setMargin(margin);
    }

}
