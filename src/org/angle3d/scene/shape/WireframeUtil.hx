package org.angle3d.scene.shape;

import flash.Vector;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;

class WireframeUtil
{
	/**
	 * 生成Wireframe模型
	 */
	public static function generateWireframe(mesh:Mesh):WireframeShape
	{
		if (Std.is(mesh,WireframeShape))
		{
			return Std.instance(mesh,WireframeShape);
		}

		if (mesh.getVertexBuffer(BufferType.POSITION) == null || mesh.getIndices() == null)
		{
			return null;
		}
		
		var shape:WireframeShape = new WireframeShape();

		var vertices:Vector<Float> = mesh.getVertexBuffer(BufferType.POSITION).getData();
		var indices:Vector<UInt> = mesh.getIndices();

		var p0x:Float, p0y:Float, p0z:Float;
		var p1x:Float, p1y:Float, p1z:Float;
		var p2x:Float, p2y:Float, p2z:Float;
		var count:Int = Std.int(indices.length / 3);
		for (j in 0...count)
		{
			var j3:Int = j * 3;
			var j0:Int = indices[j3] * 3;
			p0x = vertices[j0];
			p0y = vertices[j0 + 1];
			p0z = vertices[j0 + 2];

			var j1:Int = indices[j3 + 1] * 3;
			p1x = vertices[j1];
			p1y = vertices[j1 + 1];
			p1z = vertices[j1 + 2];

			var j2:Int = indices[j3 + 2] * 3;
			p2x = vertices[j2];
			p2y = vertices[j2 + 1];
			p2z = vertices[j2 + 2];

			shape.addSegment(new WireframeLineSet(p0x, p0y, p0z, p1x, p1y, p1z));
			shape.addSegment(new WireframeLineSet(p1x, p1y, p1z, p2x, p2y, p2z));
			shape.addSegment(new WireframeLineSet(p2x, p2y, p2z, p0x, p0y, p0z));
		}
		shape.build();
		return shape;
	}

	/**
	 * 得到顶点法线，用于测试
	 */
	public static function generateNormalLineShape(mesh:Mesh, size:Float = 5):WireframeShape
	{
		if (Std.is(mesh,WireframeShape))
		{
			return null;
		}

		if (mesh.getVertexBuffer(BufferType.POSITION) == null || 
			mesh.getVertexBuffer(BufferType.NORMAL) == null)
		{
			return null;
		}
		
		var shape:WireframeShape = new WireframeShape();

		var vertices:Vector<Float> = mesh.getVertexBuffer(BufferType.POSITION).getData();
		var normals:Vector<Float> = mesh.getVertexBuffer(BufferType.NORMAL).getData();

		var p0x:Float, p0y:Float, p0z:Float;
		var p1x:Float, p1y:Float, p1z:Float;
		var nx:Float, ny:Float, nz:Float;
		var count:Int = Std.int(vertices.length / 3);
		for (j in 0...count)
		{
			var j3:Int = j * 3;
			p0x = vertices[j3];
			p0y = vertices[j3 + 1];
			p0z = vertices[j3 + 2];

			nx = normals[j3];
			ny = normals[j3 + 1];
			nz = normals[j3 + 2];

			p1x = p0x + nx * size;
			p1y = p0y + ny * size;
			p1z = p0z + nz * size;

			shape.addSegment(new WireframeLineSet(p0x, p0y, p0z, p1x, p1y, p1z));
		}
		shape.build();

		return shape;
	}
}

