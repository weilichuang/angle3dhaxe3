package org.angle3d.bullet.util;
import com.bulletphysics.collision.shapes.IndexedMesh;
import haxe.ds.Vector;
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
	
	public static function a2vVector3f(oldVec:org.angle3d.math.Vector3f):com.vecmath.Vector3f
	{
        var newVec:com.vecmath.Vector3f = new com.vecmath.Vector3f();
		newVec.x = oldVec.x;
		newVec.y = oldVec.y;
		newVec.z = oldVec.z;
        return newVec;
    }
	
	//public static function a2vMesh(mesh:Mesh):IndexedMesh
	//{
        //var jBulletIndexedMesh:IndexedMesh = new IndexedMesh();
        //jBulletIndexedMesh.triangleIndexBase = new Vector(mesh.getTriangleCount() * 3 * 4);
        //jBulletIndexedMesh.vertexBase = new Vector(mesh.getVertexCount() * 3 * 4);
//
        //IndexBuffer indices = mesh.getIndicesAsList();
        //
        //FloatBuffer vertices = mesh.getFloatBuffer(Type.Position);
        //vertices.rewind();
//
        //int verticesLength = mesh.getVertexCount() * 3;
        //jBulletIndexedMesh.numVertices = mesh.getVertexCount();
        //jBulletIndexedMesh.vertexStride = 12; //3 verts * 4 bytes per.
        //for (int i = 0; i < verticesLength; i++) {
            //float tempFloat = vertices.get();
            //jBulletIndexedMesh.vertexBase.putFloat(tempFloat);
        //}
//
        //int indicesLength = mesh.getTriangleCount() * 3;
        //jBulletIndexedMesh.numTriangles = mesh.getTriangleCount();
        //jBulletIndexedMesh.triangleIndexStride = 12; //3 index entries * 4 bytes each.
        //for (int i = 0; i < indicesLength; i++) {
            //jBulletIndexedMesh.triangleIndexBase.putInt(indices.get(i));
        //}
        //vertices.rewind();
        //vertices.clear();
//
        //return jBulletIndexedMesh;
    //}
	
}