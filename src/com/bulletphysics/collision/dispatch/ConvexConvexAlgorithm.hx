package com.bulletphysics.collision.dispatch;
import com.bulletphysics.collision.broadphase.CollisionAlgorithm;
import com.bulletphysics.collision.broadphase.CollisionAlgorithmConstructionInfo;
import com.bulletphysics.collision.broadphase.DispatcherInfo;
import com.bulletphysics.collision.dispatch.CollisionObject;
import com.bulletphysics.collision.dispatch.ManifoldResult;
import com.bulletphysics.collision.narrowphase.CastResult;
import com.bulletphysics.collision.narrowphase.ConvexPenetrationDepthSolver;
import com.bulletphysics.collision.narrowphase.DiscreteCollisionDetectorInterface.ClosestPointInput;
import com.bulletphysics.collision.narrowphase.GjkConvexCast;
import com.bulletphysics.collision.narrowphase.GjkPairDetector;
import com.bulletphysics.collision.narrowphase.PersistentManifold;
import com.bulletphysics.collision.narrowphase.SimplexSolverInterface;
import com.bulletphysics.collision.narrowphase.VoronoiSimplexSolver;
import com.bulletphysics.collision.shapes.ConvexShape;
import com.bulletphysics.collision.shapes.SphereShape;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.util.ObjectArrayList;
import com.bulletphysics.util.ObjectPool;
import org.angle3d.math.Vector3f;

/**
 * ConvexConvexAlgorithm collision algorithm implements time of impact, convex
 * closest points and penetration depth calculations.
 
 */
class ConvexConvexAlgorithm extends CollisionAlgorithm
{
	public var ownManifold:Bool;
    public var manifoldPtr:PersistentManifold;
    public var lowLevelOfDetail:Bool;
	
	private var pointInputsPool:ObjectPool<ClosestPointInput> = ObjectPool.getPool(ClosestPointInput);
	
	private var gjkPairDetector:GjkPairDetector = new GjkPairDetector();
	
	private static var disableCcd:Bool = false;

	public function new() 
	{
		super();
	}
	
	
	
	public function init(mf:PersistentManifold, ci:CollisionAlgorithmConstructionInfo, body0:CollisionObject, body1:CollisionObject, simplexSolver:SimplexSolverInterface, pdSolver:ConvexPenetrationDepthSolver):Void 
	{
		this.setConstructionInfo(ci);
		gjkPairDetector.init(null, null, simplexSolver, pdSolver);
        this.manifoldPtr = mf;
        this.ownManifold = false;
        this.lowLevelOfDetail = false;
	}
	
	override public function destroy():Void 
	{
		if (ownManifold)
		{
            if (manifoldPtr != null)
			{
                dispatcher.releaseManifold(manifoldPtr);
            }
            manifoldPtr = null;
        }
	}

    public function setLowLevelOfDetail(useLowLevel:Bool):Void
	{
        this.lowLevelOfDetail = useLowLevel;
    }
	
	/**
     * Convex-Convex collision algorithm.
     */
	override public function processCollision(body0:CollisionObject, body1:CollisionObject, dispatchInfo:DispatcherInfo, resultOut:ManifoldResult):Void 
	{
		if (manifoldPtr == null) 
		{
            // swapped?
            manifoldPtr = dispatcher.getNewManifold(body0, body1);
            ownManifold = true;
        }
        resultOut.setPersistentManifold(manifoldPtr);

//	#ifdef USE_BT_GJKEPA
//		btConvexShape*				shape0(static_cast<btConvexShape*>(body0->getCollisionShape()));
//		btConvexShape*				shape1(static_cast<btConvexShape*>(body1->getCollisionShape()));
//		const btScalar				radialmargin(0/*shape0->getMargin()+shape1->getMargin()*/);
//		btGjkEpaSolver::sResults	results;
//		if(btGjkEpaSolver::Collide(	shape0,body0->getWorldTransform(),
//									shape1,body1->getWorldTransform(),
//									radialmargin,results))
//			{
//			dispatchInfo.m_debugDraw->drawLine(results.witnesses[1],results.witnesses[1]+results.normal,btVector3(255,0,0));
//			resultOut->addContactPoint(results.normal,results.witnesses[1],-results.depth);
//			}
//	#else

        var min0:ConvexShape = cast body0.getCollisionShape();
        var min1:ConvexShape = cast body1.getCollisionShape();

        var input:ClosestPointInput = pointInputsPool.get();
        input.init();

        // JAVA NOTE: original: TODO: if (dispatchInfo.m_useContinuous)
        gjkPairDetector.setMinkowskiA(min0);
        gjkPairDetector.setMinkowskiB(min1);
        input.maximumDistanceSquared = min0.getMargin() + min1.getMargin() + manifoldPtr.getContactBreakingThreshold();
        input.maximumDistanceSquared *= input.maximumDistanceSquared;
        //input.m_stackAlloc = dispatchInfo.m_stackAllocator;

        //	input.m_maximumDistanceSquared = btScalar(1e30);

        body0.getWorldTransformTo(input.transformA);
        body1.getWorldTransformTo(input.transformB);

        gjkPairDetector.getClosestPoints(input, resultOut, dispatchInfo.debugDraw);

        pointInputsPool.release(input);

        if (ownManifold)
		{
            resultOut.refreshContactPoints();
        }
	}

    
	
	override public function calculateTimeOfImpact(col0:CollisionObject, col1:CollisionObject, dispatchInfo:DispatcherInfo, resultOut:ManifoldResult):Float 
	{
		var tmp:Vector3f = new Vector3f();

		//var tmpTrans1:Transform = new Transform();
        //var tmpTrans2:Transform = new Transform();

        // Rather then checking ALL pairs, only calculate TOI when motion exceeds threshold

        // Linear motion for one of objects needs to exceed m_ccdSquareMotionThreshold
        // col0->m_worldTransform,
        var resultFraction:Float = 1;

        tmp.subtractBy(col0.getInterpolationWorldTransform().origin, col0.getWorldTransform().origin);
        var squareMot0:Float = tmp.lengthSquared;

        tmp.subtractBy(col1.getInterpolationWorldTransform().origin, col1.getWorldTransform().origin);
        var squareMot1:Float = tmp.lengthSquared;

        if (squareMot0 < col0.getCcdSquareMotionThreshold() &&
                squareMot1 < col1.getCcdSquareMotionThreshold())
		{
            return resultFraction;
        }

        if (disableCcd)
		{
            return 1;
        }

        // An adhoc way of testing the Continuous Collision Detection algorithms
        // One object is approximated as a sphere, to simplify things
        // Starting in penetration should report no time of impact
        // For proper CCD, better accuracy and handling of 'allowed' penetration should be added
        // also the mainloop of the physics should have a kind of toi queue (something like Brian Mirtich's application of Timewarp for Rigidbodies)

        // Convex0 against sphere for Convex1
        {
            var convex0:ConvexShape = cast col0.getCollisionShape();

            var sphere1:SphereShape = new SphereShape(col1.getCcdSweptSphereRadius()); // todo: allow non-zero sphere sizes, for better approximation
            var result:CastResult = new CastResult();
            var voronoiSimplex:VoronoiSimplexSolver = new VoronoiSimplexSolver();
            //SubsimplexConvexCast ccd0(&sphere,min0,&voronoiSimplex);
            ///Simplification, one object is simplified as a sphere
            var ccd1:GjkConvexCast = new GjkConvexCast(convex0, sphere1, voronoiSimplex);
            //ContinuousConvexCollision ccd(min0,min1,&voronoiSimplex,0);
            if (ccd1.calcTimeOfImpact(col0.getWorldTransform(), col0.getInterpolationWorldTransform(),
                    col1.getWorldTransform(), col1.getInterpolationWorldTransform(), result))
			{
                // store result.m_fraction in both bodies

                if (col0.getHitFraction() > result.fraction)
				{
                    col0.setHitFraction(result.fraction);
                }

                if (col1.getHitFraction() > result.fraction)
				{
                    col1.setHitFraction(result.fraction);
                }

                if (resultFraction > result.fraction) 
				{
                    resultFraction = result.fraction;
                }
            }
        }

        // Sphere (for convex0) against Convex1
        {
            var convex1:ConvexShape = cast col1.getCollisionShape();

            var sphere0:SphereShape = new SphereShape(col0.getCcdSweptSphereRadius()); // todo: allow non-zero sphere sizes, for better approximation
            var result:CastResult = new CastResult();
            var voronoiSimplex:VoronoiSimplexSolver = new VoronoiSimplexSolver();
            //SubsimplexConvexCast ccd0(&sphere,min0,&voronoiSimplex);
            ///Simplification, one object is simplified as a sphere
            var ccd1:GjkConvexCast = new GjkConvexCast(sphere0, convex1, voronoiSimplex);
            //ContinuousConvexCollision ccd(min0,min1,&voronoiSimplex,0);
            if (ccd1.calcTimeOfImpact(col0.getWorldTransform(), col0.getInterpolationWorldTransform(),
                    col1.getWorldTransform(), col1.getInterpolationWorldTransform(), result)) 
			{
                //store result.m_fraction in both bodies

                if (col0.getHitFraction() > result.fraction) 
				{
                    col0.setHitFraction(result.fraction);
                }

                if (col1.getHitFraction() > result.fraction)
				{
                    col1.setHitFraction(result.fraction);
                }

                if (resultFraction > result.fraction)
				{
                    resultFraction = result.fraction;
                }

            }
        }

        return resultFraction;
	}
	
	override public function getAllContactManifolds(manifoldArray:ObjectArrayList<PersistentManifold>):Void 
	{
		// should we use ownManifold to avoid adding duplicates?
        if (manifoldPtr != null && ownManifold) 
		{
            manifoldArray.add(manifoldPtr);
        }
	}

    public function getManifold():PersistentManifold
	{
        return manifoldPtr;
    }
	
}