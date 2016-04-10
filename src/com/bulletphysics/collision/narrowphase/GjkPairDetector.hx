package com.bulletphysics.collision.narrowphase;
import com.bulletphysics.collision.narrowphase.DiscreteCollisionDetectorInterface.ClosestPointInput;
import com.bulletphysics.collision.narrowphase.DiscreteCollisionDetectorInterface.Result;
import com.bulletphysics.collision.shapes.ConvexShape;
import com.bulletphysics.linearmath.IDebugDraw;
import com.bulletphysics.linearmath.Transform;
import de.polygonal.ds.error.Assert;
import com.bulletphysics.linearmath.MatrixUtil;
import com.bulletphysics.util.StackPool;
import de.polygonal.core.math.Mathematics;
import org.angle3d.utils.Logger;
import org.angle3d.math.Vector3f;

/**
 * GjkPairDetector uses GJK to implement the {DiscreteCollisionDetectorInterface}.
 
 */
class GjkPairDetector implements DiscreteCollisionDetectorInterface
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
	
	public function new()
	{
		
	}

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

	//temp var
	var tmp:Vector3f = new Vector3f();
	var normalInB:Vector3f = new Vector3f();
	var pointOnA:Vector3f = new Vector3f();
	var pointOnB:Vector3f = new Vector3f();
	var localTransA:Transform = new Transform();
	var localTransB:Transform = new Transform();
	var positionOffset:Vector3f = new Vector3f();
	var seperatingAxisInA:Vector3f = new Vector3f();
	var seperatingAxisInB:Vector3f = new Vector3f();

	var pWorld:Vector3f = new Vector3f();
	var qWorld:Vector3f = new Vector3f();
	var w:Vector3f = new Vector3f();

	var tmpPointOnA:Vector3f = new Vector3f();
	var tmpPointOnB:Vector3f = new Vector3f();
	var tmpNormalInB:Vector3f = new Vector3f();
    public function getClosestPoints(input:ClosestPointInput, output:Result, debugDraw:IDebugDraw, swapResults:Bool = false):Void
	{
		var M = Math;
		
        var distance:Float = 0;
        
        normalInB.setTo(0, 0, 0);
        
		localTransA.fromTransform(input.transformA);
		localTransB.fromTransform(input.transformB);
        
        positionOffset.addBy(localTransA.origin, localTransB.origin);
        positionOffset.scaleLocal(0.5);
        localTransA.origin.subtractLocal(positionOffset);
        localTransB.origin.subtractLocal(positionOffset);

        BulletStats.gNumGjkChecks++;

		var marginA:Float;
        var marginB:Float;
        // for CCD we don't use margins
        if (ignoreMargin)
		{
            marginA = 0;
            marginB = 0;
        }
		else
		{
			marginA = minkowskiA.getMargin();
			marginB = minkowskiB.getMargin();
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

            while (true)
            {
                seperatingAxisInA.negateBy(cachedSeparatingAxis);
                MatrixUtil.transposeTransform(seperatingAxisInA, seperatingAxisInA, input.transformA.basis);

                seperatingAxisInB.copyFrom(cachedSeparatingAxis);
                MatrixUtil.transposeTransform(seperatingAxisInB, seperatingAxisInB, input.transformB.basis);

                minkowskiA.localGetSupportingVertexWithoutMargin(seperatingAxisInA, pWorld);
                minkowskiB.localGetSupportingVertexWithoutMargin(seperatingAxisInB, qWorld);

                localTransA.transform(pWorld);
                localTransB.transform(qWorld);

                w.subtractBy(pWorld, qWorld);

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

                if (cachedSeparatingAxis.lengthSquared < REL_ERROR2)
				{
                    degenerateSimplex = 6;
                    checkSimplex = true;
                    break;
                }

                var previousSquaredDistance:Float = squaredDistance;
                squaredDistance = cachedSeparatingAxis.lengthSquared;

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
                    #if debug
                    if (BulletGlobals.DEBUG) 
					{
                        Logger.log('GjkPairDetector maxIter exceeded: $curIter');
                        Logger.log('sepAxis=(${cachedSeparatingAxis}), squaredDistance = ${squaredDistance}, shapeTypeA=${minkowskiA.shapeType},shapeTypeB=${minkowskiB.shapeType}');
                    }
					#end
                    break;
                }

                var check:Bool = (!simplexSolver.fullSimplex());
                //bool check = (!m_simplexSolver->fullSimplex() && squaredDistance > FLT_EPSILON * m_simplexSolver->maxVertex());

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
                normalInB.subtractBy(pointOnA, pointOnB);
                var lenSqr:Float = cachedSeparatingAxis.lengthSquared;
                // valid normal
                if (lenSqr < 0.0001)
				{
                    degenerateSimplex = 5;
                }
                if (lenSqr > BulletGlobals.FLT_EPSILON * BulletGlobals.FLT_EPSILON)
				{
                    var rlen:Float = 1 / M.sqrt(lenSqr);
                    normalInB.scaleLocal(rlen); // normalize
                    var s:Float = M.sqrt(squaredDistance);

					#if debug
                    Assert.assert (s > 0);
					#end

                    tmp.scaleBy((marginA / s), cachedSeparatingAxis);
                    pointOnA.subtractLocal(tmp);

                    tmp.scaleBy((marginB / s), cachedSeparatingAxis);
                    pointOnB.addLocal(tmp);

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
                            debugDraw);

                    if (isValid2)
					{
                        tmpNormalInB.subtractBy(tmpPointOnB, tmpPointOnA);

                        var lenSqr:Float = tmpNormalInB.lengthSquared;
                        if (lenSqr > (BulletGlobals.FLT_EPSILON * BulletGlobals.FLT_EPSILON))
						{
                            tmpNormalInB.scaleLocal(1 / M.sqrt(lenSqr));
                            tmp.subtractBy(tmpPointOnA, tmpPointOnB);
                            var distance2:Float = -tmp.length;
                            // only replace valid penetrations when the result is deeper (check)
                            if (!isValid || (distance2 < distance)) 
							{
                                distance = distance2;
                                pointOnA.copyFrom(tmpPointOnA);
                                pointOnB.copyFrom(tmpPointOnB);
                                normalInB.copyFrom(tmpNormalInB);
                                isValid = true;
                                lastUsedMethod = 3;
                            } 
							else
							{

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
            tmp.addBy(pointOnB, positionOffset);
            output.addContactPoint(normalInB, tmp, distance);
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
        cachedSeparatingAxis.copyFrom(seperatingAxis);
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