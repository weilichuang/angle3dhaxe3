package com.bulletphysics.dynamics;

import com.bulletphysics.collision.broadphase.BroadphaseInterface;
import com.bulletphysics.collision.broadphase.Dispatcher;
import com.bulletphysics.collision.broadphase.DispatcherInfo;
import com.bulletphysics.collision.dispatch.CollisionConfiguration;
import com.bulletphysics.collision.dispatch.CollisionDispatcher;
import com.bulletphysics.collision.dispatch.CollisionObject;
import com.bulletphysics.collision.narrowphase.PersistentManifold;
import com.bulletphysics.dynamics.constraintsolver.ConstraintSolver;
import com.bulletphysics.dynamics.constraintsolver.ContactSolverInfo;
import com.bulletphysics.dynamics.DynamicsWorldType;
import com.bulletphysics.dynamics.RigidBody;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.util.ObjectArrayList;
import com.vecmath.Vector3f;

/**
 * SimpleDynamicsWorld serves as unit-test and to verify more complicated and
 * optimized dynamics worlds. Please use {@link DiscreteDynamicsWorld} instead
 * (or ContinuousDynamicsWorld once it is finished).
 *
 * @author weilichuang
 */
class SimpleDynamicsWorld extends DynamicsWorld
{

	private var constraintSolver:ConstraintSolver;
    private var ownsConstraintSolver:Bool;
    private var gravity:Vector3f = new Vector3f(0, 0, -10);

    public function new(dispatcher:Dispatcher, pairCache:BroadphaseInterface, constraintSolver:ConstraintSolver, collisionConfiguration:CollisionConfiguration)
	{
        super(dispatcher, pairCache, collisionConfiguration);
        this.constraintSolver = constraintSolver;
        this.ownsConstraintSolver = false;
    }

    private function predictUnconstraintMotion(timeStep:Float):Void
	{
        //var tmpTrans:Transform = new Transform();

        for (i in 0...collisionObjects.size()) 
		{
            var colObj:CollisionObject = collisionObjects.getQuick(i);
            var body:RigidBody = RigidBody.upcast(colObj);
            if (body != null)
			{
                if (!body.isStaticObject())
				{
                    if (body.isActive()) 
					{
                        body.applyGravity();
                        body.integrateVelocities(timeStep);
                        body.applyDamping(timeStep);
						
						//TODO 这里是不是应该用上面这个,计算tmpTrans的值毫无意义啊
						body.predictIntegratedTransform(timeStep, body.getInterpolationWorldTransform());
                        //body.predictIntegratedTransform(timeStep, body.getInterpolationWorldTransformTo(tmpTrans));
                    }
                }
            }
        }
    }

    private function integrateTransforms(timeStep:Float):Void
	{
        var predictedTrans:Transform = new Transform();
        for (i in 0...collisionObjects.size()) 
		{
            var colObj:CollisionObject = collisionObjects.getQuick(i);
            var body:RigidBody = RigidBody.upcast(colObj);
            if (body != null)
			{
                if (body.isActive() && (!body.isStaticObject())) 
				{
                    body.predictIntegratedTransform(timeStep, predictedTrans);
                    body.proceedToTransform(predictedTrans);
                }
            }
        }
    }

    /**
     * maxSubSteps/fixedTimeStep for interpolation is currently ignored for SimpleDynamicsWorld, use DiscreteDynamicsWorld instead.
     */
	override public function stepSimulation(timeStep:Float, maxSubSteps:Int = 1, fixedTimeStep:Float = 1/60):Int 
	{
		// apply gravity, predict motion
        predictUnconstraintMotion(timeStep);

        var dispatchInfo:DispatcherInfo = getDispatchInfo();
        dispatchInfo.timeStep = timeStep;
        dispatchInfo.stepCount = 0;
        dispatchInfo.debugDraw = getDebugDrawer();

        // perform collision detection
        performDiscreteCollisionDetection();

        // solve contact constraints
        var numManifolds:Int = dispatcher1.getNumManifolds();
        if (numManifolds != 0)
		{
            var manifoldPtr:ObjectArrayList<PersistentManifold> = cast(dispatcher1,CollisionDispatcher).getInternalManifoldPointer();

            var infoGlobal:ContactSolverInfo = new ContactSolverInfo();
            infoGlobal.timeStep = timeStep;
            constraintSolver.prepareSolve(0, numManifolds);
            constraintSolver.solveGroup(null, 0, manifoldPtr, 0, numManifolds, null, 0, 0, infoGlobal, debugDrawer/*, m_stackAlloc*/, dispatcher1);
            constraintSolver.allSolved(infoGlobal, debugDrawer/*, m_stackAlloc*/);
        }

        // integrate transforms
        integrateTransforms(timeStep);

        updateAabbs();

        synchronizeMotionStates();

        clearForces();

        return 1;
	}
	
	override public function clearForces():Void 
	{
		// todo: iterate over awake simulation islands!
        for (i in 0...collisionObjects.size()) 
		{
            var colObj:CollisionObject = collisionObjects.getQuick(i);

            var body:RigidBody = RigidBody.upcast(colObj);
            if (body != null)
			{
                body.clearForces();
            }
        }
	}
	
	override public function setGravity(gravity:Vector3f):Void 
	{
		this.gravity.fromVector3f(gravity);
        for (i in 0...collisionObjects.size()) 
		{
            var colObj:CollisionObject = collisionObjects.getQuick(i);
            var body:RigidBody = RigidBody.upcast(colObj);
            if (body != null) 
			{
                body.setGravity(gravity);
            }
        }
	}
	
	override public function getGravity(out:Vector3f):Vector3f 
	{
		out.fromVector3f(gravity);
		return out;
	}

    override public function addRigidBody(body:RigidBody):Void 
	{
		body.setGravity(gravity);

        if (body.getCollisionShape() != null) {
            addCollisionObject(body);
        }
	}
	
	override public function removeRigidBody(body:RigidBody):Void 
	{
		removeCollisionObject(body);
	}

    override public function updateAabbs():Void 
	{
		//var tmpTrans:Transform = new Transform();
        var predictedTrans:Transform = new Transform();
        var minAabb:Vector3f = new Vector3f();
		var maxAabb:Vector3f = new Vector3f();

        for (i in 0...collisionObjects.size()) 
		{
            var colObj:CollisionObject = collisionObjects.getQuick(i);
            var body:RigidBody = RigidBody.upcast(colObj);
            if (body != null)
			{
                if (body.isActive() && (!body.isStaticObject())) 
				{
                    colObj.getCollisionShape().getAabb(colObj.getWorldTransform(), minAabb, maxAabb);
                    var bp:BroadphaseInterface = getBroadphase();
                    bp.setAabb(body.getBroadphaseHandle(), minAabb, maxAabb, dispatcher1);
                }
            }
        }
	}

    public function synchronizeMotionStates():Void
	{
        //var tmpTrans:Transform = new Transform();

        // todo: iterate over awake simulation islands!
        for (i in 0...collisionObjects.size())
		{
            var colObj:CollisionObject = collisionObjects.getQuick(i);
            var body:RigidBody = RigidBody.upcast(colObj);
            if (body != null && body.getMotionState() != null)
			{
                if (body.getActivationState() != CollisionObject.ISLAND_SLEEPING)
				{
                    body.getMotionState().setWorldTransform(body.getWorldTransform());
                }
            }
        }
    }
	
	override public function setConstraintSolver(solver:ConstraintSolver):Void 
	{
		if (ownsConstraintSolver) {
            //btAlignedFree(m_constraintSolver);
        }

        ownsConstraintSolver = false;
        constraintSolver = solver;
	}

    override public function getConstraintSolver():ConstraintSolver 
	{
		return constraintSolver;
	}
    
	override public function debugDrawWorld():Void 
	{
	}
	
	override public function getWorldType():DynamicsWorldType 
	{
		return DynamicsWorldType.SIMPLE_DYNAMICS_WORLD;
	}
}