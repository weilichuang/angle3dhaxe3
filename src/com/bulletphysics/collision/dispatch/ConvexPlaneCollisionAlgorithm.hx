package com.bulletphysics.collision.dispatch;
import com.bulletphysics.collision.broadphase.CollisionAlgorithm;
import com.bulletphysics.collision.broadphase.CollisionAlgorithmConstructionInfo;
import com.bulletphysics.collision.broadphase.DispatcherInfo;
import com.bulletphysics.collision.dispatch.CollisionObject;
import com.bulletphysics.collision.dispatch.ManifoldResult;
import com.bulletphysics.collision.narrowphase.PersistentManifold;
import com.bulletphysics.collision.shapes.ConvexShape;
import com.bulletphysics.collision.shapes.StaticPlaneShape;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.util.ObjectArrayList;
import com.vecmath.Vector3f;

/**
 * ConvexPlaneCollisionAlgorithm provides convex/plane collision detection.
 * @author weilichuang
 */
class ConvexPlaneCollisionAlgorithm extends CollisionAlgorithm
{
	private var ownManifold:Bool;
    private var manifoldPtr:PersistentManifold;
    private var isSwapped:Bool;

    public function init(mf:PersistentManifold, ci:CollisionAlgorithmConstructionInfo, body0:CollisionObject,  body1:CollisionObject, isSwapped:Bool):Void
	{
		this.setConstructionInfo(ci);
		
        this.ownManifold = false;
        this.manifoldPtr = mf;
        this.isSwapped = isSwapped;

        var convexObj:CollisionObject = isSwapped ? body1 : body0;
        var planeObj:CollisionObject = isSwapped ? body0 : body1;

        if (manifoldPtr == null && dispatcher.needsCollision(convexObj, planeObj)) 
		{
            manifoldPtr = dispatcher.getNewManifold(convexObj, planeObj);
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

	/**
     * Convex-Convex collision algorithm.
     */
	override public function processCollision(body0:CollisionObject, body1:CollisionObject, dispatchInfo:DispatcherInfo, resultOut:ManifoldResult):Void 
	{
		if (manifoldPtr == null) 
		{
            return;
        }

        var tmpTrans:Transform = new Transform();

        var convexObj:CollisionObject = isSwapped ? body1 : body0;
        var planeObj:CollisionObject = isSwapped ? body0 : body1;

        var convexShape:ConvexShape = cast convexObj.getCollisionShape();
        var planeShape:StaticPlaneShape = cast planeObj.getCollisionShape();

        var hasCollision:Bool = false;
        var planeNormal:Vector3f = planeShape.getPlaneNormal(new Vector3f());
        var planeConstant:Float = planeShape.getPlaneConstant();

        var planeInConvex:Transform = new Transform();
        convexObj.getWorldTransform(planeInConvex);
        planeInConvex.inverse();
        planeInConvex.mul(planeObj.getWorldTransform(tmpTrans));

        var convexInPlaneTrans:Transform = new Transform();
        convexInPlaneTrans.inverse(planeObj.getWorldTransform(tmpTrans));
        convexInPlaneTrans.mul(convexObj.getWorldTransform(tmpTrans));

        var tmp:Vector3f = new Vector3f();
        tmp.negate(planeNormal);
        planeInConvex.basis.transform(tmp);

        var vtx:Vector3f = convexShape.localGetSupportingVertex(tmp, new Vector3f());
        var vtxInPlane:Vector3f = vtx.clone();
        convexInPlaneTrans.transform(vtxInPlane);

        var distance:Float = (planeNormal.dot(vtxInPlane) - planeConstant);

        var vtxInPlaneProjected:Vector3f = new Vector3f();
        tmp.scale(distance, planeNormal);
        vtxInPlaneProjected.sub(vtxInPlane, tmp);

        var vtxInPlaneWorld:Vector3f = vtxInPlaneProjected.clone();
        planeObj.getWorldTransform(tmpTrans).transform(vtxInPlaneWorld);

        hasCollision = distance < manifoldPtr.getContactBreakingThreshold();
        resultOut.setPersistentManifold(manifoldPtr);
        if (hasCollision) 
		{
            // report a contact. internally this will be kept persistent, and contact reduction is done
            var normalOnSurfaceB:Vector3f = planeNormal.clone();
            planeObj.getWorldTransform(tmpTrans).basis.transform(normalOnSurfaceB);

            var pOnB:Vector3f = vtxInPlaneWorld.clone();
            resultOut.addContactPoint(normalOnSurfaceB, pOnB, distance);
        }
		
        if (ownManifold)
		{
            if (manifoldPtr.getNumContacts() != 0)
			{
                resultOut.refreshContactPoints();
            }
        }
	}

	override public function calculateTimeOfImpact(col0:CollisionObject, col1:CollisionObject, dispatchInfo:DispatcherInfo, resultOut:ManifoldResult):Float 
	{
		// not yet
        return 1;
	}

	override public function getAllContactManifolds(manifoldArray:ObjectArrayList<PersistentManifold>):Void 
	{
		// should we use ownManifold to avoid adding duplicates?
        if (manifoldPtr != null && ownManifold) {
            manifoldArray.add(manifoldPtr);
        }
	}
    
    public function getManifold():PersistentManifold
	{
        return manifoldPtr;
    }
	
}