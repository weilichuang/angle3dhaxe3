package com.bulletphysics.collision.dispatch;
import com.bulletphysics.collision.broadphase.CollisionAlgorithm;
import com.bulletphysics.collision.broadphase.CollisionAlgorithmConstructionInfo;
import com.bulletphysics.collision.broadphase.DispatcherInfo;
import com.bulletphysics.collision.dispatch.CollisionObject;
import com.bulletphysics.collision.dispatch.ManifoldResult;
import com.bulletphysics.collision.narrowphase.CastResult;
import com.bulletphysics.collision.narrowphase.PersistentManifold;
import com.bulletphysics.collision.narrowphase.SubsimplexConvexCast;
import com.bulletphysics.collision.narrowphase.VoronoiSimplexSolver;
import com.bulletphysics.collision.shapes.ConcaveShape;
import com.bulletphysics.collision.shapes.SphereShape;
import com.bulletphysics.collision.shapes.TriangleCallback;
import com.bulletphysics.collision.shapes.TriangleShape;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.VectorUtil;
import com.bulletphysics.util.ObjectArrayList;
import com.bulletphysics.util.ObjectPool;
import com.vecmath.Vector3f;


/**
 * ConvexConcaveCollisionAlgorithm supports collision between convex shapes
 * and (concave) trianges meshes.
 * @author weilichuang
 */
class ConvexConcaveCollisionAlgorithm extends CollisionAlgorithm
{
	private var isSwapped:Bool;
    private var btConvexTriangleCallback:ConvexTriangleCallback;

	public function new() 
	{
		super();
	}
	
    public function init(ci:CollisionAlgorithmConstructionInfo, body0:CollisionObject, body1:CollisionObject, isSwapped:Bool):Void
	{
        setConstructionInfo(ci);
        this.isSwapped = isSwapped;
        this.btConvexTriangleCallback = new ConvexTriangleCallback(dispatcher, body0, body1, isSwapped);
    }
	
	override public function destroy():Void 
	{
		btConvexTriangleCallback.destroy();
	}

	override public function processCollision(body0:CollisionObject, body1:CollisionObject, dispatchInfo:DispatcherInfo, resultOut:ManifoldResult):Void 
	{
		var convexBody:CollisionObject = isSwapped ? body1 : body0;
        var triBody:CollisionObject = isSwapped ? body0 : body1;

        if (triBody.getCollisionShape().isConcave()) {
            var triOb:CollisionObject = triBody;
            var concaveShape:ConcaveShape = cast triOb.getCollisionShape();

            if (convexBody.getCollisionShape().isConvex()) 
			{
                var collisionMarginTriangle:Float = concaveShape.getMargin();

                resultOut.setPersistentManifold(btConvexTriangleCallback.manifoldPtr);
                btConvexTriangleCallback.setTimeStepAndCounters(collisionMarginTriangle, dispatchInfo, resultOut);

                // Disable persistency. previously, some older algorithm calculated all contacts in one go, so you can clear it here.
                //m_dispatcher->clearManifold(m_btConvexTriangleCallback.m_manifoldPtr);

                btConvexTriangleCallback.manifoldPtr.setBodies(convexBody, triBody);

                concaveShape.processAllTriangles(
                        btConvexTriangleCallback,
                        btConvexTriangleCallback.getAabbMin(new Vector3f()),
                        btConvexTriangleCallback.getAabbMax(new Vector3f()));

                resultOut.refreshContactPoints();
            }
        }
	}
	
	override public function calculateTimeOfImpact(body0:CollisionObject, body1:CollisionObject, dispatchInfo:DispatcherInfo, resultOut:ManifoldResult):Float 
	{
		var tmp:Vector3f = new Vector3f();

        var convexbody:CollisionObject = isSwapped ? body1 : body0;
        var triBody:CollisionObject = isSwapped ? body0 : body1;

        // quick approximation using raycast, todo: hook up to the continuous collision detection (one of the btConvexCast)

        // only perform CCD above a certain threshold, this prevents blocking on the long run
        // because object in a blocked ccd state (hitfraction<1) get their linear velocity halved each frame...
        tmp.sub(convexbody.getInterpolationWorldTransform(new Transform()).origin, convexbody.getWorldTransform(new Transform()).origin);
        var squareMot0:Float = tmp.lengthSquared();
        if (squareMot0 < convexbody.getCcdSquareMotionThreshold())
		{
            return 1;
        }

        var tmpTrans:Transform = new Transform();

        //const btVector3& from = convexbody->m_worldTransform.getOrigin();
        //btVector3 to = convexbody->m_interpolationWorldTransform.getOrigin();
        //todo: only do if the motion exceeds the 'radius'

        var triInv:Transform = triBody.getWorldTransform(new Transform());
        triInv.inverse();

        var convexFromLocal:Transform = new Transform();
        convexFromLocal.mul(triInv, convexbody.getWorldTransform(tmpTrans));

        var convexToLocal:Transform = new Transform();
        convexToLocal.mul(triInv, convexbody.getInterpolationWorldTransform(tmpTrans));

        if (triBody.getCollisionShape().isConcave()) 
		{
            var rayAabbMin:Vector3f = convexFromLocal.origin.clone();
            VectorUtil.setMin(rayAabbMin, convexToLocal.origin);

            var rayAabbMax:Vector3f = convexFromLocal.origin.clone();
            VectorUtil.setMax(rayAabbMax, convexToLocal.origin);

            var ccdRadius0:Float = convexbody.getCcdSweptSphereRadius();

            tmp.setTo(ccdRadius0, ccdRadius0, ccdRadius0);
            rayAabbMin.sub(tmp);
            rayAabbMax.add(tmp);

            var curHitFraction:Float = 1; // is this available?
            var raycastCallback:LocalTriangleSphereCastCallback = new LocalTriangleSphereCastCallback(convexFromLocal, convexToLocal, convexbody.getCcdSweptSphereRadius(), curHitFraction);

            raycastCallback.hitFraction = convexbody.getHitFraction();

            var concavebody:CollisionObject = triBody;

            var triangleMesh:ConcaveShape = cast concavebody.getCollisionShape();

            if (triangleMesh != null)
			{
                triangleMesh.processAllTriangles(raycastCallback, rayAabbMin, rayAabbMax);
            }

            if (raycastCallback.hitFraction < convexbody.getHitFraction())
			{
                convexbody.setHitFraction(raycastCallback.hitFraction);
                return raycastCallback.hitFraction;
            }
        }

        return 1;
	}
	
	override public function getAllContactManifolds(manifoldArray:ObjectArrayList<PersistentManifold>):Void 
	{
		if (btConvexTriangleCallback.manifoldPtr != null) {
            manifoldArray.add(btConvexTriangleCallback.manifoldPtr);
        }
	}

    public function clearCache():Void
	{
        btConvexTriangleCallback.clearCache();
    }
}

//class CovexConcaveCreateFunc extends CollisionAlgorithmCreateFunc 
//{
	//private var pool:ObjectPool<ConvexConcaveCollisionAlgorithm> = ObjectPool.getPool(ConvexConcaveCollisionAlgorithm);
//
	//override public function createCollisionAlgorithm(ci:CollisionAlgorithmConstructionInfo, body0:CollisionObject, body1:CollisionObject):CollisionAlgorithm 
	//{
		//var algo:ConvexConcaveCollisionAlgorithm = pool.get();
		//algo.init2(ci, body0, body1, false);
		//return algo;
	//}
//
	//override public function releaseCollisionAlgorithm(algo:CollisionAlgorithm):Void 
	//{
		//pool.release(cast algo);
	//}
//}
//
//class CovexConcaveSwappedCreateFunc extends CollisionAlgorithmCreateFunc
//{
	//private var pool:ObjectPool<ConvexConcaveCollisionAlgorithm> = ObjectPool.getPool(ConvexConcaveCollisionAlgorithm);
	//
	//override public function createCollisionAlgorithm(ci:CollisionAlgorithmConstructionInfo, body0:CollisionObject, body1:CollisionObject):CollisionAlgorithm 
	//{
		//var algo:ConvexConcaveCollisionAlgorithm = pool.get();
		//algo.init2(ci, body0, body1, true);
		//return algo;
	//}
//
	//override public function releaseCollisionAlgorithm(algo:CollisionAlgorithm):Void 
	//{
		//pool.release(cast algo);
	//}
//}


class LocalTriangleSphereCastCallback extends TriangleCallback
{
	public var ccdSphereFromTrans:Transform = new Transform();
	public var ccdSphereToTrans:Transform = new Transform();
	public var meshTransform:Transform = new Transform();

	public var ccdSphereRadius:Float;
	public var hitFraction:Float;

	private var ident:Transform = new Transform();

	public function new(from:Transform, to:Transform, ccdSphereRadius:Float, hitFraction:Float)
	{
		super();
		
		this.ccdSphereFromTrans.fromTransform(from);
		this.ccdSphereToTrans.fromTransform(to);
		this.ccdSphereRadius = ccdSphereRadius;
		this.hitFraction = hitFraction;
	}
	
	override public function processTriangle(triangle:Array<Vector3f>, partId:Int, triangleIndex:Int):Void
	{
		// do a swept sphere for now

		//btTransform ident;
		//ident.setIdentity();

		var castResult:CastResult = new CastResult();
		castResult.fraction = hitFraction;
		var pointShape:SphereShape = new SphereShape(ccdSphereRadius);
		var triShape:TriangleShape = new TriangleShape();
		triShape.init(triangle[0], triangle[1], triangle[2]);
		var simplexSolver:VoronoiSimplexSolver = new VoronoiSimplexSolver();
		var convexCaster:SubsimplexConvexCast = new SubsimplexConvexCast(pointShape, triShape, simplexSolver);
		//GjkConvexCast	convexCaster(&pointShape,convexShape,&simplexSolver);
		//ContinuousConvexCollision convexCaster(&pointShape,convexShape,&simplexSolver,0);
		//local space?

		if (convexCaster.calcTimeOfImpact(ccdSphereFromTrans, ccdSphereToTrans, ident, ident, castResult)) 
		{
			if (hitFraction > castResult.fraction)
			{
				hitFraction = castResult.fraction;
			}
		}
	}
}