package org.angle3d.bullet.util;
import com.bulletphysics.collision.shapes.IndexedMesh;

import org.angle3d.math.Transform;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;

class Converter {
	public static inline function convertTransformFromAngle3D(inT:org.angle3d.math.Transform, out:com.bulletphysics.linearmath.Transform):com.bulletphysics.linearmath.Transform {
		out.origin.copyFrom(inT.translation);
		out.basis.fromQuaternion(inT.rotation);
		return out;
	}

	public static inline function convertTransformFromBullet(inT:com.bulletphysics.linearmath.Transform, out:org.angle3d.math.Transform):org.angle3d.math.Transform {
		out.translation.copyFrom(inT.origin);
		out.rotation.fromMatrix3f(inT.basis);
		return out;
	}

	public static function convertMesh(mesh:Mesh):IndexedMesh {
		var triangleCount:Int = mesh.getTriangleCount();
		var vertexCount:Int = mesh.getVertexCount();

		var jBulletIndexedMesh:IndexedMesh = new IndexedMesh();
		jBulletIndexedMesh.triangleIndexBase = new Array<Int>(triangleCount * 3,true);
		jBulletIndexedMesh.vertexBase = new Array<Float>(vertexCount * 3,true);

		var indices = mesh.getIndices();
		var vertices = mesh.getVertexBuffer(BufferType.POSITION).getData();

		var verticesLength:Int = vertexCount * 3;
		jBulletIndexedMesh.numVertices = vertexCount;
		jBulletIndexedMesh.vertexStride = 3; //3 verts * 4 bytes per.
		for (i in 0...verticesLength) {
			var tempFloat:Float = vertices[i];
			jBulletIndexedMesh.vertexBase[i] = tempFloat;
		}

		var indicesLength:Int = triangleCount * 3;
		jBulletIndexedMesh.numTriangles = triangleCount;
		jBulletIndexedMesh.triangleIndexStride = 3; //3 index entries * 4 bytes each.
		for (i in 0...indicesLength) {
			jBulletIndexedMesh.triangleIndexBase[i] = indices[i];
		}

		return jBulletIndexedMesh;
	}

}