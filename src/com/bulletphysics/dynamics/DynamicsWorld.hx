package com.bulletphysics.dynamics;

import com.bulletphysics.collision.broadphase.BroadphaseInterface;
import com.bulletphysics.collision.broadphase.Dispatcher;
import com.bulletphysics.collision.dispatch.CollisionConfiguration;
import com.bulletphysics.collision.dispatch.CollisionWorld;
import com.bulletphysics.dynamics.constraintsolver.ConstraintSolver;
import com.bulletphysics.dynamics.constraintsolver.ContactSolverInfo;
import com.bulletphysics.dynamics.constraintsolver.TypedConstraint;
import com.bulletphysics.dynamics.vehicle.RaycastVehicle;
import org.angle3d.math.Vector3f;

/**
 * DynamicsWorld is the interface class for several dynamics implementation,
 * basic, discrete, parallel, and continuous etc.
 * @author weilichuang
 */
class DynamicsWorld extends CollisionWorld
{
	private var internalTickCallback:InternalTickCallback;
    private var worldUserInfo:Dynamic;

    private var solverInfo:ContactSolverInfo = new ContactSolverInfo();

	public function new(dispatcher:Dispatcher, broadphasePairCache:BroadphaseInterface, collisionConfiguration:CollisionConfiguration) 
	{
		super(dispatcher, broadphasePairCache, collisionConfiguration);
		
	}

    /**
     * Proceeds the simulation over 'timeStep', units in preferably in seconds.<p>
     * <p/>
     * By default, Bullet will subdivide the timestep in constant substeps of each
     * 'fixedTimeStep'.<p>
     * <p/>
     * In order to keep the simulation real-time, the maximum number of substeps can
     * be clamped to 'maxSubSteps'.<p>
     * <p/>
     * You can disable subdividing the timestep/substepping by passing maxSubSteps=0
     * as second argument to stepSimulation, but in that case you have to keep the
     * timeStep constant.
     */
    public function stepSimulation(timeStep:Float, maxSubSteps:Int = 1, fixedTimeStep:Float = 1 / 60):Int
	{
		return 0;
	}

    public function debugDrawWorld():Void
	{
		
	}

    public function addConstraint(constraint:TypedConstraint, disableCollisionsBetweenLinkedBodies:Bool = false):Void
	{
    }

    public function removeConstraint(constraint:TypedConstraint):Void
	{
    }

    public function addAction(action:ActionInterface):Void 
	{
    }

    public function removeAction(action:ActionInterface):Void
	{
    }

    public function addVehicle(vehicle:RaycastVehicle):Void
	{
    }

    public function removeVehicle(vehicle:RaycastVehicle):Void 
	{
    }

    /**
     * Once a rigidbody is added to the dynamics world, it will get this gravity assigned.
     * Existing rigidbodies in the world get gravity assigned too, during this method.
     */
    public function setGravity(gravity:Vector3f):Void
	{
		
	}

    public function getGravity(out:Vector3f):Vector3f
	{
		return out;
	}

    public function addRigidBody(body:RigidBody):Void
	{
		
	}

    public function removeRigidBody(body:RigidBody):Void
	{
		
	}

    public function setConstraintSolver(solver:ConstraintSolver):Void
	{
		
	}

    public function getConstraintSolver():ConstraintSolver
	{
		return null;
	}

    public function getNumConstraints():Int
	{
        return 0;
    }

    public function getConstraint(index:Int):TypedConstraint
	{
        return null;
    }

    // JAVA NOTE: not part of the original api
    public function getNumActions():Int
	{
        return 0;
    }

    // JAVA NOTE: not part of the original api
    public function getAction(index:Int):ActionInterface
	{
        return null;
    }

    public function  getWorldType():DynamicsWorldType
	{
		return null;
	}

    public function  clearForces():Void
	{
		
	}

    /**
     * Set the callback for when an internal tick (simulation substep) happens, optional user info.
     */
    public function setInternalTickCallback(cb:InternalTickCallback, worldUserInfo:Dynamic):Void
	{
        this.internalTickCallback = cb;
        this.worldUserInfo = worldUserInfo;
    }

    public function setWorldUserInfo(worldUserInfo:Dynamic):Void
	{
        this.worldUserInfo = worldUserInfo;
    }

    public function getWorldUserInfo():Dynamic
	{
        return worldUserInfo;
    }

    public function getSolverInfo():ContactSolverInfo
	{
        return solverInfo;
    }
	
}