package com.bulletphysics.collision.narrowphase;
import com.bulletphysics.collision.narrowphase.CastResult;
import com.bulletphysics.collision.shapes.ConvexShape;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.VectorUtil;
import com.vecmath.MatrixUtil;
import com.vecmath.Vector3f;

/**
 * SubsimplexConvexCast implements Gino van den Bergens' paper
 * "Ray Casting against bteral Convex Objects with Application to Continuous Collision Detection"
 * GJK based Ray Cast, optimized version
 * Objects should not start in overlap, otherwise results are not defined.
 * 
 * @author weilichuang
 */
class SubsimplexConvexCast extends ConvexCast
{

	private static inline var MAX_ITERATIONS:Int = 32;

    private var simplexSolver:SimplexSolverInterface;
    private var convexA:ConvexShape;
    private var convexB:ConvexShape;

    public function new(shapeA:ConvexShape, shapeB:ConvexShape, simplexSolver:SimplexSolverInterface)
	{
		super();
        this.convexA = shapeA;
        this.convexB = shapeB;
        this.simplexSolver = simplexSolver;
    }

    override public function calcTimeOfImpact(fromA:Transform, toA:Transform, fromB:Transform, toB:Transform, result:CastResult):Bool
	{
        var tmp:Vector3f = new Vector3f();

        simplexSolver.reset();

        var linVelA:Vector3f = new Vector3f();
        var linVelB:Vector3f = new Vector3f();
        linVelA.sub(toA.origin, fromA.origin);
        linVelB.sub(toB.origin, fromB.origin);

        var lambda:Float = 0;

        var interpolatedTransA:Transform = fromA.clone();
        var interpolatedTransB:Transform = fromB.clone();

        // take relative motion
        var r:Vector3f = new Vector3f();
        r.sub(linVelA, linVelB);

        var v:Vector3f = new Vector3f();

        tmp.negate(r);
        MatrixUtil.transposeTransform(tmp, tmp, fromA.basis);
        var supVertexA:Vector3f = convexA.localGetSupportingVertex(tmp, new Vector3f());
        fromA.transform(supVertexA);

        MatrixUtil.transposeTransform(tmp, r, fromB.basis);
        var supVertexB:Vector3f = convexB.localGetSupportingVertex(tmp, new Vector3f());
        fromB.transform(supVertexB);

        v.sub(supVertexA, supVertexB);

        var maxIter:Int = MAX_ITERATIONS;

        var n:Vector3f = new Vector3f();
        n.setTo(0, 0, 0);
        var hasResult:Bool = false;
        var c:Vector3f = new Vector3f();

        var lastLambda:Float = lambda;

        var dist2:Float = v.lengthSquared();
        //#ifdef BT_USE_DOUBLE_PRECISION
        //	btScalar epsilon = btScalar(0.0001);
        //#else
        var epsilon:Float = 0.0001;
        //#endif
        var w:Vector3f = new Vector3f();
		var p:Vector3f = new Vector3f();
        var VdotR:Float;

        while ((dist2 > epsilon) && (maxIter--) != 0)
		{
            tmp.negate(v);
            MatrixUtil.transposeTransform(tmp, tmp, interpolatedTransA.basis);
            convexA.localGetSupportingVertex(tmp, supVertexA);
            interpolatedTransA.transform(supVertexA);

            MatrixUtil.transposeTransform(tmp, v, interpolatedTransB.basis);
            convexB.localGetSupportingVertex(tmp, supVertexB);
            interpolatedTransB.transform(supVertexB);

            w.sub(supVertexA, supVertexB);

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
                    VectorUtil.setInterpolate3(interpolatedTransA.origin, fromA.origin, toA.origin, lambda);
                    VectorUtil.setInterpolate3(interpolatedTransB.origin, fromB.origin, toB.origin, lambda);
                    //m_simplexSolver->reset();
                    // check next line
                    w.sub(supVertexA, supVertexB);
                    lastLambda = lambda;
                    n.fromVector3f(v);
                    hasResult = true;
                }
            }
            simplexSolver.addVertex(w, supVertexA, supVertexB);
            if (simplexSolver.closest(v))
			{
                dist2 = v.lengthSquared();
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
        if (n.lengthSquared() >= BulletGlobals.SIMD_EPSILON * BulletGlobals.SIMD_EPSILON)
		{
			result.normal.fromVector3f(n);
            result.normal.normalize();
        } 
		else {
            result.normal.setTo(0, 0, 0);
        }

        // don't report time of impact for motion away from the contact normal (or causes minor penetration)
        if (result.normal.dot(r) >= -result.allowedPenetration)
            return false;

        var hitA:Vector3f = new Vector3f();
        var hitB:Vector3f = new Vector3f();
        simplexSolver.compute_points(hitA, hitB);
        result.hitPoint.fromVector3f(hitB);
        return true;
    }
	
}