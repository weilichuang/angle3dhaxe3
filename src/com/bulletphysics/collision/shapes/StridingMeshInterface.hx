package com.bulletphysics.collision.shapes;
import com.bulletphysics.linearmath.VectorUtil;
import vecmath.Vector3f;

/**
 * StridingMeshInterface is the abstract class for high performance access to
 * triangle meshes. It allows for sharing graphics and collision meshes. Also
 * it provides locking/unlocking of graphics meshes that are in GPU memory.
 * @author weilichuang
 */
class StridingMeshInterface
{
	private var scaling:Vector3f = new Vector3f(1, 1, 1);

	public function new() 
	{
		
	}
	
	public function internalProcessAllTriangles(callback:InternalTriangleIndexCallback, aabbMin:Vector3f, aabbMax:Vector3f):Void
	{
		var graphicssubparts:Int = getNumSubParts();
        var triangle:Array<Vector3f> = [new Vector3f(), new Vector3f(), new Vector3f()];

        var meshScaling:Vector3f = getScaling(new Vector3f());

        for (part in 0...graphicssubparts)
		{
            var data:VertexData = getLockedReadOnlyVertexIndexBase(part);

			var cnt:Int = Std.int(data.getIndexCount() / 3);
            for (i in 0...cnt)
			{
                data.getTriangle(i * 3, meshScaling, triangle);
                callback.internalProcessTriangleIndex(triangle, part, i);
            }

            unLockReadOnlyVertexBase(part);
        }
	}
	
	public function calculateAabbBruteForce(aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
        // first calculate the total aabb for all triangles
        var aabbCallback:AabbCalculationCallback = new AabbCalculationCallback();
        aabbMin.setTo(-1e30, -1e30, -1e30);
        aabbMax.setTo(1e30, 1e30, 1e30);
        internalProcessAllTriangles(aabbCallback, aabbMin, aabbMax);

        aabbMin.fromVector3f(aabbCallback.aabbMin);
        aabbMax.fromVector3f(aabbCallback.aabbMax);
    }

    /**
     * Get read and write access to a subpart of a triangle mesh.
     * This subpart has a continuous array of vertices and indices.
     * In this way the mesh can be handled as chunks of memory with striding
     * very similar to OpenGL vertexarray support.
     * Make a call to unLockVertexBase when the read and write access is finished.
     */
    public function getLockedVertexIndexBase(subpart:Int/*=0*/):VertexData
	{
		return null;
	}

    public function getLockedReadOnlyVertexIndexBase(subpart:Int/*=0*/):VertexData
	{
		return null;
	}

    /**
     * unLockVertexBase finishes the access to a subpart of the triangle mesh.
     * Make a call to unLockVertexBase when the read and write access (using getLockedVertexIndexBase) is finished.
     */
    public function unLockVertexBase(subpart:Int):Void 
	{
		
	}

    public function unLockReadOnlyVertexBase(subpart:Int):Void 
	{
		
	}

    /**
     * getNumSubParts returns the number of seperate subparts.
     * Each subpart has a continuous array of vertices and indices.
     */
    public function getNumSubParts():Int
	{
		return 0;
	}

    public function preallocateVertices(numverts:Int):Void 
	{
		
	}

    public function preallocateIndices(numindices:Int):Void 
	{
		
	}

    public function getScaling(out:Vector3f ):Vector3f 
	{
        out.fromVector3f(scaling);
        return out;
    }

    public function setScaling(scaling:Vector3f ):Void 
	{
        this.scaling.fromVector3f(scaling);
    }
	
	
}

class AabbCalculationCallback extends InternalTriangleIndexCallback
{
	public var aabbMin:Vector3f = new Vector3f(1e30, 1e30, 1e30);
	public var aabbMax:Vector3f = new Vector3f( -1e30, -1e30, -1e30);
	
	public function new() 
	{
		super();
	}

	override public function internalProcessTriangleIndex(triangle:Array<Vector3f>, partId:Int, triangleIndex:Int):Void 
	{
		VectorUtil.setMin(aabbMin, triangle[0]);
		VectorUtil.setMax(aabbMax, triangle[0]);
		VectorUtil.setMin(aabbMin, triangle[1]);
		VectorUtil.setMax(aabbMax, triangle[1]);
		VectorUtil.setMin(aabbMin, triangle[2]);
		VectorUtil.setMax(aabbMax, triangle[2]);
	}
}