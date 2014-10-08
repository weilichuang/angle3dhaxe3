package org.angle3d.bullet.collision.shapes;

import com.bulletphysics.collision.shapes.BvhTriangleMeshShape;
import com.bulletphysics.collision.shapes.IndexedMesh;
import com.bulletphysics.collision.shapes.TriangleIndexVertexArray;
import org.angle3d.bullet.util.Converter;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.math.Vector3f;
/**
 * Basic mesh collision shape
 * @author weilichuang
 */
class MeshCollisionShape extends CollisionShape
{

	private var numVertices:Int; 
	private var numTriangles:Int;  
	private var vertexStride:Int;  
	private var triangleIndexStride:Int; 
    private var triangleIndexBase:Array<Int>;//ByteBuffer
	private var vertexBase:Array<Float>;//ByteBuffer
    private var bulletMesh:IndexedMesh;

    /** 
     * Creates a collision shape from the given TriMesh
     *
     * @param mesh
     *            the TriMesh to use
     */
    public function new(mesh:Mesh)
	{
		super();
        createCollisionMesh(mesh, new Vector3f(1, 1, 1));
    }
    
    private function createCollisionMesh(mesh:Mesh, worldScale:Vector3f):Void
	{
        this.scale = worldScale;
        //bulletMesh = Converter.convert(mesh);
        //this.numVertices = bulletMesh.numVertices;
        //this.numTriangles = bulletMesh.numTriangles;
        //this.vertexStride = bulletMesh.vertexStride;
        //this.triangleIndexStride = bulletMesh.triangleIndexStride;
        //this.triangleIndexBase = bulletMesh.triangleIndexBase;
        //this.vertexBase = bulletMesh.vertexBase;
        //createShape();
    }

    /**
     * creates a jme mesh from the collision shape, only needed for debugging
     */
    //public function createJmeMesh():Mesh 
	//{
        //return Converter.convert(bulletMesh);
    //}

    //private function createShape():Void
	//{
        //bulletMesh = new IndexedMesh();
        //bulletMesh.numVertices = numVertices;
        //bulletMesh.numTriangles = numTriangles;
        //bulletMesh.vertexStride = vertexStride;
        //bulletMesh.triangleIndexStride = triangleIndexStride;
        //bulletMesh.triangleIndexBase = triangleIndexBase;
        //bulletMesh.vertexBase = vertexBase;
        //bulletMesh.triangleIndexBase = triangleIndexBase;
        //var tiv:TriangleIndexVertexArray = new TriangleIndexVertexArray();
		//tiv.init(numTriangles, triangleIndexBase, triangleIndexStride, numVertices, vertexBase, vertexStride);
		//
        //cShape = new BvhTriangleMeshShape();
		//cast(cShape,BvhTriangleMeshShape).init(tiv, true);
        //cShape.setLocalScaling(Converter.a2vVector3f(getScale()));
        //cShape.setMargin(margin);
    //}
	
}