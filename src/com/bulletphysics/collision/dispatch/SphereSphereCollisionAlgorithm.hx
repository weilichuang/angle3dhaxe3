package com.bulletphysics.collision.dispatch;
import com.bulletphysics.collision.dispatch.ManifoldResult;
import com.bulletphysics.collision.broadphase.DispatcherInfo;
import com.bulletphysics.collision.dispatch.CollisionObject;
import com.bulletphysics.collision.narrowphase.PersistentManifold;
import com.bulletphysics.collision.shapes.SphereShape;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.util.ObjectArrayList;
import vecmath.Vector3f;

import com.bulletphysics.collision.broadphase.CollisionAlgorithm;
import com.bulletphysics.collision.broadphase.CollisionAlgorithmConstructionInfo;
import com.bulletphysics.util.ObjectPool;

/**
 * Provides collision detection between two spheres.
 * @author weilichuang
 */
class SphereSphereCollisionAlgorithm extends CollisionAlgorithm
{

	private var ownManifold:Bool;
    private var manifoldPtr:PersistentManifold;

    public function init2(mf:PersistentManifold, ci:CollisionAlgorithmConstructionInfo, col0:CollisionObject,  col1:CollisionObject):Void
	{
        this.dispatcher = ci.dispatcher1;
        manifoldPtr = mf;

        if (manifoldPtr == null)
		{
            manifoldPtr = dispatcher.getNewManifold(col0, col1);
            ownManifold = true;
        }
    }

	override public function destroy():Void 
	{
		if (ownManifold) {
            if (manifoldPtr != null) {
                dispatcher.releaseManifold(manifoldPtr);
            }
            manifoldPtr = null;
        }
	}

	override public function processCollision(col0:CollisionObject, col1:CollisionObject, dispatchInfo:DispatcherInfo, resultOut:ManifoldResult):Void 
	{
		if (manifoldPtr == null)
		{
            return;
        }

        var tmpTrans1:Transform = new Transform();
        var tmpTrans2:Transform = new Transform();

        resultOut.setPersistentManifold(manifoldPtr);

        var sphere0:SphereShape = cast col0.getCollisionShape();
        var sphere1:SphereShape = cast col1.getCollisionShape();

        var diff:Vector3f = new Vector3f();
        diff.sub(col0.getWorldTransform(tmpTrans1).origin, col1.getWorldTransform(tmpTrans2).origin);

        var len:Float = diff.length();
        var radius0:Float = sphere0.getRadius();
        var radius1:Float = sphere1.getRadius();

        //#ifdef CLEAR_MANIFOLD
        //manifoldPtr.clearManifold(); // don't do this, it disables warmstarting
        //#endif

        // if distance positive, don't generate a new contact
        if (len > (radius0 + radius1)) 
		{
            //#ifndef CLEAR_MANIFOLD
            resultOut.refreshContactPoints();
            //#endif //CLEAR_MANIFOLD
            return;
        }
        // distance (negative means penetration)
        var dist:Float = len - (radius0 + radius1);

        var normalOnSurfaceB:Vector3f = new Vector3f();
        normalOnSurfaceB.setTo(1, 0, 0);
        if (len > BulletGlobals.FLT_EPSILON)
		{
            normalOnSurfaceB.scale(1 / len, diff);
        }

        var tmp:Vector3f = new Vector3f();

        // point on A (worldspace)
        var pos0:Vector3f = new Vector3f();
        tmp.scale(radius0, normalOnSurfaceB);
        pos0.sub(col0.getWorldTransform(tmpTrans1).origin, tmp);

        // point on B (worldspace)
        var pos1:Vector3f = new Vector3f();
        tmp.scale(radius1, normalOnSurfaceB);
        pos1.add(col1.getWorldTransform(tmpTrans2).origin, tmp);

        // report a contact. internally this will be kept persistent, and contact reduction is done
        resultOut.addContactPoint(normalOnSurfaceB, pos1, dist);

        //#ifndef CLEAR_MANIFOLD
        resultOut.refreshContactPoints();
        //#endif //CLEAR_MANIFOLD
	}
	
	override public function calculateTimeOfImpact(body0:CollisionObject, body1:CollisionObject, dispatchInfo:DispatcherInfo, resultOut:ManifoldResult):Float 
	{
		return 1;
	}

	override public function getAllContactManifolds(manifoldArray:ObjectArrayList<PersistentManifold>):Void 
	{
		if (manifoldPtr != null && ownManifold)
		{
            manifoldArray.add(manifoldPtr);
        }
	}
}
