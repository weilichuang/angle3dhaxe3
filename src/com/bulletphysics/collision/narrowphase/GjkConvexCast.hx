package com.bulletphysics.collision.narrowphase;
import com.bulletphysics.collision.narrowphase.CastResult;
import com.bulletphysics.collision.narrowphase.DiscreteCollisionDetectorInterface.ClosestPointInput;
import com.bulletphysics.collision.shapes.ConvexShape;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.VectorUtil;
import com.bulletphysics.util.ObjectPool;
import vecmath.Vector3f;

/**
 * GjkConvexCast performs a raycast on a convex object using support mapping.
 * @author weilichuang
 */
class GjkConvexCast implements ConvexCast
{

	private var pointInputsPool:ObjectPool<ClosestPointInput> = ObjectPool.getPool(ClosestPointInput);

    //#ifdef BT_USE_DOUBLE_PRECISION
//	private static final int MAX_ITERATIONS = 64;
//#else
    private static inline var MAX_ITERATIONS:Int = 32;
//#endif

    private var simplexSolver:SimplexSolverInterface;
    private var convexA:ConvexShape;
    private var convexB:ConvexShape;

    private var gjk:GjkPairDetector = new GjkPairDetector();

    public function new(convexA:ConvexShape, convexB:ConvexShape, simplexSolver:SimplexSolverInterface)
	{
        this.simplexSolver = simplexSolver;
        this.convexA = convexA;
        this.convexB = convexB;
    }

    // Note: Incorporates this fix http://code.google.com/p/bullet/source/detail?r=2362
    // But doesn't add in angular velocity
    public function calcTimeOfImpact(fromA:Transform, toA:Transform, fromB:Transform, toB:Transform, result:CastResult):Bool
	{
        simplexSolver.reset();

        // compute linear velocity for this interval, to interpolate
        // assume no rotation/angular velocity, assert here?
        var linVelA:Vector3f = new Vector3f();
        var linVelB:Vector3f = new Vector3f();

        linVelA.sub2(toA.origin, fromA.origin);
        linVelB.sub2(toB.origin, fromB.origin);

        var radius:Float = 0.001;
        var lambda:Float = 0;
        var v:Vector3f = new Vector3f(1,0,0);
        var maxIter:Int = MAX_ITERATIONS;

        var n:Vector3f = new Vector3f(0,0,0);

        var hasResult:Bool = false;
        var c:Vector3f = new Vector3f();
        var r:Vector3f = new Vector3f();
        r.sub2(linVelA,linVelB);

        var lastLambda:Float = lambda;
        //btScalar epsilon = btScalar(0.001);

        var numIter:Int = 0;
        // first solution, using GJK

        var identityTrans:Transform = new Transform();
        identityTrans.setIdentity();

        //result.drawCoordSystem(sphereTr);

        var pointCollector:PointCollector = new PointCollector();

        gjk.init(convexA, convexB, simplexSolver, null); // penetrationDepthSolver);
		
        var input:ClosestPointInput = pointInputsPool.get();
        input.init();

        // we don't use margins during CCD
		//	gjk.setIgnoreMargin(true);

		input.transformA.fromTransform(fromA);
		input.transformB.fromTransform(fromB);
		gjk.getClosestPoints(input, pointCollector, null);

		hasResult = pointCollector.hasResult;
		c.fromVector3f(pointCollector.pointInWorld);

		if (hasResult) 
		{
			var dist:Float;
			dist = pointCollector.distance;
			n.fromVector3f(pointCollector.normalOnBInWorld);

			// not close enough
			while (dist > radius)
			{
				numIter++;
				if (numIter > maxIter) 
				{
					pointInputsPool.release(input);
					return false; // todo: report a failure
				} 

				var dLambda:Float = 0;

				var projectedLinearVelocity:Float = r.dot(n);

				dLambda = dist / (projectedLinearVelocity);

				lambda = lambda - dLambda;

				if (lambda > 1)
				{
					pointInputsPool.release(input);
					return false;
				}
				if (lambda < 0) 
				{
					pointInputsPool.release(input);
					return false;                    // todo: next check with relative epsilon
				}

				if (lambda <= lastLambda) 
				{
					pointInputsPool.release(input);
					return false;
				}
				lastLambda = lambda;

				// interpolate to next lambda
				result.debugDraw(lambda);
				VectorUtil.setInterpolate3(input.transformA.origin, fromA.origin, toA.origin, lambda);
				VectorUtil.setInterpolate3(input.transformB.origin, fromB.origin, toB.origin, lambda);

				gjk.getClosestPoints(input, pointCollector, null);
				if (pointCollector.hasResult)
				{
					if (pointCollector.distance < 0) 
					{
						result.fraction = lastLambda;
						n.fromVector3f(pointCollector.normalOnBInWorld);
						result.normal.fromVector3f(n);
						result.hitPoint.fromVector3f(pointCollector.pointInWorld);

						pointInputsPool.release(input);
						return true;
					}
					c.fromVector3f(pointCollector.pointInWorld);
					n.fromVector3f(pointCollector.normalOnBInWorld);
					dist = pointCollector.distance;
				} 
				else 
				{
					// ??
					pointInputsPool.release(input);
					return false;
				}
				numIter++;
				if (numIter > maxIter)
				{
					pointInputsPool.release(input);
					return false;
				}

			}

			// is n normalized?
			// don't report time of impact for motion away from the contact normal (or causes minor penetration)
			if (n.dot(r) >= -result.allowedPenetration) 
			{
				pointInputsPool.release(input);
				return false;
			}
			result.fraction = lambda;
			result.normal.fromVector3f(n);
			result.hitPoint.fromVector3f(c);

			pointInputsPool.release(input);
			return true;
		}

		pointInputsPool.release(input);
		return false;
    }
	
}