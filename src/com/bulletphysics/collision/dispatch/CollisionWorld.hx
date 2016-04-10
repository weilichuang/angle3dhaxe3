package com.bulletphysics.collision.dispatch;
import com.bulletphysics.collision.broadphase.BroadphaseInterface;
import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.bulletphysics.collision.broadphase.BroadphaseProxy;
import com.bulletphysics.collision.broadphase.CollisionFilterGroups;
import com.bulletphysics.collision.broadphase.Dispatcher;
import com.bulletphysics.collision.broadphase.DispatcherInfo;
import com.bulletphysics.collision.broadphase.OverlappingPairCache;
import com.bulletphysics.collision.narrowphase.CastResult;
import com.bulletphysics.collision.narrowphase.ConvexCast;
import com.bulletphysics.collision.narrowphase.GjkConvexCast;
import com.bulletphysics.collision.narrowphase.GjkEpaPenetrationDepthSolver;
import com.bulletphysics.collision.narrowphase.SubsimplexConvexCast;
import com.bulletphysics.collision.narrowphase.TriangleConvexcastCallback;
import com.bulletphysics.collision.narrowphase.TriangleRaycastCallback;
import com.bulletphysics.collision.narrowphase.VoronoiSimplexSolver;
import com.bulletphysics.collision.shapes.BvhTriangleMeshShape;
import com.bulletphysics.collision.shapes.CollisionShape;
import com.bulletphysics.collision.shapes.CompoundShape;
import com.bulletphysics.collision.shapes.ConcaveShape;
import com.bulletphysics.collision.shapes.ConvexShape;
import com.bulletphysics.collision.shapes.SphereShape;
import com.bulletphysics.collision.shapes.TriangleMeshShape;
import com.bulletphysics.linearmath.AabbUtil2;
import com.bulletphysics.linearmath.IDebugDraw;
import com.bulletphysics.linearmath.LinearMathUtil;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.TransformUtil;
import com.bulletphysics.util.ObjectArrayList;
import com.bulletphysics.util.StackPool;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import de.polygonal.ds.error.Assert;

/**
 * ...
 
 */
class CollisionWorld
{
    private var collisionObjects:ObjectArrayList<CollisionObject> = new ObjectArrayList<CollisionObject>();
    private var dispatcher1:Dispatcher;
    private var dispatchInfo:DispatcherInfo = new DispatcherInfo();

    private var broadphasePairCache:BroadphaseInterface;
    private var debugDrawer:IDebugDraw;

    /**
     * This constructor doesn't own the dispatcher and paircache/broadphase.
     */
    public function new(dispatcher:Dispatcher, broadphasePairCache:BroadphaseInterface, collisionConfiguration:CollisionConfiguration)
	{
        this.dispatcher1 = dispatcher;
        this.broadphasePairCache = broadphasePairCache;
    }

    public function destroy():Void
	{
        // clean up remaining objects
        for (i in 0...collisionObjects.size())
		{
            var collisionObject:CollisionObject = collisionObjects.getQuick(i);

            var bp:BroadphaseProxy = collisionObject.getBroadphaseHandle();
            if (bp != null)
			{
                //
                // only clear the cached algorithms
                //
                getBroadphase().getOverlappingPairCache().cleanProxyFromPairs(bp, dispatcher1);
                getBroadphase().destroyProxy(bp, dispatcher1);
            }
        }
    }

    public function addCollisionObject(collisionObject:CollisionObject,
										collisionFilterGroup:Int = CollisionFilterGroups.DEFAULT_FILTER,
										collisionFilterMask:Int = CollisionFilterGroups.ALL_FILTER):Void						
	{
        // check that the object isn't already added
        Assert.assert (!collisionObjects.contains(collisionObject));

        collisionObjects.add(collisionObject);
		
		var pool:StackPool = StackPool.get();

        // calculate new AABB
        // TODO: check if it's overwritten or not
        var trans:Transform = collisionObject.getWorldTransform();

        var minAabb:Vector3f = pool.getVector3f();
        var maxAabb:Vector3f = pool.getVector3f();
        collisionObject.getCollisionShape().getAabb(trans, minAabb, maxAabb);

        var type:BroadphaseNativeType = collisionObject.getCollisionShape().shapeType;
        collisionObject.setBroadphaseHandle(getBroadphase().createProxy(
                minAabb,
                maxAabb,
                type,
                collisionObject,
                collisionFilterGroup,
                collisionFilterMask,
                dispatcher1, null));
		
		pool.release();
    }

    public function performDiscreteCollisionDetection():Void
	{
        BulletStats.pushProfile("performDiscreteCollisionDetection");
        {
            //DispatcherInfo dispatchInfo = getDispatchInfo();

            updateAabbs();

            BulletStats.pushProfile("calculateOverlappingPairs");
			broadphasePairCache.calculateOverlappingPairs(dispatcher1);
			BulletStats.popProfile();

            var dispatcher:Dispatcher = getDispatcher();
			BulletStats.pushProfile("dispatchAllCollisionPairs");
			if (dispatcher != null) 
			{
				dispatcher.dispatchAllCollisionPairs(broadphasePairCache.getOverlappingPairCache(), dispatchInfo, dispatcher1);
			}
			BulletStats.popProfile();
        } 
        BulletStats.popProfile();
    }

    public function removeCollisionObject(collisionObject:CollisionObject):Void
	{
		var bp:BroadphaseProxy = collisionObject.getBroadphaseHandle();
		if (bp != null)
		{
			//
			// only clear the cached algorithms
			//
			getBroadphase().getOverlappingPairCache().cleanProxyFromPairs(bp, dispatcher1);
			getBroadphase().destroyProxy(bp, dispatcher1);
			collisionObject.setBroadphaseHandle(null);
		}

        //swapremove
        collisionObjects.removeObject(collisionObject);
    }

    public function setBroadphase(pairCache:BroadphaseInterface):Void
	{
        broadphasePairCache = pairCache;
    }

    public function getBroadphase():BroadphaseInterface
	{
        return broadphasePairCache;
    }

    public function getPairCache():OverlappingPairCache
	{
        return broadphasePairCache.getOverlappingPairCache();
    }

    public inline function getDispatcher():Dispatcher
	{
        return dispatcher1;
    }

    public inline function getDispatchInfo():DispatcherInfo
	{
        return dispatchInfo;
    }

    private static var updateAabbs_reportMe:Bool = true;

    // JAVA NOTE: ported from 2.74, missing contact threshold stuff
	private var minAabb:Vector3f = new Vector3f();
	private var maxAabb:Vector3f = new Vector3f();
	private var tmp:Vector3f = new Vector3f();
	//private var tmpTrans:Transform = new Transform();
    public inline function updateSingleAabb(colObj:CollisionObject):Void
	{
        colObj.getCollisionShape().getAabb(colObj.getWorldTransform(), minAabb, maxAabb);
		
        // need to increase the aabb for contact thresholds
        //var contactThreshold:Vector3f = new Vector3f(BulletGlobals.contactBreakingThreshold, BulletGlobals.contactBreakingThreshold, BulletGlobals.contactBreakingThreshold);
        //minAabb.sub(contactThreshold);
        //maxAabb.add(contactThreshold);
		var contactThreshold:Float = BulletGlobals.contactBreakingThreshold;
		minAabb.x -= contactThreshold;
		minAabb.y -= contactThreshold;
		minAabb.z -= contactThreshold;
		maxAabb.x += contactThreshold;
		maxAabb.y += contactThreshold;
		maxAabb.z += contactThreshold;
		

        var bp:BroadphaseInterface = broadphasePairCache;

        // moving objects should be moderately sized, probably something wrong if not
        tmp.subtractBy(maxAabb, minAabb); // TODO: optimize
        if (colObj.isStaticObject() || (tmp.lengthSquared < 1e12))
		{
            bp.setAabb(colObj.getBroadphaseHandle(), minAabb, maxAabb, dispatcher1);
        } 
		else 
		{
            // something went wrong, investigate
            // this assert is unwanted in 3D modelers (danger of loosing work)
            colObj.setActivationState(CollisionObject.DISABLE_SIMULATION);

            if (updateAabbs_reportMe && debugDrawer != null) 
			{
                updateAabbs_reportMe = false;
                debugDrawer.reportErrorWarning("Overflow in AABB, object removed from simulation");
                debugDrawer.reportErrorWarning("If you can reproduce this, please email bugs@continuousphysics.com\n");
                debugDrawer.reportErrorWarning("Please include above information, your Platform, version of OS.\n");
                debugDrawer.reportErrorWarning("Thanks.\n");
            }
        }
    }

    public function updateAabbs():Void
	{
        BulletStats.pushProfile("updateAabbs");
		for (i in 0...collisionObjects.size()) 
		{
			var colObj:CollisionObject = collisionObjects.getQuick(i);

			// only update aabb of active objects
			if (colObj.isActive())
			{
				updateSingleAabb(colObj);
			}
		}
		BulletStats.popProfile();
    }

    public function getDebugDrawer():IDebugDraw 
	{
        return debugDrawer;
    }

    public function setDebugDrawer( debugDrawer:IDebugDraw):Void
	{
        this.debugDrawer = debugDrawer;
    }

    public function getNumCollisionObjects():Int
	{
        return collisionObjects.size();
    }

    // TODO
	private static var convexCaster:SubsimplexConvexCast;
	private static var simplexSolver:VoronoiSimplexSolver;
	private static var castResult:CastResult;
    public static function rayTestSingle(rayFromTrans:Transform, rayToTrans:Transform,
										  collisionObject:CollisionObject,
										  collisionShape:CollisionShape,
										  colObjWorldTransform:Transform,
										  resultCallback:RayResultCallback):Void
	 {
        var pointShape:SphereShape = new SphereShape(0);
        pointShape.setMargin(0);
		
        var castShape:ConvexShape = pointShape;

        if (collisionShape.isConvex())
		{
            if (castResult == null)
				castResult = new CastResult();
            castResult.fraction = resultCallback.closestHitFraction;

            var convexShape:ConvexShape = cast collisionShape;
            

            //#define USE_SUBSIMPLEX_CONVEX_CAST 1
            //#ifdef USE_SUBSIMPLEX_CONVEX_CAST
			if (convexCaster == null)
				convexCaster = new SubsimplexConvexCast();
			if (simplexSolver == null)
				simplexSolver = new VoronoiSimplexSolver();
			convexCaster.init(castShape, convexShape, simplexSolver);
            //#else
            //btGjkConvexCast	convexCaster(castShape,convexShape,&simplexSolver);
            //btContinuousConvexCollision convexCaster(castShape,convexShape,&simplexSolver,0);
            //#endif //#USE_SUBSIMPLEX_CONVEX_CAST

            if (convexCaster.calcTimeOfImpact(rayFromTrans, rayToTrans, colObjWorldTransform, colObjWorldTransform, castResult))
			{
                //add hit
                if (castResult.normal.lengthSquared > 0.0001)
				{
                    if (castResult.fraction < resultCallback.closestHitFraction) 
					{
                        //#ifdef USE_SUBSIMPLEX_CONVEX_CAST
                        //rotate normal into worldspace
                        rayFromTrans.basis.multVecLocal(castResult.normal);
                        //#endif //USE_SUBSIMPLEX_CONVEX_CAST

                        castResult.normal.normalizeLocal();
                        var localRayResult:LocalRayResult = new LocalRayResult(
                                collisionObject,
                                null,
                                castResult.normal,
                                castResult.fraction);

                        var normalInWorldSpace:Bool = true;
                        resultCallback.addSingleResult(localRayResult, normalInWorldSpace);
                    }
                }
            }
        } 
		else if (collisionShape.isConcave())
		{
            if (collisionShape.shapeType == BroadphaseNativeType.TRIANGLE_MESH_SHAPE_PROXYTYPE)
			{
                // optimized version for BvhTriangleMeshShape
                var triangleMesh:BvhTriangleMeshShape = cast collisionShape;
                var worldTocollisionObject:Transform = new Transform();
                worldTocollisionObject.inverse(colObjWorldTransform);
                var rayFromLocal:Vector3f = rayFromTrans.origin.clone();
                worldTocollisionObject.transform(rayFromLocal);
                var rayToLocal:Vector3f = rayToTrans.origin.clone();
                worldTocollisionObject.transform(rayToLocal);

                var rcb:BridgeTriangleRaycastCallback = new BridgeTriangleRaycastCallback(rayFromLocal, rayToLocal, resultCallback, collisionObject, triangleMesh);
                rcb.hitFraction = resultCallback.closestHitFraction;
                triangleMesh.performRaycast(rcb, rayFromLocal, rayToLocal);
            } 
			else 
			{
                var triangleMesh:ConcaveShape = cast collisionShape;

                var worldTocollisionObject:Transform = new Transform();
                worldTocollisionObject.inverse(colObjWorldTransform);

                var rayFromLocal:Vector3f = rayFromTrans.origin.clone();
                worldTocollisionObject.transform(rayFromLocal);
                var rayToLocal:Vector3f = rayToTrans.origin.clone();
                worldTocollisionObject.transform(rayToLocal);

                var rcb:BridgeTriangleRaycastCallback = new BridgeTriangleRaycastCallback(rayFromLocal, rayToLocal, resultCallback, collisionObject, triangleMesh);
                rcb.hitFraction = resultCallback.closestHitFraction;

                var rayAabbMinLocal:Vector3f = rayFromLocal.clone();
                LinearMathUtil.setMin(rayAabbMinLocal, rayToLocal);
                var rayAabbMaxLocal:Vector3f = rayFromLocal.clone();
                LinearMathUtil.setMax(rayAabbMaxLocal, rayToLocal);

                triangleMesh.processAllTriangles(rcb, rayAabbMinLocal, rayAabbMaxLocal);
            }
        } 
		else if (collisionShape.isCompound())
		{
            // todo: use AABB tree or other BVH acceleration structure!
            var compoundShape:CompoundShape = cast collisionShape;
            var childTrans:Transform = new Transform();
            for (i in 0...compoundShape.getNumChildShapes())
			{
                compoundShape.getChildTransform(i, childTrans);
                var childCollisionShape:CollisionShape = compoundShape.getChildShape(i);
                var childWorldTrans:Transform = colObjWorldTransform.clone();
                childWorldTrans.mul(childTrans);
                // replace collision shape so that callback can determine the triangle
                var saveCollisionShape:CollisionShape = collisionObject.getCollisionShape();
                collisionObject.internalSetTemporaryCollisionShape(childCollisionShape);
                rayTestSingle(rayFromTrans, rayToTrans,
                        collisionObject,
                        childCollisionShape,
                        childWorldTrans,
                        resultCallback);
                // restore
                collisionObject.internalSetTemporaryCollisionShape(saveCollisionShape);
            }
        }
    }

    /**
     * objectQuerySingle performs a collision detection query and calls the resultCallback. It is used internally by rayTest.
     */
    public static function objectQuerySingle(castShape:ConvexShape, convexFromTrans:Transform, convexToTrans:Transform, 
											collisionObject:CollisionObject, collisionShape:CollisionShape, colObjWorldTransform:Transform, resultCallback:ConvexResultCallback, allowedPenetration:Float):Void
	{
        if (collisionShape.isConvex())
		{
            var castResult:CastResult = new CastResult();
            castResult.allowedPenetration = allowedPenetration;
            castResult.fraction = 1; // ??

            var convexShape:ConvexShape = cast collisionShape;
            var simplexSolver:VoronoiSimplexSolver = new VoronoiSimplexSolver();
            var gjkEpaPenetrationSolver:GjkEpaPenetrationDepthSolver = new GjkEpaPenetrationDepthSolver();

            // JAVA TODO: should be convexCaster1
            //ContinuousConvexCollision convexCaster1(castShape,convexShape,&simplexSolver,&gjkEpaPenetrationSolver);
            var convexCaster2:GjkConvexCast = new GjkConvexCast(castShape, convexShape, simplexSolver);
            //btSubsimplexConvexCast convexCaster3(castShape,convexShape,&simplexSolver);

            var castPtr:ConvexCast = convexCaster2;

            if (castPtr.calcTimeOfImpact(convexFromTrans, convexToTrans, colObjWorldTransform, colObjWorldTransform, castResult))
			{
                // add hit
                if (castResult.normal.lengthSquared > 0.0001)
				{
                    if (castResult.fraction < resultCallback.closestHitFraction) 
					{
                        castResult.normal.normalizeLocal();
                        var localConvexResult:LocalConvexResult = new LocalConvexResult(collisionObject, null, castResult.normal, castResult.hitPoint, castResult.fraction);

                        var normalInWorldSpace:Bool = true;
                        resultCallback.addSingleResult(localConvexResult, normalInWorldSpace);
                    }
                }
            }
        } 
		else if (collisionShape.isConcave()) 
		{
            if (collisionShape.shapeType == BroadphaseNativeType.TRIANGLE_MESH_SHAPE_PROXYTYPE)
			{
                var triangleMesh:BvhTriangleMeshShape = cast collisionShape;
                var worldTocollisionObject:Transform = new Transform();
                worldTocollisionObject.inverse(colObjWorldTransform);

                var convexFromLocal:Vector3f = new Vector3f();
                convexFromLocal.copyFrom(convexFromTrans.origin);
                worldTocollisionObject.transform(convexFromLocal);

                var convexToLocal:Vector3f = new Vector3f();
                convexToLocal.copyFrom(convexToTrans.origin);
                worldTocollisionObject.transform(convexToLocal);

                // rotation of box in local mesh space = MeshRotation^-1 * ConvexToRotation
                var rotationXform:Transform = new Transform();
                var tmpMat:Matrix3f = new Matrix3f();
                tmpMat.multBy(worldTocollisionObject.basis, convexToTrans.basis);
                rotationXform.fromMatrix3f(tmpMat);

                var tccb:BridgeTriangleConvexcastCallback = new BridgeTriangleConvexcastCallback(castShape, convexFromTrans, convexToTrans, resultCallback, collisionObject, triangleMesh, colObjWorldTransform);
                tccb.hitFraction = resultCallback.closestHitFraction;
                tccb.normalInWorldSpace = true;

                var boxMinLocal:Vector3f = new Vector3f();
                var boxMaxLocal:Vector3f = new Vector3f();
                castShape.getAabb(rotationXform, boxMinLocal, boxMaxLocal);
                triangleMesh.performConvexcast(tccb, convexFromLocal, convexToLocal, boxMinLocal, boxMaxLocal);
            } 
			else 
			{
                var triangleMesh:BvhTriangleMeshShape = cast collisionShape;
                var worldTocollisionObject:Transform = new Transform();
                worldTocollisionObject.inverse(colObjWorldTransform);

                var convexFromLocal:Vector3f = new Vector3f();
                convexFromLocal.copyFrom(convexFromTrans.origin);
                worldTocollisionObject.transform(convexFromLocal);

                var convexToLocal:Vector3f = new Vector3f();
                convexToLocal.copyFrom(convexToTrans.origin);
                worldTocollisionObject.transform(convexToLocal);

                // rotation of box in local mesh space = MeshRotation^-1 * ConvexToRotation
                var rotationXform:Transform = new Transform();
                var tmpMat:Matrix3f = new Matrix3f();
                tmpMat.multBy(worldTocollisionObject.basis, convexToTrans.basis);
                rotationXform.fromMatrix3f(tmpMat);

                var tccb:BridgeTriangleConvexcastCallback = new BridgeTriangleConvexcastCallback(castShape, convexFromTrans, convexToTrans, resultCallback, collisionObject, triangleMesh, colObjWorldTransform);
                tccb.hitFraction = resultCallback.closestHitFraction;
                tccb.normalInWorldSpace = false;
                var boxMinLocal:Vector3f = new Vector3f();
                var boxMaxLocal:Vector3f = new Vector3f();
                castShape.getAabb(rotationXform, boxMinLocal, boxMaxLocal);

                var rayAabbMinLocal:Vector3f = convexFromLocal.clone();
                LinearMathUtil.setMin(rayAabbMinLocal, convexToLocal);
                var rayAabbMaxLocal:Vector3f = convexFromLocal.clone();
                LinearMathUtil.setMax(rayAabbMaxLocal, convexToLocal);
                rayAabbMinLocal.addLocal(boxMinLocal);
                rayAabbMaxLocal.addLocal(boxMaxLocal);
                triangleMesh.processAllTriangles(tccb, rayAabbMinLocal, rayAabbMaxLocal);
            }
        }
		else if (collisionShape.isCompound())
		{
            // todo: use AABB tree or other BVH acceleration structure!
            var compoundShape:CompoundShape = cast collisionShape;
            for (i in 0...compoundShape.getNumChildShapes()) 
			{
                var childTrans:Transform = compoundShape.getChildTransform(i, new Transform());
                var childCollisionShape:CollisionShape = compoundShape.getChildShape(i);
                var childWorldTrans:Transform = new Transform();
                childWorldTrans.mul2(colObjWorldTransform, childTrans);
                // replace collision shape so that callback can determine the triangle
                var saveCollisionShape:CollisionShape = collisionObject.getCollisionShape();
                collisionObject.internalSetTemporaryCollisionShape(childCollisionShape);
                objectQuerySingle(castShape, convexFromTrans, convexToTrans,
                        collisionObject,
                        childCollisionShape,
                        childWorldTrans,
                        resultCallback, allowedPenetration);
                // restore
                collisionObject.internalSetTemporaryCollisionShape(saveCollisionShape);
            }
        }
    }

    /**
     * rayTest performs a raycast on all objects in the CollisionWorld, and calls the resultCallback.
     * This allows for several queries: first hit, all hits, any hit, dependent on the value returned by the callback.
     */
    public function rayTest(rayFromWorld:Vector3f, rayToWorld:Vector3f, resultCallback:RayResultCallback):Void
	{
        var rayFromTrans:Transform = new Transform();
		var rayToTrans:Transform = new Transform();
        rayFromTrans.setIdentity();
        rayFromTrans.origin.copyFrom(rayFromWorld);
        rayToTrans.setIdentity();

        rayToTrans.origin.copyFrom(rayToWorld);

        // go over all objects, and if the ray intersects their aabb, do a ray-shape query using convexCaster (CCD)
        var collisionObjectAabbMin:Vector3f = new Vector3f();
		var collisionObjectAabbMax:Vector3f = new Vector3f();
        var hitLambda:Array<Float> = [0];

        //var tmpTrans:Transform = new Transform();

        for (i in 0...collisionObjects.size())
		{
            // terminate further ray tests, once the closestHitFraction reached zero
            if (resultCallback.closestHitFraction == 0)
			{
                break;
            }

            var collisionObject:CollisionObject = collisionObjects.getQuick(i);
            // only perform raycast if filterMask matches
            if (resultCallback.needsCollision(collisionObject.getBroadphaseHandle()))
			{
                //RigidcollisionObject* collisionObject = ctrl->GetRigidcollisionObject();
                collisionObject.getCollisionShape().getAabb(collisionObject.getWorldTransform(), collisionObjectAabbMin, collisionObjectAabbMax);

                hitLambda[0] = resultCallback.closestHitFraction;
                var hitNormal:Vector3f = new Vector3f();
                if (AabbUtil2.rayAabb(rayFromWorld, rayToWorld, collisionObjectAabbMin, collisionObjectAabbMax, hitLambda, hitNormal))
				{
                    rayTestSingle(rayFromTrans, rayToTrans,
                            collisionObject,
                            collisionObject.getCollisionShape(),
                            collisionObject.getWorldTransform(),
                            resultCallback);
                }
            }

        }
    }

    /**
     * convexTest performs a swept convex cast on all objects in the {CollisionWorld}, and calls the resultCallback
     * This allows for several queries: first hit, all hits, any hit, dependent on the value return by the callback.
     */
    public function convexSweepTest(castShape:ConvexShape, convexFromWorld:Transform, convexToWorld:Transform,  resultCallback:ConvexResultCallback):Void
	{
        var convexFromTrans:Transform = new Transform();
        var convexToTrans:Transform = new Transform();

        convexFromTrans.fromTransform(convexFromWorld);
        convexToTrans.fromTransform(convexToWorld);

        var castShapeAabbMin:Vector3f = new Vector3f();
        var castShapeAabbMax:Vector3f = new Vector3f();

        // Compute AABB that encompasses angular movement
        {
            var linVel:Vector3f = new Vector3f();
            var angVel:Vector3f = new Vector3f();
            TransformUtil.calculateVelocity(convexFromTrans, convexToTrans, 1, linVel, angVel);
            var R:Transform = new Transform();
            R.setIdentity();
            R.setRotation(convexFromTrans.getRotation(new Quaternion()));
            castShape.calculateTemporalAabb(R, linVel, angVel, 1, castShapeAabbMin, castShapeAabbMax);
        }

        var tmpTrans:Transform = new Transform();
        var collisionObjectAabbMin:Vector3f = new Vector3f();
        var collisionObjectAabbMax:Vector3f = new Vector3f();
        var hitLambda:Array<Float> = [0];

        // go over all objects, and if the ray intersects their aabb + cast shape aabb,
        // do a ray-shape query using convexCaster (CCD)
        for (i in 0...collisionObjects.size()) 
		{
            var collisionObject:CollisionObject = collisionObjects.getQuick(i);

            // only perform raycast if filterMask matches
            if (resultCallback.needsCollision(collisionObject.getBroadphaseHandle())) 
			{
                //RigidcollisionObject* collisionObject = ctrl->GetRigidcollisionObject();
                collisionObject.getWorldTransformTo(tmpTrans);
                collisionObject.getCollisionShape().getAabb(tmpTrans, collisionObjectAabbMin, collisionObjectAabbMax);
                AabbUtil2.aabbExpand(collisionObjectAabbMin, collisionObjectAabbMax, castShapeAabbMin, castShapeAabbMax);
                hitLambda[0] = 1; // could use resultCallback.closestHitFraction, but needs testing
                var hitNormal:Vector3f = new Vector3f();
                if (AabbUtil2.rayAabb(convexFromWorld.origin, convexToWorld.origin, collisionObjectAabbMin, collisionObjectAabbMax, hitLambda, hitNormal))
				{
                    objectQuerySingle(castShape, convexFromTrans, convexToTrans,
                            collisionObject,
                            collisionObject.getCollisionShape(),
                            tmpTrans,
                            resultCallback,
                            getDispatchInfo().allowedCcdPenetration);
                }
            }
        }
    }

    public function getCollisionObjectArray():ObjectArrayList<CollisionObject>
	{
        return collisionObjects;
    }
}

class BridgeTriangleConvexcastCallback extends TriangleConvexcastCallback 
{
	public var resultCallback:ConvexResultCallback;
	public var collisionObject:CollisionObject;
	public var triangleMesh:TriangleMeshShape;
	public var normalInWorldSpace:Bool;

	public function new(castShape:ConvexShape, from:Transform, to:Transform, resultCallback:ConvexResultCallback, collisionObject:CollisionObject, triangleMesh:TriangleMeshShape, triangleToWorld:Transform)
	{
		super(castShape, from, to, triangleToWorld, triangleMesh.getMargin());
		this.resultCallback = resultCallback;
		this.collisionObject = collisionObject;
		this.triangleMesh = triangleMesh;
	}
	
	override public function reportHit(hitNormalLocal:Vector3f, hitPointLocal:Vector3f, hitFraction:Float, partId:Int,  triangleIndex:Int):Float
	{
		var shapeInfo:LocalShapeInfo = new LocalShapeInfo();
		shapeInfo.shapePart = partId;
		shapeInfo.triangleIndex = triangleIndex;
		if (hitFraction <= resultCallback.closestHitFraction)
		{
			var convexResult:LocalConvexResult = new LocalConvexResult(collisionObject, shapeInfo, hitNormalLocal, hitPointLocal, hitFraction);
			return resultCallback.addSingleResult(convexResult, normalInWorldSpace);
		}
		return hitFraction;
	}
}

/**
 * LocalShapeInfo gives extra information for complex shapes.
 * Currently, only btTriangleMeshShape is available, so it just contains triangleIndex and subpart.
 */
class LocalShapeInfo
{
	public var shapePart:Int;
	public var triangleIndex:Int;
	//const btCollisionShape*	m_shapeTemp;
	//const btTransform*	m_shapeLocalTransform;
	
	public function new()
	{
		
	}
}

class LocalRayResult
{
	public var collisionObject:CollisionObject;
	public var localShapeInfo:LocalShapeInfo;
	public var hitNormalLocal:Vector3f = new Vector3f();
	public var hitFraction:Float;

	public function new(collisionObject:CollisionObject, localShapeInfo:LocalShapeInfo, hitNormalLocal:Vector3f,  hitFraction:Float)
	{
		this.collisionObject = collisionObject;
		this.localShapeInfo = localShapeInfo;
		this.hitNormalLocal.copyFrom(hitNormalLocal);
		this.hitFraction = hitFraction;
	}
}

/**
 * RayResultCallback is used to report new raycast results.
 */
class RayResultCallback 
{
	public var closestHitFraction:Float = 1;
	public var collisionObject:CollisionObject;
	public var collisionFilterGroup:Int = CollisionFilterGroups.DEFAULT_FILTER;
	public var collisionFilterMask:Int = CollisionFilterGroups.ALL_FILTER;
	
	public function new()
	{
		
	}

	public function hasHit():Bool
	{
		return (collisionObject != null);
	}

	public function needsCollision(proxy0:BroadphaseProxy):Bool
	{
		var collides:Bool = ((proxy0.collisionFilterGroup & collisionFilterMask) & 0xFFFF) != 0;
		collides = collides && ((collisionFilterGroup & proxy0.collisionFilterMask) & 0xFFFF) != 0;
		return collides;
	}

	public function addSingleResult(rayResult:LocalRayResult, normalInWorldSpace:Bool):Float
	{
		return 0;
	}
}

class ClosestRayResultCallback extends RayResultCallback 
{
	public var rayFromWorld:Vector3f = new Vector3f(); //used to calculate hitPointWorld from hitFraction
	public var rayToWorld:Vector3f = new Vector3f();

	public var hitNormalWorld:Vector3f = new Vector3f();
	public var hitPointWorld:Vector3f = new Vector3f();

	public function new(rayFromWorld:Vector3f, rayToWorld:Vector3f) 
	{
		super();
		this.rayFromWorld.copyFrom(rayFromWorld);
		this.rayToWorld.copyFrom(rayToWorld);
	}
	
	override public function addSingleResult(rayResult:LocalRayResult, normalInWorldSpace:Bool):Float  
	{
		// caller already does the filter on the closestHitFraction
		Assert.assert (rayResult.hitFraction <= closestHitFraction);

		closestHitFraction = rayResult.hitFraction;
		collisionObject = rayResult.collisionObject;
		if (normalInWorldSpace) 
		{
			hitNormalWorld.copyFrom(rayResult.hitNormalLocal);
		} 
		else 
		{
			// need to transform normal into worldspace
			hitNormalWorld.copyFrom(rayResult.hitNormalLocal);
			collisionObject.getWorldTransform().basis.multVecLocal(hitNormalWorld);
		}

		LinearMathUtil.setInterpolate3(hitPointWorld, rayFromWorld, rayToWorld, rayResult.hitFraction);
		return rayResult.hitFraction;
	}
}

class ClosestRayResultWithUserDataCallback extends RayResultCallback 
{
	public var rayFromWorld:Vector3f = new Vector3f(); //used to calculate hitPointWorld from hitFraction
	public var rayToWorld:Vector3f = new Vector3f();

	public var hitNormalWorld:Vector3f = new Vector3f();
	public var hitPointWorld:Vector3f = new Vector3f();

	public var userData:Dynamic = null;

	public function new(rayFromWorld:Vector3f, rayToWorld:Vector3f)
	{
		super();
		this.rayFromWorld.copyFrom(rayFromWorld);
		this.rayToWorld.copyFrom(rayToWorld);
	}
	
	override public function addSingleResult(rayResult:LocalRayResult, normalInWorldSpace:Bool):Float 
	{
		// caller already does the filter on the closestHitFraction
		Assert.assert (rayResult.hitFraction <= closestHitFraction);

		closestHitFraction = rayResult.hitFraction;
		collisionObject = rayResult.collisionObject;
		userData = collisionObject.getUserPointer();
		if (normalInWorldSpace) {
			hitNormalWorld.copyFrom(rayResult.hitNormalLocal);
		} else {
			// need to transform normal into worldspace
			hitNormalWorld.copyFrom(rayResult.hitNormalLocal);
			collisionObject.getWorldTransform().basis.multVecLocal(hitNormalWorld);
		}

		LinearMathUtil.setInterpolate3(hitPointWorld, rayFromWorld, rayToWorld, rayResult.hitFraction);
		return rayResult.hitFraction;
	}
}

class LocalConvexResult 
{
	public var hitCollisionObject:CollisionObject;
	public var localShapeInfo:LocalShapeInfo;
	public var hitNormalLocal:Vector3f = new Vector3f();
	public var hitPointLocal:Vector3f = new Vector3f();
	public var hitFraction:Float;

	public function new(hitCollisionObject:CollisionObject, localShapeInfo:LocalShapeInfo, hitNormalLocal:Vector3f, hitPointLocal:Vector3f, hitFraction:Float)
	{
		this.hitCollisionObject = hitCollisionObject;
		this.localShapeInfo = localShapeInfo;
		this.hitNormalLocal.copyFrom(hitNormalLocal);
		this.hitPointLocal.copyFrom(hitPointLocal);
		this.hitFraction = hitFraction;
	}
}

class ConvexResultCallback 
{
	public var closestHitFraction:Float = 1;
	public var collisionFilterGroup:Int = CollisionFilterGroups.DEFAULT_FILTER;
	public var collisionFilterMask:Int = CollisionFilterGroups.ALL_FILTER;
	
	public function new()
	{
		
	}

	public function hasHit():Bool 
	{
		return (closestHitFraction < 1);
	}

	public function needsCollision(proxy0:BroadphaseProxy):Bool
	{
		var collides:Bool = ((proxy0.collisionFilterGroup & collisionFilterMask) & 0xFFFF) != 0;
		collides = collides && ((collisionFilterGroup & proxy0.collisionFilterMask) & 0xFFFF) != 0;
		return collides;
	}

	public function addSingleResult(convexResult:LocalConvexResult, normalInWorldSpace:Bool):Float
	{
		return 0;
	}
}

class ClosestConvexResultCallback extends ConvexResultCallback
{
	public var convexFromWorld:Vector3f = new Vector3f(); // used to calculate hitPointWorld from hitFraction
	public var convexToWorld:Vector3f = new Vector3f();
	public var hitNormalWorld:Vector3f = new Vector3f();
	public var hitPointWorld:Vector3f = new Vector3f();
	public var hitCollisionObject:CollisionObject;

	public function new(convexFromWorld:Vector3f, convexToWorld:Vector3f)
	{
		super();
		this.convexFromWorld.copyFrom(convexFromWorld);
		this.convexToWorld.copyFrom(convexToWorld);
		this.hitCollisionObject = null;
	}
	
	override public function addSingleResult(convexResult:LocalConvexResult, normalInWorldSpace:Bool):Float 
	{
		// caller already does the filter on the m_closestHitFraction
		Assert.assert (convexResult.hitFraction <= closestHitFraction);

		closestHitFraction = convexResult.hitFraction;
		hitCollisionObject = convexResult.hitCollisionObject;
		if (normalInWorldSpace) 
		{
			hitNormalWorld.copyFrom(convexResult.hitNormalLocal);
			if (hitNormalWorld.length > 2) 
			{
				trace("CollisionWorld.addSingleResult world " + hitNormalWorld);
			}
		} 
		else 
		{
			// need to transform normal into worldspace
			hitNormalWorld.copyFrom(convexResult.hitNormalLocal);
			hitCollisionObject.getWorldTransform().basis.multVecLocal(hitNormalWorld);
			if (hitNormalWorld.length > 2)
			{
				trace("CollisionWorld.addSingleResult world " + hitNormalWorld);
			}
		}

		hitPointWorld.copyFrom(convexResult.hitPointLocal);
		return convexResult.hitFraction;
	}
}

class BridgeTriangleRaycastCallback extends TriangleRaycastCallback
{
	public var resultCallback:RayResultCallback;
	public var collisionObject:CollisionObject;
	public var triangleMesh:ConcaveShape;

	public function new(from:Vector3f, to:Vector3f, resultCallback:RayResultCallback, collisionObject:CollisionObject, triangleMesh:ConcaveShape)
	{
		super(from, to);
		this.resultCallback = resultCallback;
		this.collisionObject = collisionObject;
		this.triangleMesh = triangleMesh;
	}

	override public function reportHit(hitNormalLocal:Vector3f, hitFraction:Float, partId:Int, triangleIndex:Int):Float
	{
		var shapeInfo:LocalShapeInfo = new LocalShapeInfo();
		shapeInfo.shapePart = partId;
		shapeInfo.triangleIndex = triangleIndex;

		var rayResult:LocalRayResult = new LocalRayResult(collisionObject, shapeInfo, hitNormalLocal, hitFraction);

		var normalInWorldSpace:Bool = false;
		return resultCallback.addSingleResult(rayResult, normalInWorldSpace);
	}
}