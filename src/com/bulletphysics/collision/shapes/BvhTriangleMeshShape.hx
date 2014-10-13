package com.bulletphysics.collision.shapes;
import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.bulletphysics.collision.shapes.TriangleCallback;
import com.bulletphysics.linearmath.VectorUtil;
import com.bulletphysics.util.Assert;
import com.bulletphysics.util.ObjectPool;
import vecmath.Vector3f;

/**
 * BvhTriangleMeshShape is a static-triangle mesh shape with several optimizations,
 * such as bounding volume hierarchy. It is recommended to enable useQuantizedAabbCompression
 * for better memory usage.<p>
 * <p/>
 * It takes a triangle mesh as input, for example a {@link TriangleMesh} or
 * {@link TriangleIndexVertexArray}. The BvhTriangleMeshShape class allows for
 * triangle mesh deformations by a refit or partialRefit method.<p>
 * <p/>
 * Instead of building the bounding volume hierarchy acceleration structure, it is
 * also possible to serialize (save) and deserialize (load) the structure from disk.
 * See ConcaveDemo for an example.
 * 
 * @author weilichuang
 */
class BvhTriangleMeshShape extends TriangleMeshShape
{

	private var bvh:OptimizedBvh;
    private var useQuantizedAabbCompression:Bool;
    private var ownsBvh:Bool;

    private var myNodeCallbacks:ObjectPool<MyNodeOverlapCallback> = ObjectPool.getPool(MyNodeOverlapCallback);
	
	public function new()
	{
		super(null);
		this.bvh = null;
        this.ownsBvh = false;
	}

    public function init(meshInterface:StridingMeshInterface, useQuantizedAabbCompression:Bool, buildBvh:Bool = true):Void
	{
        this.meshInterface = meshInterface;
        this.bvh = null;
        this.useQuantizedAabbCompression = useQuantizedAabbCompression;
        this.ownsBvh = false;
		
		// construct bvh from meshInterface
        //#ifndef DISABLE_BVH

        var bvhAabbMin:Vector3f = new Vector3f();
		var bvhAabbMax:Vector3f = new Vector3f();
        meshInterface.calculateAabbBruteForce(bvhAabbMin, bvhAabbMax);

        if (buildBvh) 
		{
            bvh = new OptimizedBvh();
            bvh.build(meshInterface, useQuantizedAabbCompression, bvhAabbMin, bvhAabbMax);
            ownsBvh = true;

            // JAVA NOTE: moved from TriangleMeshShape
            recalcLocalAabb();
        }

        //#endif //DISABLE_BVH
    }

	
	public function init2(meshInterface:StridingMeshInterface, useQuantizedAabbCompression:Bool, 
						bvhAabbMin:Vector3f, bvhAabbMax:Vector3f, buildBvh:Bool = true)
	{
		this.meshInterface = meshInterface;
		
		this.bvh = null;
        this.useQuantizedAabbCompression = useQuantizedAabbCompression;
        this.ownsBvh = false;

        // construct bvh from meshInterface
        //#ifndef DISABLE_BVH

        if (buildBvh)
		{
            bvh = new OptimizedBvh();

            bvh.build(meshInterface, useQuantizedAabbCompression, bvhAabbMin, bvhAabbMax);
            ownsBvh = true;
        }

        // JAVA NOTE: moved from TriangleMeshShape
        recalcLocalAabb();
        //#endif //DISABLE_BVH
	}
   
    public function getOwnsBvh():Bool
	{
        return ownsBvh;
    }
	
	override public function getShapeType():BroadphaseNativeType 
	{
		return BroadphaseNativeType.TRIANGLE_MESH_SHAPE_PROXYTYPE;
	}

    public function performRaycast(callback:TriangleCallback, raySource:Vector3f, rayTarget:Vector3f):Void
	{
        var myNodeCallback:MyNodeOverlapCallback = myNodeCallbacks.get();
        myNodeCallback.init(callback, meshInterface);

        bvh.reportRayOverlappingNodex(myNodeCallback, raySource, rayTarget);

        myNodeCallbacks.release(myNodeCallback);
    }

    public function performConvexcast(callback:TriangleCallback, raySource:Vector3f, rayTarget:Vector3f, aabbMin:Vector3f, aabbMax:Vector3f):Void
	{
        var myNodeCallback:MyNodeOverlapCallback = myNodeCallbacks.get();
        myNodeCallback.init(callback, meshInterface);

        bvh.reportBoxCastOverlappingNodex(myNodeCallback, raySource, rayTarget, aabbMin, aabbMax);

        myNodeCallbacks.release(myNodeCallback);
    }
	
	/**
     * Perform bvh tree traversal and report overlapping triangles to 'callback'.
     */
	override public function processAllTriangles(callback:TriangleCallback, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		//#ifdef DISABLE_BVH
        // // brute force traverse all triangles
        //btTriangleMeshShape::processAllTriangles(callback,aabbMin,aabbMax);
        //#else

        // first get all the nodes
        var myNodeCallback:MyNodeOverlapCallback = myNodeCallbacks.get();
        myNodeCallback.init(callback, meshInterface);

        bvh.reportAabbOverlappingNodex(myNodeCallback, aabbMin, aabbMax);

        myNodeCallbacks.release(myNodeCallback);
        //#endif//DISABLE_BVH
	}


    public function refitTree(aabbMin:Vector3f, aabbMax:Vector3f):Void
	{
        // JAVA NOTE: update it for 2.70b1
        //bvh.refit(meshInterface, aabbMin, aabbMax);
        bvh.refit(meshInterface);

        recalcLocalAabb();
    }

    /**
     * For a fast incremental refit of parts of the tree. Note: the entire AABB of the tree will become more conservative, it never shrinks.
     */
    public function partialRefitTree(aabbMin:Vector3f, aabbMax:Vector3f):Void
	{
        bvh.refitPartial(meshInterface, aabbMin, aabbMax);

        VectorUtil.setMin(localAabbMin, aabbMin);
        VectorUtil.setMax(localAabbMax, aabbMax);
    }
	
	override public function getName():String 
	{
		return "BVHTRIANGLEMESH";
	}
	
	override public function setLocalScaling(scaling:Vector3f):Void 
	{
		var tmp:Vector3f = new Vector3f();
        tmp.sub(getLocalScaling(new Vector3f()), scaling);

        if (tmp.lengthSquared() > BulletGlobals.SIMD_EPSILON)
		{
            super.setLocalScaling(scaling);
            /*
            if (ownsBvh)
			{
			m_bvh->~btOptimizedBvh();
			btAlignedFree(m_bvh);
			}
			*/
            ///m_localAabbMin/m_localAabbMax is already re-calculated in btTriangleMeshShape. We could just scale aabb, but this needs some more work
            bvh = new OptimizedBvh();
            // rebuild the bvh...
            bvh.build(meshInterface, useQuantizedAabbCompression, localAabbMin, localAabbMax);
            ownsBvh = true;
        }
	}

    public function getOptimizedBvh():OptimizedBvh
	{
        return bvh;
    }

    public function setOptimizedBvh(bvh:OptimizedBvh, scaling:Vector3f = null):Void
	{
		if (scaling == null)
			scaling = new Vector3f(1, 1, 1);
			
        Assert.assert (this.bvh == null);
        Assert.assert (!ownsBvh);

        this.bvh = bvh;
        ownsBvh = false;

        // update the scaling without rebuilding the bvh
        var tmp:Vector3f = new Vector3f();
        tmp.sub(getLocalScaling(new Vector3f()), scaling);

        if (tmp.lengthSquared() > BulletGlobals.SIMD_EPSILON)
		{
            super.setLocalScaling(scaling);
        }
    }

    public function usesQuantizedAabbCompression():Bool
	{
        return useQuantizedAabbCompression;
    }
}

class MyNodeOverlapCallback extends NodeOverlapCallback 
{
	public var meshInterface:StridingMeshInterface;
	public var callback:TriangleCallback;

	private var triangle:Array<Vector3f> = [new Vector3f(), new Vector3f(), new Vector3f()];

	public function new()
	{
		super();
	}

	public function init(callback:TriangleCallback, meshInterface:StridingMeshInterface):Void
	{
		this.meshInterface = meshInterface;
		this.callback = callback;
	}

	override public function processNode(nodeSubPart:Int, nodeTriangleIndex:Int):Void
	{
		var data:VertexData = meshInterface.getLockedReadOnlyVertexIndexBase(nodeSubPart);

		var meshScaling:Vector3f = meshInterface.getScaling(new Vector3f());

		data.getTriangle(nodeTriangleIndex * 3, meshScaling, triangle);

		/* Perform ray vs. triangle collision here */
		callback.processTriangle(triangle, nodeSubPart, nodeTriangleIndex);

		meshInterface.unLockReadOnlyVertexBase(nodeSubPart);
	}
}