package com.bulletphysics.collision.narrowphase;
import com.bulletphysics.collision.shapes.ConvexShape;
import com.bulletphysics.linearmath.IDebugDraw;
import com.bulletphysics.linearmath.Transform;
import org.angle3d.math.Vector3f;

/**
 * ConvexPenetrationDepthSolver provides an interface for penetration depth calculation.
 
 */
interface ConvexPenetrationDepthSolver
{
	function calcPenDepth(simplexSolver:SimplexSolverInterface,
                                          convexA:ConvexShape, convexB:ConvexShape,
                                          transA:Transform, transB:Transform,
                                          v:Vector3f, pa:Vector3f, pb:Vector3f,
                                          debugDraw:IDebugDraw):Bool;
}