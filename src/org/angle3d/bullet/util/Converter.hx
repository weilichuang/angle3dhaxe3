package org.angle3d.bullet.util;
import com.bulletphysics.collision.shapes.IndexedMesh;
import haxe.ds.Vector;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;

/**
 * ...
 * @author weilichuang
 */
class Converter
{

	public function new() 
	{
		
	}
	
	public static function a2vVector3f(oldVec:org.angle3d.math.Vector3f,result:com.vecmath.Vector3f = null):com.vecmath.Vector3f
	{
		if(result == null)
			result = new com.vecmath.Vector3f();
		result.x = oldVec.x;
		result.y = oldVec.y;
		result.z = oldVec.z;
        return result;
    }
	
	public static function v2aVector3f(oldVec:com.vecmath.Vector3f,result:org.angle3d.math.Vector3f = null):org.angle3d.math.Vector3f
	{
		if(result == null)
			result = new org.angle3d.math.Vector3f();
		result.x = oldVec.x;
		result.y = oldVec.y;
		result.z = oldVec.z;
        return result;
    }
	
	public static function a2vMatrix3f(oldMatrix:org.angle3d.math.Matrix3f, newMatrix:com.vecmath.Matrix3f = null):com.vecmath.Matrix3f 
	{
		if (newMatrix == null)
			newMatrix = new com.vecmath.Matrix3f();
        newMatrix.m00 = oldMatrix.m00;
        newMatrix.m01 = oldMatrix.m01;
        newMatrix.m02 = oldMatrix.m02;
        newMatrix.m10 = oldMatrix.m10;
        newMatrix.m11 = oldMatrix.m11;
        newMatrix.m12 = oldMatrix.m12;
        newMatrix.m20 = oldMatrix.m20;
        newMatrix.m21 = oldMatrix.m21;
        newMatrix.m22 = oldMatrix.m22;
        return newMatrix;
    }
	
	public static function a2vMesh(mesh:Mesh):IndexedMesh
	{
        var jBulletIndexedMesh:IndexedMesh = new IndexedMesh();
        jBulletIndexedMesh.triangleIndexBase = new Vector(mesh.getTriangleCount() * 3 * 4);
        jBulletIndexedMesh.vertexBase = new Vector(mesh.getVertexCount() * 3 * 4);

        var indices = mesh.getIndices();
        var vertices = mesh.getVertexBuffer(BufferType.POSITION).getData();

        var verticesLength:Int = mesh.getVertexCount() * 3;
        jBulletIndexedMesh.numVertices = mesh.getVertexCount();
        jBulletIndexedMesh.vertexStride = 12; //3 verts * 4 bytes per.
        for (i in 0...verticesLength) 
		{
            var tempFloat:Float = vertices[i];
            jBulletIndexedMesh.vertexBase[i] = tempFloat;
        }

        var indicesLength:Int = mesh.getTriangleCount() * 3;
        jBulletIndexedMesh.numTriangles = mesh.getTriangleCount();
        jBulletIndexedMesh.triangleIndexStride = 12; //3 index entries * 4 bytes each.
        for (i in 0...indicesLength)
		{
            jBulletIndexedMesh.triangleIndexBase[i] = indices[i];
        }

        return jBulletIndexedMesh;
    }
	
}