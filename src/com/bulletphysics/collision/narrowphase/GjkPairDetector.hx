package com.bulletphysics.collision.narrowphase;
import com.bulletphysics.collision.narrowphase.DiscreteCollisionDetectorInterface.ClosestPointInput;
import com.bulletphysics.collision.narrowphase.DiscreteCollisionDetectorInterface.Result;
import com.bulletphysics.collision.shapes.ConvexShape;
import com.bulletphysics.linearmath.IDebugDraw;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.util.Assert;
import com.vecmath.MatrixUtil;
import com.vecmath.Vector3f;

/**
 * GjkPairDetector uses GJK to implement the {@link DiscreteCollisionDetectorInterface}.
 * @author weilichuang
 */
class GjkPairDetector extends DiscreteCollisionDetectorInterface
{
	// must be above the machine epsilon
    private static inline var REL_ERROR2:Float = 1.0e-6;

    private var cachedSeparatingAxis:Vector3f = new Vector3f();
    private var penetrationDepthSolver:ConvexPenetrationDepthSolver;
    private var simplexSolver:SimplexSolverInterface;
    private var minkowskiA:ConvexShape;
    private var minkowskiB:ConvexShape;
    private var ignoreMargin:Bool;

    // some debugging to fix degeneracy problems
    public var lastUsedMethod:Int;
    public var curIter:Int;
    public var degenerateSimplex:Int;
    public var catchDegeneracies:Int;

    public function init( objectA:ConvexShape,  objectB:ConvexShape,  simplexSolver:SimplexSolverInterface,  penetrationDepthSolver:ConvexPenetrationDepthSolver)
	{
        this.cachedSeparatingAxis.setTo(0, 0, 1);
        this.ignoreMargin = false;
        this.lastUsedMethod = -1;
        this.catchDegeneracies = 1;

        this.penetrationDepthSolver = penetrationDepthSolver;
        this.simplexSolver = simplexSolver;
        this.minkowskiA = objectA;
        this.minkowskiB = objectB;
    }

    override public function getClosestPoints(input:ClosestPointInput, output:Result, debugDraw:IDebugDraw, swapResults:Bool = false):Void
	{
        var tmp:Vector3f = new Vector3f();

        var distance:Float = 0;
        var normalInB:Vector3f = new Vector3f();
        normalInB.setTo(0, 0, 0);
        var pointOnA:Vector3f = new Vector3f(), pointOnB = new Vector3f();
        var localTransA:Transform = input.transformA.clone();
        var localTransB:Transform = input.transformB.clone();
        var positionOffset:Vector3f = new Vector3f();
        positionOffset.add(localTransA.origin, localTransB.origin);
        positionOffset.scale(0.5);
        localTransA.origin.sub(positionOffset);
        localTransB.origin.sub(positionOffset);

        var marginA:Float = minkowskiA.getMargin();
        var marginB:Float = minkowskiB.getMargin();

        BulletStats.gNumGjkChecks++;

        // for CCD we don't use margins
        if (ignoreMargin)
		{
            marginA = 0;
            marginB = 0;
        }

        curIter = 0;
        var gGjkMaxIter:Int = 1000; // this is to catch invalid input, perhaps check for #NaN?
        cachedSeparatingAxis.setTo(0, 1, 0);

        var isValid:Bool = false;
        var checkSimplex:Bool = false;
        var checkPenetration:Bool = true;
        degenerateSimplex = 0;

        lastUsedMethod = -1;

        {
            var squaredDistance:Float = BulletGlobals.SIMD_INFINITY;
            var delta:Float = 0;

            var margin:Float = marginA + marginB;

            simplexSolver.reset();

            var seperatingAxisInA:Vector3f = new Vector3f();
            var seperatingAxisInB:Vector3f = new Vector3f();

            var pInA:Vector3f = new Vector3f();
            var qInB:Vector3f = new Vector3f();

            var pWorld:Vector3f = new Vector3f();
            var qWorld:Vector3f = new Vector3f();
            var w:Vector3f = new Vector3f();

            var tmpPointOnA:Vector3f = new Vector3f();
			var tmpPointOnB:Vector3f = new Vector3f();
            var tmpNormalInB:Vector3f = new Vector3f();

            while (true)
            {
                seperatingAxisInA.negate(cachedSeparatingAxis);
                MatrixUtil.transposeTransform(seperatingAxisInA, seperatingAxisInA, input.transformA.basis);

                seperatingAxisInB.fromVector3f(cachedSeparatingAxis);
                MatrixUtil.transposeTransform(seperatingAxisInB, seperatingAxisInB, input.transformB.basis);

                minkowskiA.localGetSupportingVertexWithoutMargin(seperatingAxisInA, pInA);
                minkowskiB.localGetSupportingVertexWithoutMargin(seperatingAxisInB, qInB);

                pWorld.fromVector3f(pInA);
                localTransA.transform(pWorld);

                qWorld.fromVector3f(qInB);
                localTransB.transform(qWorld);

                w.sub(pWorld, qWorld);

                delta = cachedSeparatingAxis.dot(w);

                // potential exit, they don't overlap
                if ((delta > 0) && (delta * delta > squaredDistance * input.maximumDistanceSquared))
				{
                    checkPenetration = false;
                    break;
                }

                // exit 0: the new point is already in the simplex, or we didn't come any closer
                if (simplexSolver.inSimplex(w)) 
				{
                    degenerateSimplex = 1;
                    checkSimplex = true;
                    break;
                }
                // are we getting any closer ?
                var f0:Float = squaredDistance - delta;
                var f1:Float = squaredDistance * REL_ERROR2;

                if (f0 <= f1)
				{
                    if (f0 <= 0)
					{
                        degenerateSimplex = 2;
                    }
                    checkSimplex = true;
                    break;
                }
                // add current vertex to simplex
                simplexSolver.addVertex(w, pWorld, qWorld);

                // calculate the closest point to the origin (update vector v)
                if (!simplexSolver.closest(cachedSeparatingAxis))
				{
                    degenerateSimplex = 3;
                    checkSimplex = true;
                    break;
                }

                if (cachedSeparatingAxis.lengthSquared() < REL_ERROR2)
				{
                    degenerateSimplex = 6;
                    checkSimplex = true;
                    break;
                }

                var previousSquaredDistance:Float = squaredDistance;
                squaredDistance = cachedSeparatingAxis.lengthSquared();

                // redundant m_simplexSolver->compute_points(pointOnA, pointOnB);

                // are we getting any closer ?
                if (previousSquaredDistance - squaredDistance <= BulletGlobals.FLT_EPSILON * previousSquaredDistance) 
				{
                    simplexSolver.backup_closest(cachedSeparatingAxis);
                    checkSimplex = true;
                    break;
                }

                // degeneracy, this is typically due to invalid/uninitialized worldtransforms for a CollisionObject
                if (curIter++ > gGjkMaxIter)
				{
                    //#if defined(DEBUG) || defined (_DEBUG)
                    if (BulletGlobals.DEBUG) 
					{
                        //System.err.printf("btGjkPairDetector maxIter exceeded:%i\n", curIter);
                        //System.err.printf("sepAxis=(%f,%f,%f), squaredDistance = %f, shapeTypeA=%i,shapeTypeB=%i\n",
                                //cachedSeparatingAxis.x,
                                //cachedSeparatingAxis.y,
                                //cachedSeparatingAxis.z,
                                //squaredDistance,
                                //minkowskiA.getShapeType(),
                                //minkowskiB.getShapeType());
                    }
                    //#endif
                    break;

                }

                var check:Bool = (!simplexSolver.fullSimplex());
                //bool check = (!m_simplexSolver->fullSimplex() && squaredDistance > SIMD_EPSILON * m_simplexSolver->maxVertex());

                if (!check) 
				{
                    // do we need this backup_closest here ?
                    simplexSolver.backup_closest(cachedSeparatingAxis);
                    break;
                }
            }

            if (checkSimplex) 
			{
                simplexSolver.compute_points(pointOnA, pointOnB);
                normalInB.sub(pointOnA, pointOnB);
                var lenSqr:Float = cachedSeparatingAxis.lengthSquared();
                // valid normal
                if (lenSqr < 0.0001)
				{
                    degenerateSimplex = 5;
                }
                if (lenSqr > BulletGlobals.FLT_EPSILON * BulletGlobals.FLT_EPSILON)
				{
                    var rlen:Float = 1 / Math.sqrt(lenSqr);
                    normalInB.scale(rlen); // normalize
                    var s:Float = Math.sqrt(squaredDistance);

                    Assert.assert (s > 0);

                    tmp.scale((marginA / s), cachedSeparatingAxis);
                    pointOnA.sub(tmp);

                    tmp.scale((marginB / s), cachedSeparatingAxis);
                    pointOnB.add(tmp);

                    distance = ((1 / rlen) - margin);
                    isValid = true;

                    lastUsedMethod = 1;
                }
				else
				{
                    lastUsedMethod = 2;
                }
            }

            var catchDegeneratePenetrationCase:Bool =
                    (catchDegeneracies != 0 && penetrationDepthSolver != null && degenerateSimplex != 0 && ((distance + margin) < 0.01));

            //if (checkPenetration && !isValid)
            if (checkPenetration && (!isValid || catchDegeneratePenetrationCase)) 
			{
                // penetration case

                // if there is no way to handle penetrations, bail out
                if (penetrationDepthSolver != null)
				{
                    // Penetration depth case.
                    BulletStats.gNumDeepPenetrationChecks++;

                    var isValid2:Bool = penetrationDepthSolver.calcPenDepth(
                            simplexSolver,
                            minkowskiA, minkowskiB,
                            localTransA, localTransB,
                            cachedSeparatingAxis, tmpPointOnA, tmpPointOnB,
                            debugDraw/*,input.stackAlloc*/);

                    if (isValid2)
					{
                        tmpNormalInB.sub(tmpPointOnB, tmpPointOnA);

                        var lenSqr:Float = tmpNormalInB.lengthSquared();
                        if (lenSqr > (BulletGlobals.FLT_EPSILON * BulletGlobals.FLT_EPSILON))
						{
                            tmpNormalInB.scale(1 / Math.sqrt(lenSqr));
                            tmp.sub(tmpPointOnA, tmpPointOnB);
                            var distance2:Float = -tmp.length();
                            // only replace valid penetrations when the result is deeper (check)
                            if (!isValid || (distance2 < distance)) 
							{
                                distance = distance2;
                                pointOnA.fromVector3f(tmpPointOnA);
                                pointOnB.fromVector3f(tmpPointOnB);
                                normalInB.fromVector3f(tmpNormalInB);
                                isValid = true;
                                lastUsedMethod = 3;
                            } 
							else {

                            }
                        } 
						else
						{
                            //isValid = false;
                            lastUsedMethod = 4;
                        }
                    }
					else
					{
                        lastUsedMethod = 5;
                    }

                }
            }
        }

        if (isValid)
		{
            //#ifdef __SPU__
            //		//spu_printf("distance\n");
            //#endif //__CELLOS_LV2__

            tmp.add(pointOnB, positionOffset);
            output.addContactPoint(
                    normalInB,
                    tmp,
                    distance);
            //printf("gjk add:%f",distance);
        }
    }

    public function setMinkowskiA( minkA:ConvexShape):Void
	{
        minkowskiA = minkA;
    }

    public function setMinkowskiB(minkB:ConvexShape):Void
	{
        minkowskiB = minkB;
    }

    public function setCachedSeperatingAxis(seperatingAxis:Vector3f):Void 
	{
        cachedSeparatingAxis.fromVector3f(seperatingAxis);
    }

    public function setPenetrationDepthSolver(penetrationDepthSolver:ConvexPenetrationDepthSolver):Void
	{
        this.penetrationDepthSolver = penetrationDepthSolver;
    }

    /**
     * Don't use setIgnoreMargin, it's for Bullet's internal use.
     */
    public function setIgnoreMargin(ignoreMargin:Bool):Void
	{
        this.ignoreMargin = ignoreMargin;
    }
	
}