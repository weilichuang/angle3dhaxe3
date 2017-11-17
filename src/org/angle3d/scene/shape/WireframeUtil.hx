package org.angle3d.scene.shape;

import org.angle3d.math.Color;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;

class WireframeUtil {
	/**
	 * 生成Wireframe模型
	 */
	public static function generateWireframe(mesh:Mesh):WireframeShape {
		if (Std.is(mesh,WireframeShape)) {
			return Std.instance(mesh,WireframeShape);
		}

		if (mesh.getVertexBuffer(BufferType.POSITION) == null || mesh.getIndices() == null) {
			return null;
		}

		var shape:WireframeShape = new WireframeShape();

		var vertices:Array<Float> = mesh.getVertexBuffer(BufferType.POSITION).getData();
		var indices:Array<UInt> = mesh.getIndices();

		var p0x:Float, p0y:Float, p0z:Float;
		var p1x:Float, p1y:Float, p1z:Float;
		var p2x:Float, p2y:Float, p2z:Float;
		var count:Int = Std.int(indices.length / 3);
		for (j in 0...count) {
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
	public static function generateNormalLineShape(mesh:Mesh, size:Float = 5):WireframeShape {
		if (Std.is(mesh,WireframeShape)) {
			return null;
		}

		if (mesh.getVertexBuffer(BufferType.POSITION) == null ||
		mesh.getVertexBuffer(BufferType.NORMAL) == null) {
			return null;
		}

		var originColor:Color = Color.White();
		var normalColor:Color = Color.Blue();

		var shape:WireframeShape = new WireframeShape();

		var vertices:Array<Float> = mesh.getVertexBuffer(BufferType.POSITION).getData();
		var normals:Array<Float> = mesh.getVertexBuffer(BufferType.NORMAL).getData();

		var indices:Array<UInt> = mesh.getIndices();

		var p0x:Float, p0y:Float, p0z:Float;
		var p1x:Float, p1y:Float, p1z:Float;
		var p2x:Float, p2y:Float, p2z:Float;
		var count:Int = Std.int(indices.length / 3);
		for (j in 0...count) {
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

			shape.addSegment(new WireframeLineSet(p0x, p0y, p0z, p1x, p1y, p1z,originColor.r,originColor.g,originColor.b));
			shape.addSegment(new WireframeLineSet(p1x, p1y, p1z, p2x, p2y, p2z,originColor.r,originColor.g,originColor.b));
			shape.addSegment(new WireframeLineSet(p2x, p2y, p2z, p0x, p0y, p0z,originColor.r,originColor.g,originColor.b));
		}

		var nx:Float, ny:Float, nz:Float;
		count = Std.int(vertices.length / 3);
		for (j in 0...count) {
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

			shape.addSegment(new WireframeLineSet(p0x, p0y, p0z, p1x, p1y, p1z,normalColor.r,normalColor.g,normalColor.b));
		}
		shape.build();

		return shape;
	}

	/**
	 * 得到顶点切线，用于测试
	 */
	public static function generateTangentLineShape(mesh:Mesh, size:Float = 5):WireframeShape {
		if (Std.is(mesh,WireframeShape)) {
			return null;
		}

		if (mesh.getVertexBuffer(BufferType.POSITION) == null ||
		mesh.getVertexBuffer(BufferType.TANGENT) == null) {
			return null;
		}

		var originColor:Color = Color.White();
		var tangentColor:Color = Color.Red();
		var binormalColor:Color = Color.Green();
		var normalColor:Color = Color.Blue();

		var shape:WireframeShape = new WireframeShape();

		var vertices:Array<Float> = mesh.getVertexBuffer(BufferType.POSITION).getData();
		var tangents:Array<Float> = mesh.getVertexBuffer(BufferType.TANGENT).getData();
		var normals:Array<Float> = mesh.getVertexBuffer(BufferType.NORMAL).getData();

		var binomals:Array<Float> = null;
		if (mesh.getVertexBuffer(BufferType.BINORMAL) != null) {
			binomals = mesh.getVertexBuffer(BufferType.BINORMAL).getData();
		}

		var hasParity:Bool = mesh.getVertexBuffer(BufferType.TANGENT).components == 4;
		var tangentW:Float = 1;

		var indices:Array<UInt> = mesh.getIndices();

		var p0x:Float, p0y:Float, p0z:Float;
		var p1x:Float, p1y:Float, p1z:Float;
		var p2x:Float, p2y:Float, p2z:Float;
		var count:Int = Std.int(indices.length / 3);
		for (j in 0...count) {
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

			shape.addSegment(new WireframeLineSet(p0x, p0y, p0z, p1x, p1y, p1z,originColor.r,originColor.g,originColor.b));
			shape.addSegment(new WireframeLineSet(p1x, p1y, p1z, p2x, p2y, p2z,originColor.r,originColor.g,originColor.b));
			shape.addSegment(new WireframeLineSet(p2x, p2y, p2z, p0x, p0y, p0z,originColor.r,originColor.g,originColor.b));
		}

		var nx:Float, ny:Float, nz:Float;
		var tangent:Vector3f = new Vector3f();
		var binomal:Vector3f = new Vector3f();
		var normal:Vector3f = new Vector3f();
		count = Std.int(vertices.length / 3);
		for (j in 0...count) {
			var j3:Int = j * 3;
			var j4:Int = j * 4;

			p0x = vertices[j3];
			p0y = vertices[j3 + 1];
			p0z = vertices[j3 + 2];

			//normal
			normal.setTo(normals[j3], normals[j3 + 1], normals[j3 + 2]);

			p1x = p0x + normal.x * size;
			p1y = p0y + normal.y * size;
			p1z = p0z + normal.z * size;

			shape.addSegment(new WireframeLineSet(p0x, p0y, p0z, p1x, p1y, p1z, normalColor.r, normalColor.g, normalColor.b));

			tangent.setTo(tangents[j4], tangents[j4 + 1], tangents[j4 + 2]);
			if (hasParity) {
				tangentW = tangents[j4 + 3];
			}

			p1x = p0x + tangent.x * size;
			p1y = p0y + tangent.y * size;
			p1z = p0z + tangent.z * size;

			shape.addSegment(new WireframeLineSet(p0x, p0y, p0z, p1x, p1y, p1z, tangentColor.r, tangentColor.g, tangentColor.b));

			if (binomals != null) {
				binomal.setTo(binomals[j3], binomals[j3 + 1], binomals[j3 + 2]);
			} else {
				normal.cross(tangent, binomal);
				binomal.scaleLocal(-tangentW);
				binomal.normalizeLocal();
			}

			p1x = p0x + binomal.x * size;
			p1y = p0y + binomal.y * size;
			p1z = p0z + binomal.z * size;

			shape.addSegment(new WireframeLineSet(p0x, p0y, p0z, p1x, p1y, p1z, binormalColor.r, binormalColor.g, binormalColor.b));

		}
		shape.build();

		return shape;
	}
}

