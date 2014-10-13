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
class GjkConvexCast extends ConvexCast
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
		super();
        this.simplexSolver = simplexSolver;
        this.convexA = convexA;
        this.convexB = convexB;
    }

    // Note: Incorporates this fix http://code.google.com/p/bullet/source/detail?r=2362
    // But doesn't add in angular velocity
    override public function calcTimeOfImpact(fromA:Transform, toA:Transform, fromB:Transform, toB:Transform, result:CastResult):Bool
	{
        simplexSolver.reset();

        // compute linear velocity for this interval, to interpolate
        // assume no rotation/angular velocity, assert here?
        var linVelA:Vector3f = new Vector3f();
        var linVelB:Vector3f = new Vector3f();

        linVelA.sub(toA.origin, fromA.origin);
        linVelB.sub(toB.origin, fromB.origin);

        var relLinVel:Vector3f = new Vector3f();
        relLinVel.sub(linVelB, linVelA);
        var relLinVelocLength:Float = relLinVel.length();
        if (relLinVelocLength == 0)
		{
            return false;
        }

        var lambda:Float = 0;
        var v:Vector3f = new Vector3f();
        v.setTo(1, 0, 0);

        var maxIter:Int = MAX_ITERATIONS;

        var n:Vector3f = new Vector3f();
        n.setTo(0, 0, 0);
        var hasResult:Bool = false;
        var c:Vector3f = new Vector3f();

        var lastLambda:Float = lambda;
        //btScalar epsilon = btScalar(0.001);

        var numIter:Int = 0;
        // first solution, using GJK

        var identityTrans:Transform = new Transform();
        identityTrans.setIdentity();

        //result.drawCoordSystem(sphereTr);

        var pointCollector:PointCollector = new PointCollector();

        gjk.init(convexA, convexB, simplexSolver, null); // penetrationDepthSolver);
		
        var input:ClosestPointInput = new ClosestPointInput();
        input.init();

		input.transformA.fromTransform(fromA);
		input.transformB.fromTransform(fromB);
		gjk.getClosestPoints(input, pointCollector, null);

		hasResult = pointCollector.hasResult;
		c.fromVector3f(pointCollector.pointInWorld);

		if (hasResult) 
		{
			var dist:Float;
			dist = pointCollector.distance + result.allowedPenetration;
			n.fromVector3f(pointCollector.normalOnBInWorld);

			var projectedLinearVelocity:Float = relLinVel.dot(n);
			if ((projectedLinearVelocity) <= BulletGlobals.SIMD_EPSILON)
			{
				return false;
			}

			// not close enough
			while (dist > BulletGlobals.SIMD_EPSILON)
			{
				/*numIter++;
				if (numIter > maxIter) {
					return false; // todo: report a failure
				} */
				var dLambda:Float = 0;

				projectedLinearVelocity = relLinVel.dot(n);

				if ((projectedLinearVelocity) <= BulletGlobals.SIMD_EPSILON)
				{
					return false;
				}

				dLambda = dist / (projectedLinearVelocity);

				lambda = lambda + dLambda;

				if (lambda > 1)
				{
					return false;
				}
				if (lambda < 0) 
				{
					return false;                    // todo: next check with relative epsilon
				}

				if (lambda <= lastLambda) 
				{
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
					dist = pointCollector.distance + result.allowedPenetration;
					c.fromVector3f(pointCollector.pointInWorld);
					n.fromVector3f(pointCollector.normalOnBInWorld);
				} 
				else 
				{
					// ??
					return false;
				}
				numIter++;
				if (numIter > maxIter)
				{
					return false;
				}

			}

			result.fraction = lambda;
			result.normal.fromVector3f(n);
			result.hitPoint.fromVector3f(c);
			return true;
		}

		return false;
    }
	
}