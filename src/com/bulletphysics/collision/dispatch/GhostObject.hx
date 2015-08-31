package com.bulletphysics.collision.dispatch;
import com.bulletphysics.collision.broadphase.BroadphaseProxy;
import com.bulletphysics.collision.broadphase.Dispatcher;
import com.bulletphysics.collision.shapes.ConvexShape;
import com.bulletphysics.linearmath.AabbUtil2;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.TransformUtil;
import de.polygonal.ds.error.Assert;
import com.bulletphysics.util.ObjectArrayList;
import com.vecmath.Quat4f;
import com.vecmath.Vector3f;

/**
 * GhostObject can keep track of all objects that are overlapping. By default, this
 * overlap is based on the AABB. This is useful for creating a character controller,
 * collision sensors/triggers, explosions etc.
 * @author weilichuang
 */
class GhostObject extends CollisionObject
{
	private var overlappingObjects:ObjectArrayList<CollisionObject> = new ObjectArrayList<CollisionObject>();

	public function new() 
	{
		super();
		this.internalType = CollisionObjectType.GHOST_OBJECT;
	}
	
	/**
     * This method is mainly for expert/internal use only.
     */
    public function addOverlappingObjectInternal(otherProxy:BroadphaseProxy, thisProxy:BroadphaseProxy):Void
	{
        var otherObject:CollisionObject = cast otherProxy.clientObject;
		
		#if debug
        Assert.assert (otherObject != null);
		#end

        // if this linearSearch becomes too slow (too many overlapping objects) we should add a more appropriate data structure
        var index:Int = overlappingObjects.indexOf(otherObject);
        if (index == -1)
		{
            // not found
            overlappingObjects.add(otherObject);
        }
    }

    /**
     * This method is mainly for expert/internal use only.
     */
    public function removeOverlappingObjectInternal(otherProxy:BroadphaseProxy, dispatcher:Dispatcher,  thisProxy:BroadphaseProxy):Void
	{
        var otherObject:CollisionObject = cast otherProxy.clientObject;
        Assert.assert (otherObject != null);

        var index:Int = overlappingObjects.indexOf(otherObject);
        if (index != -1) 
		{
            overlappingObjects.set(index, overlappingObjects.getQuick(overlappingObjects.size() - 1));
            overlappingObjects.removeQuick(overlappingObjects.size() - 1);
        }
    }

    public function convexSweepTest( castShape:ConvexShape, convexFromWorld:Transform, convexToWorld:Transform,  resultCallback:CollisionWorld.ConvexResultCallback, allowedCcdPenetration:Float):Void
	{
        var convexFromTrans:Transform = new Transform();
        var convexToTrans:Transform = new Transform();

        convexFromTrans.fromTransform(convexFromWorld);
        convexToTrans.fromTransform(convexToWorld);

        var castShapeAabbMin:Vector3f = new Vector3f();
        var castShapeAabbMax:Vector3f = new Vector3f();

        // compute AABB that encompasses angular movement
        {
            var linVel:Vector3f = new Vector3f();
            var angVel:Vector3f = new Vector3f();
            TransformUtil.calculateVelocity(convexFromTrans, convexToTrans, 1, linVel, angVel);
            var R:Transform = new Transform();
            R.setIdentity();
            R.setRotation(convexFromTrans.getRotation(new Quat4f()));
            castShape.calculateTemporalAabb(R, linVel, angVel, 1, castShapeAabbMin, castShapeAabbMax);
        }

        // go over all objects, and if the ray intersects their aabb + cast shape aabb,
        // do a ray-shape query using convexCaster (CCD)
        for (i in 0...overlappingObjects.size())
		{
            var collisionObject:CollisionObject = overlappingObjects.getQuick(i);

            // only perform raycast if filterMask matches
            if (resultCallback.needsCollision(collisionObject.getBroadphaseHandle()))
			{
                //RigidcollisionObject* collisionObject = ctrl->GetRigidcollisionObject();
                var collisionObjectAabbMin:Vector3f = new Vector3f();
                var collisionObjectAabbMax:Vector3f = new Vector3f();
                collisionObject.getCollisionShape().getAabb(collisionObject.getWorldTransform(), collisionObjectAabbMin, collisionObjectAabbMax);
                AabbUtil2.aabbExpand(collisionObjectAabbMin, collisionObjectAabbMax, castShapeAabbMin, castShapeAabbMax);
                var hitLambda:Array<Float> = [1]; // could use resultCallback.closestHitFraction, but needs testing
                var hitNormal:Vector3f = new Vector3f();
                if (AabbUtil2.rayAabb(convexFromWorld.origin, convexToWorld.origin, collisionObjectAabbMin, collisionObjectAabbMax, hitLambda, hitNormal)) 
				{
                    CollisionWorld.objectQuerySingle(castShape, convexFromTrans, convexToTrans,
                            collisionObject,
                            collisionObject.getCollisionShape(),
                            collisionObject.getWorldTransform(),
                            resultCallback,
                            allowedCcdPenetration);
                }
            }
        }
    }

    public function rayTest(rayFromWorld:Vector3f, rayToWorld:Vector3f, resultCallback:CollisionWorld.RayResultCallback):Void
	{
        var rayFromTrans:Transform = new Transform();
        rayFromTrans.setIdentity();
        rayFromTrans.origin.copyFrom(rayFromWorld);
        var rayToTrans:Transform = new Transform();
        rayToTrans.setIdentity();
        rayToTrans.origin.copyFrom(rayToWorld);

        for (i in 0...overlappingObjects.size())
		{
            var collisionObject:CollisionObject = overlappingObjects.getQuick(i);

            // only perform raycast if filterMask matches
            if (resultCallback.needsCollision(collisionObject.getBroadphaseHandle())) 
			{
                CollisionWorld.rayTestSingle(rayFromTrans, rayToTrans,
                        collisionObject,
                        collisionObject.getCollisionShape(),
                        collisionObject.getWorldTransform(),
                        resultCallback);
            }
        }
    }

    public inline function getNumOverlappingObjects():Int
	{
        return overlappingObjects.size();
    }

    public inline function getOverlappingObject(index:Int):CollisionObject
	{
        return overlappingObjects.getQuick(index);
    }

    public inline function getOverlappingPairs():ObjectArrayList<CollisionObject>
	{
        return overlappingObjects;
    }

    //
    // internal cast
    //

    public static inline function upcast(colObj:CollisionObject):GhostObject
	{
        //if (colObj.getInternalType() == CollisionObjectType.GHOST_OBJECT) 
		//{
            //return cast colObj;
        //}
//
        //return null;
		return Std.instance(colObj, GhostObject);
    }
}