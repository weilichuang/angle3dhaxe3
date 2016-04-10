package org.angle3d.bullet.collision.shapes;
import com.bulletphysics.collision.shapes.IndexedMesh;
import com.bulletphysics.collision.shapes.TriangleIndexVertexArray;
import com.bulletphysics.collision.gimpact.GImpactMeshShape;
import flash.Vector;
import org.angle3d.bullet.util.Converter;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.mesh.Mesh;

/**
 * Basic mesh collision shape
 
 */
class GImpactCollisionShape extends CollisionShape
{
	private var worldScale:Vector3f;
	private var numVertices:Int;
	private var numTriangles:Int;
	private var vertexStride:Int;
	private var triangleIndexStride:Int;
	private var triangleIndexBase:Vector<Int>;
	private var vertexBase:Vector<Float>;
	private var bulletMesh:IndexedMesh;

	public function new(mesh:Mesh, worldScale:Vector3f = null)
	{
		super();
		if (worldScale != null)
			this.worldScale = worldScale;
		else 
			this.worldScale = new Vector3f(1, 1, 1);
			
		bulletMesh = Converter.convertMesh(mesh);
        this.numVertices = bulletMesh.numVertices;
        this.numTriangles = bulletMesh.numTriangles;
        this.vertexStride = bulletMesh.vertexStride;
        this.triangleIndexStride = bulletMesh.triangleIndexStride;
        this.triangleIndexBase = bulletMesh.triangleIndexBase;
        this.vertexBase = bulletMesh.vertexBase;
        createShape();
	}
	
	private function createShape():Void
	{
        bulletMesh = new IndexedMesh();
        bulletMesh.numVertices = numVertices;
        bulletMesh.numTriangles = numTriangles;
        bulletMesh.vertexStride = vertexStride;
        bulletMesh.triangleIndexStride = triangleIndexStride;
        bulletMesh.triangleIndexBase = triangleIndexBase;
        bulletMesh.vertexBase = vertexBase;
        bulletMesh.triangleIndexBase = triangleIndexBase;
		
        var tiv:TriangleIndexVertexArray = new TriangleIndexVertexArray(numTriangles, triangleIndexBase, triangleIndexStride, numVertices, vertexBase, vertexStride);
		
        cShape = new GImpactMeshShape(tiv);
		cast(cShape, GImpactMeshShape).updateBound();
		
        cShape.setLocalScaling(getScale());
        cShape.setMargin(margin);
    }
}