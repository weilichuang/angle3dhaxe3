package com.bulletphysics.collision.narrowphase;
import com.bulletphysics.collision.narrowphase.CastResult;
import com.bulletphysics.collision.shapes.ConvexShape;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.LinearMathUtil;
import com.bulletphysics.linearmath.MatrixUtil;
import com.vecmath.Vector3f;

/**
 * SubsimplexConvexCast implements Gino van den Bergens' paper
 * "Ray Casting against bteral Convex Objects with Application to Continuous Collision Detection"
 * GJK based Ray Cast, optimized version
 * Objects should not start in overlap, otherwise results are not defined.
 * 
 * @author weilichuang
 */
class SubsimplexConvexCast implements ConvexCast
{

	private static inline var MAX_ITERATIONS:Int = 32;

    private var simplexSolver:SimplexSolverInterface;
    private var convexA:ConvexShape;
    private var convexB:ConvexShape;

    public function new()
	{
    }
	
	public function init(shapeA:ConvexShape, shapeB:ConvexShape, simplexSolver:SimplexSolverInterface):Void
	{
		this.convexA = shapeA;
        this.convexB = shapeB;
        this.simplexSolver = simplexSolver;
	}

	private var tmp:Vector3f = new Vector3f();
	private var linVelA:Vector3f = new Vector3f();
	private var linVelB:Vector3f = new Vector3f();
	private var interpolatedTransA:Transform = new Transform();
	private var interpolatedTransB:Transform = new Transform();
	private var r:Vector3f = new Vector3f();
	private var v:Vector3f = new Vector3f();
	private var supVertexA:Vector3f = new Vector3f();
	private var supVertexB:Vector3f = new Vector3f();
	private var n:Vector3f = new Vector3f();
	//private var c:Vector3f = new Vector3f();
	private var hitA:Vector3f = new Vector3f();
	private var hitB:Vector3f = new Vector3f();
	private var w:Vector3f = new Vector3f();
	private var p:Vector3f = new Vector3f();
    public function calcTimeOfImpact(fromA:Transform, toA:Transform, fromB:Transform, toB:Transform, result:CastResult):Bool
	{
        simplexSolver.reset();

        linVelA.sub2(toA.origin, fromA.origin);
        linVelB.sub2(toB.origin, fromB.origin);

        var lambda:Float = 0;

        interpolatedTransA.fromTransform(fromA);
        interpolatedTransB.fromTransform(fromB);

        // take relative motion
        r.sub2(linVelA, linVelB);

        tmp.negateBy(r);
        MatrixUtil.transposeTransform(tmp, tmp, fromA.basis);
        supVertexA = convexA.localGetSupportingVertex(tmp, supVertexA);
        fromA.transform(supVertexA);

        MatrixUtil.transposeTransform(tmp, r, fromB.basis);
        supVertexB = convexB.localGetSupportingVertex(tmp, supVertexB);
        fromB.transform(supVertexB);

        v.sub2(supVertexA, supVertexB);

        var maxIter:Int = MAX_ITERATIONS;

        n.setTo(0, 0, 0);
        var hasResult:Bool = false;
        
        var lastLambda:Float = lambda;

        var dist2:Float = v.lengthSquared;
        //#ifdef BT_USE_DOUBLE_PRECISION
        //	btScalar epsilon = btScalar(0.0001);
        //#else
        var epsilon:Float = 0.0001;
        //#endif
        
        var VdotR:Float;

        while ((dist2 > epsilon) && (maxIter--) != 0)
		{
            tmp.negateBy(v);
            MatrixUtil.transposeTransform(tmp, tmp, interpolatedTransA.basis);
            convexA.localGetSupportingVertex(tmp, supVertexA);
            interpolatedTransA.transform(supVertexA);

            MatrixUtil.transposeTransform(tmp, v, interpolatedTransB.basis);
            convexB.localGetSupportingVertex(tmp, supVertexB);
            interpolatedTransB.transform(supVertexB);

            w.sub2(supVertexA, supVertexB);

            var VdotW:Float = v.dot(w);

            if (lambda > 1)
			{
                return false;
            }

            if (VdotW > 0) 
			{
                VdotR = v.dot(r);

                if (VdotR >= -(BulletGlobals.FLT_EPSILON * BulletGlobals.FLT_EPSILON)) 
				{
                    return false;
                }
				else 
				{
                    lambda = lambda - VdotW / VdotR;

                    // interpolate to next lambda
                    //	x = s + lambda * r;
                    LinearMathUtil.setInterpolate3(interpolatedTransA.origin, fromA.origin, toA.origin, lambda);
                    LinearMathUtil.setInterpolate3(interpolatedTransB.origin, fromB.origin, toB.origin, lambda);
                    //m_simplexSolver->reset();
                    // check next line
                    w.sub2(supVertexA, supVertexB);
                    lastLambda = lambda;
                    n.copyFrom(v);
                    hasResult = true;
                }
            }
            simplexSolver.addVertex(w, supVertexA, supVertexB);
            if (simplexSolver.closest(v))
			{
                dist2 = v.lengthSquared;
                hasResult = true;
                // todo: check this normal for validity
                //n.set(v);
                //printf("V=%f , %f, %f\n",v[0],v[1],v[2]);
                //printf("DIST2=%f\n",dist2);
                //printf("numverts = %i\n",m_simplexSolver->numVertices());
            } 
			else
			{
                dist2 = 0;
            }
        }

        //int numiter = MAX_ITERATIONS - maxIter;
        //	printf("number of iterations: %d", numiter);

        // don't report a time of impact when moving 'away' from the hitnormal

        result.fraction = lambda;
        if (n.lengthSquared >= BulletGlobals.SIMD_EPSILON * BulletGlobals.SIMD_EPSILON)
		{
			result.normal.copyFrom(n);
            result.normal.normalize();
        } 
		else
		{
            result.normal.setTo(0, 0, 0);
        }

        // don't report time of impact for motion away from the contact normal (or causes minor penetration)
        if (result.normal.dot(r) >= -result.allowedPenetration)
            return false;

        simplexSolver.compute_points(hitA, hitB);
        result.hitPoint.copyFrom(hitB);
        return true;
    }
	
}