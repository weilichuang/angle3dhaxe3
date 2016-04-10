package com.bulletphysics.dynamics.constraintsolver;
import com.bulletphysics.collision.broadphase.Dispatcher;
import com.bulletphysics.collision.dispatch.CollisionObject;
import com.bulletphysics.collision.narrowphase.PersistentManifold;
import com.bulletphysics.linearmath.IDebugDraw;
import com.bulletphysics.util.ObjectArrayList;

/**
 * interface for constraint solvers.
 
 */
interface ConstraintSolver
{
    function prepareSolve(numBodies:Int, numManifolds:Int):Void;
	
    /**
     * Solve a group of constraints.
     */
    function solveGroup(bodies:ObjectArrayList<CollisionObject>, numBodies:Int, 
							  manifold:ObjectArrayList<PersistentManifold>, manifold_offset:Int, numManifolds:Int, 
							  constraints:ObjectArrayList<TypedConstraint>, constraints_offset:Int, numConstraints:Int,
							  info:ContactSolverInfo, debugDrawer:IDebugDraw, dispatcher:Dispatcher):Float;

    function allSolved(info:ContactSolverInfo, debugDrawer:IDebugDraw):Void;
	
    /**
     * Clear internal cached data and reset random seed.
     */
    function reset():Void;
}