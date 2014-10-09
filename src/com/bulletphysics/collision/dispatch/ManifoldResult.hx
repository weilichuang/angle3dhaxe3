package com.bulletphysics.collision.dispatch;
import com.bulletphysics.collision.narrowphase.DiscreteCollisionDetectorInterface.Result;
import com.bulletphysics.collision.narrowphase.ManifoldPoint;
import com.bulletphysics.collision.narrowphase.PersistentManifold;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.util.Assert;
import com.bulletphysics.util.ObjectPool;
import com.vecmath.Vector3f;

/**
 * ManifoldResult is helper class to manage contact results.
 * @author weilichuang
 */
class ManifoldResult implements Result
{
	private var pointsPool:ObjectPool<ManifoldPoint> = ObjectPool.getPool(ManifoldPoint);

    private var manifoldPtr:PersistentManifold;

    // we need this for compounds
    private var rootTransA:Transform = new Transform();
    private var rootTransB:Transform = new Transform();
    private var body0:CollisionObject;
    private var body1:CollisionObject;
    private var partId0:Int;
    private var partId1:Int;
    private var index0:Int;
    private var index1:Int;

    public function new()
	{
    }

    public function init(body0:CollisionObject, body1:CollisionObject):Void
	{
        this.body0 = body0;
        this.body1 = body1;
        body0.getWorldTransform(this.rootTransA);
        body1.getWorldTransform(this.rootTransB);
    }

    public function getPersistentManifold():PersistentManifold
	{
        return manifoldPtr;
    }

    public function setPersistentManifold(manifoldPtr:PersistentManifold):Void
	{
        this.manifoldPtr = manifoldPtr;
    }

    public function setShapeIdentifiers(partId0:Int,index0:Int, partId1:Int, index1:Int):Void
	{
        this.partId0 = partId0;
        this.partId1 = partId1;
        this.index0 = index0;
        this.index1 = index1;
    }

    public function addContactPoint(normalOnBInWorld:Vector3f, pointInWorld:Vector3f, depth:Float):Void
	{
        Assert.assert (manifoldPtr != null);
        //order in manifold needs to match

        if (depth > manifoldPtr.getContactBreakingThreshold())
		{
            return;
        }

        var isSwapped:Bool = manifoldPtr.getBody0() != body0;

        var pointA:Vector3f = new Vector3f();
        pointA.scaleAdd(depth, normalOnBInWorld, pointInWorld);

        var localA:Vector3f = new Vector3f();
        var localB:Vector3f = new Vector3f();

        if (isSwapped) 
		{
            rootTransB.invXform(pointA, localA);
            rootTransA.invXform(pointInWorld, localB);
        } 
		else
		{
            rootTransA.invXform(pointA, localA);
            rootTransB.invXform(pointInWorld, localB);
        }

        var newPt:ManifoldPoint = pointsPool.get();
        newPt.init(localA, localB, normalOnBInWorld, depth);

        newPt.positionWorldOnA.fromVector3f(pointA);
        newPt.positionWorldOnB.fromVector3f(pointInWorld);

        var insertIndex:Int = manifoldPtr.getCacheEntry(newPt);

        newPt.combinedFriction = calculateCombinedFriction(body0, body1);
        newPt.combinedRestitution = calculateCombinedRestitution(body0, body1);

        // BP mod, store contact triangles.
        newPt.partId0 = partId0;
        newPt.partId1 = partId1;
        newPt.index0 = index0;
        newPt.index1 = index1;

        /// todo, check this for any side effects
        if (insertIndex >= 0) 
		{
            //const btManifoldPoint& oldPoint = m_manifoldPtr->getContactPoint(insertIndex);
            manifoldPtr.replaceContactPoint(newPt, insertIndex);
        } 
		else
		{
            insertIndex = manifoldPtr.addManifoldPoint(newPt);
        }

        // User can override friction and/or restitution
        if (BulletGlobals.gContactAddedCallback != null &&
                // and if either of the two bodies requires custom material
                ((body0.getCollisionFlags() & CollisionFlags.CUSTOM_MATERIAL_CALLBACK) != 0 ||
                        (body1.getCollisionFlags() & CollisionFlags.CUSTOM_MATERIAL_CALLBACK) != 0))
		{
            //experimental feature info, for per-triangle material etc.
            var obj0:CollisionObject = isSwapped ? body1 : body0;
            var obj1:CollisionObject = isSwapped ? body0 : body1;
            BulletGlobals.gContactAddedCallback.contactAdded(manifoldPtr.getContactPoint(insertIndex), obj0, partId0, index0, obj1, partId1, index1);
        }

        pointsPool.release(newPt);
    }

    ///User can override this material combiner by implementing gContactAddedCallback and setting body0->m_collisionFlags |= btCollisionObject::customMaterialCallback;
    private static function calculateCombinedFriction(body0:CollisionObject, body1:CollisionObject):Float
	{
        var friction:Float = body0.getFriction() * body1.getFriction();

        var MAX_FRICTION:Float = 10;
        if (friction < -MAX_FRICTION)
		{
            friction = -MAX_FRICTION;
        }
        if (friction > MAX_FRICTION) 
		{
            friction = MAX_FRICTION;
        }
        return friction;
    }

    private static function calculateCombinedRestitution(body0:CollisionObject, body1:CollisionObject):Float
	{
        return body0.getRestitution() * body1.getRestitution();
    }

    public function refreshContactPoints():Void
	{
        Assert.assert (manifoldPtr != null);
		
        if (manifoldPtr.getNumContacts() == 0)
		{
            return;
        }

        var isSwapped:Bool = manifoldPtr.getBody0() != body0;

        if (isSwapped) 
		{
            manifoldPtr.refreshContactPoints(rootTransB, rootTransA);
        } 
		else 
		{
            manifoldPtr.refreshContactPoints(rootTransA, rootTransB);
        }
    }
}