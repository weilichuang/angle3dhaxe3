package com.bulletphysics.collision.narrowphase;
import com.bulletphysics.collision.narrowphase.GjkEpaSolver.Results;
import com.bulletphysics.collision.shapes.ConvexShape;
import com.bulletphysics.linearmath.IDebugDraw;
import com.bulletphysics.linearmath.Transform;
import vecmath.Vector3f;

/**
 * GjkEpaPenetrationDepthSolver uses the Expanding Polytope Algorithm to calculate
 * the penetration depth between two convex shapes.
 *
 * @author weilichuang
 */
class GjkEpaPenetrationDepthSolver extends ConvexPenetrationDepthSolver
{
	private var gjkEpaSolver:GjkEpaSolver = new GjkEpaSolver();

	public function new() 
	{
		super();
		
	}
	
    override public function calcPenDepth(simplexSolver:SimplexSolverInterface,
                                pConvexA:ConvexShape, pConvexB:ConvexShape,
                                transformA:Transform, transformB:Transform,
                                v:Vector3f, wWitnessOnA:Vector3f, wWitnessOnB:Vector3f,
                                debugDraw:IDebugDraw):Bool
	{
        var radialmargin:Float = 0;

        // JAVA NOTE: 2.70b1: update when GjkEpaSolver2 is ported

        var results:Results = new Results();
        if (gjkEpaSolver.collide(pConvexA, transformA,
                pConvexB, transformB,
                radialmargin, results))
		{
            //debugDraw->drawLine(results.witnesses[1],results.witnesses[1]+results.normal,btVector3(255,0,0));
            //resultOut->addContactPoint(results.normal,results.witnesses[1],-results.depth);
            wWitnessOnA.fromVector3f(results.witnesses[0]);
            wWitnessOnB.fromVector3f(results.witnesses[1]);
            return true;
        }

        return false;
    }
	
}