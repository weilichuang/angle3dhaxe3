package com.bulletphysics.dynamics;
import com.bulletphysics.collision.broadphase.BroadphaseInterface;
import com.bulletphysics.collision.broadphase.BroadphasePair;
import com.bulletphysics.collision.broadphase.BroadphaseProxy;
import com.bulletphysics.collision.broadphase.CollisionFilterGroups;
import com.bulletphysics.collision.broadphase.Dispatcher;
import com.bulletphysics.collision.broadphase.DispatcherInfo;
import com.bulletphysics.collision.broadphase.OverlappingPairCache;
import com.bulletphysics.collision.dispatch.CollisionConfiguration;
import com.bulletphysics.collision.dispatch.CollisionObject;
import com.bulletphysics.collision.dispatch.CollisionWorld;
import com.bulletphysics.collision.dispatch.IslandCallback;
import com.bulletphysics.collision.dispatch.SimulationIslandManager;
import com.bulletphysics.collision.narrowphase.ManifoldPoint;
import com.bulletphysics.collision.narrowphase.PersistentManifold;
import com.bulletphysics.collision.shapes.CollisionShape;
import com.bulletphysics.collision.shapes.SphereShape;
import com.bulletphysics.dynamics.constraintsolver.ConstraintSolver;
import com.bulletphysics.dynamics.constraintsolver.ContactSolverInfo;
import com.bulletphysics.dynamics.constraintsolver.SequentialImpulseConstraintSolver;
import com.bulletphysics.dynamics.constraintsolver.TypedConstraint;
import com.bulletphysics.dynamics.vehicle.RaycastVehicle;
import com.bulletphysics.dynamics.vehicle.WheelInfo;
import com.bulletphysics.linearmath.AabbUtil2;
import com.bulletphysics.linearmath.CProfileManager;
import com.bulletphysics.linearmath.DebugDrawModes;
import com.bulletphysics.linearmath.IDebugDraw;
import com.bulletphysics.linearmath.ScalarUtil;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.TransformUtil;
import com.bulletphysics.util.ObjectArrayList;
import com.bulletphysics.util.StackPool;
import flash.Lib;
import org.angle3d.math.Vector3f;

/**
 * DiscreteDynamicsWorld provides discrete rigid body simulation.
 
 */
class DiscreteDynamicsWorld extends DynamicsWorld
{
	private var constraintSolver:ConstraintSolver;
    private var islandManager:SimulationIslandManager;
    private var constraints:ObjectArrayList<TypedConstraint> = new ObjectArrayList<TypedConstraint>();
    private var gravity:Vector3f = new Vector3f(0, -10, 0);

    //for variable timesteps
    private var localTime:Float = 1 / 60;
    //for variable timesteps

    private var ownsIslandManager:Bool;
    private var ownsConstraintSolver:Bool;

    private var vehicles:ObjectArrayList<RaycastVehicle> = new ObjectArrayList<RaycastVehicle>();

    private var actions:ObjectArrayList<ActionInterface> = new ObjectArrayList<ActionInterface>();

    private var profileTimings:Int = 0;
	
	private var preTickCallback:InternalTickCallback;

    public function new(dispatcher:Dispatcher, 
						pairCache:BroadphaseInterface, 
						constraintSolver:ConstraintSolver,  
						collisionConfiguration:CollisionConfiguration)
	{
        super(dispatcher, pairCache, collisionConfiguration);
		
		_worldType = DynamicsWorldType.DISCRETE_DYNAMICS_WORLD;
		
        this.constraintSolver = constraintSolver;

        if (this.constraintSolver == null)
		{
            this.constraintSolver = new SequentialImpulseConstraintSolver();
            ownsConstraintSolver = true;
        } 
		else
		{
            ownsConstraintSolver = false;
        }

		islandManager = new SimulationIslandManager();
        ownsIslandManager = true;
    }

    private function saveKinematicState( timeStep:Float):Void
	{
        for (i in 0...collisionObjects.size())
		{
            var colObj:CollisionObject = collisionObjects.getQuick(i);
            var body:RigidBody = RigidBody.upcast(colObj);
            if (body != null)
			{
                //Transform predictedTrans = new Transform();
                if (body.getActivationState() != CollisionObject.ISLAND_SLEEPING) 
				{
                    if (body.isKinematicObject())
					{
                        // to calculate velocities next frame
                        body.saveKinematicState(timeStep);
                    }
                }
            }
        }
    }

    public function awakenRigidBodiesInArea(min:Vector3f, max:Vector3f):Void
	{
		var pool:StackPool = StackPool.get();
		var otherMin:Vector3f = pool.getVector3f();
		var otherMax:Vector3f = pool.getVector3f();
		var trans:Transform = pool.getTransform();
        for (i in 0...collisionObjects.size()) 
		{
            var collisionObject:CollisionObject = collisionObjects.getQuick(i);
            if (!collisionObject.isStaticOrKinematicObject() && !collisionObject.isActive()) 
			{
                collisionObject.getCollisionShape().getAabb(collisionObject.getWorldTransform(), otherMin, otherMax);
                if (AabbUtil2.testAabbAgainstAabb2(min, max, otherMin, otherMax))
				{
                    collisionObject.activate();
                }
            }
        }
		pool.release();
    }

    override public function debugDrawWorld():Void
	{
        if (getDebugDrawer() != null && (getDebugDrawer().getDebugMode() & DebugDrawModes.DRAW_CONTACT_POINTS) != 0) 
		{
            var numManifolds:Int = getDispatcher().getNumManifolds();
            var color:Vector3f = new Vector3f();
            color.setTo(0, 0, 0);
            for (i in 0...numManifolds)
			{
                var contactManifold:PersistentManifold = getDispatcher().getManifoldByIndexInternal(i);
                //btCollisionObject* obA = static_cast<btCollisionObject*>(contactManifold->getBody0());
                //btCollisionObject* obB = static_cast<btCollisionObject*>(contactManifold->getBody1());

                var numContacts:Int = contactManifold.getNumContacts();
                for (j in 0...numContacts) 
				{
                    var cp:ManifoldPoint = contactManifold.getContactPoint(j);
                    getDebugDrawer().drawContactPoint(cp.positionWorldOnB, cp.normalWorldOnB, cp.getDistance(), cp.getLifeTime(), color);
                }
            }
        }

        if (getDebugDrawer() != null && (getDebugDrawer().getDebugMode() & (DebugDrawModes.DRAW_WIREFRAME | DebugDrawModes.DRAW_AABB)) != 0)
		{
            var tmpTrans:Transform = new Transform();
            var minAabb:Vector3f = new Vector3f();
            var maxAabb:Vector3f = new Vector3f();
            var colorvec:Vector3f = new Vector3f();

            // todo: iterate over awake simulation islands!
            for (i in 0...collisionObjects.size())
			{
                var colObj:CollisionObject = collisionObjects.getQuick(i);
                if (getDebugDrawer() != null && (getDebugDrawer().getDebugMode() & DebugDrawModes.DRAW_WIREFRAME) != 0) {
                    var color:Vector3f = new Vector3f();
                    color.setTo(255, 255, 255);
                    switch (colObj.getActivationState())
					{
                        case CollisionObject.ACTIVE_TAG:
                            color.setTo(255,255,255);
                        case CollisionObject.ISLAND_SLEEPING:
                            color.setTo(0, 255, 0);
                        case CollisionObject.WANTS_DEACTIVATION:
                            color.setTo(0, 255, 255);
                        case CollisionObject.DISABLE_DEACTIVATION:
                            color.setTo(255, 0, 0);
                        case CollisionObject.DISABLE_SIMULATION:
                            color.setTo(255, 255, 0);
                        default: {
                            color.setTo(255, 0, 0);
                        }
                    }

                    debugDrawObject(colObj.getWorldTransform(), colObj.getCollisionShape(), color);
                }
                if (debugDrawer != null && (debugDrawer.getDebugMode() & DebugDrawModes.DRAW_AABB) != 0) 
				{
                    colorvec.setTo(1, 0, 0);
                    colObj.getCollisionShape().getAabb(colObj.getWorldTransform(), minAabb, maxAabb);
                    debugDrawer.drawAabb(minAabb, maxAabb, colorvec);
                }
            }

            var wheelColor:Vector3f = new Vector3f();
            var wheelPosWS:Vector3f = new Vector3f();
            var axle:Vector3f = new Vector3f();
            var tmp:Vector3f = new Vector3f();

            for (i in 0...vehicles.size())
			{
                for (v in 0...vehicles.getQuick(i).getNumWheels())
				{
                    wheelColor.setTo(0, 255, 255);
                    if (vehicles.getQuick(i).getWheelInfo(v).raycastInfo.isInContact) 
					{
                        wheelColor.setTo(0, 0, 255);
                    }
					else
					{
                        wheelColor.setTo(255, 0, 255);
                    }
					
					var vehicle:RaycastVehicle = vehicles.getQuick(i);
					var wheelInfo:WheelInfo = vehicle.getWheelInfo(v);

                    wheelPosWS.copyFrom(wheelInfo.worldTransform.origin);

                    axle.setTo(
                            wheelInfo.worldTransform.basis.getElement(0, vehicle.getRightAxis()),
                            wheelInfo.worldTransform.basis.getElement(1, vehicle.getRightAxis()),
                            wheelInfo.worldTransform.basis.getElement(2, vehicle.getRightAxis()));


                    //m_vehicles[i]->getWheelInfo(v).m_raycastInfo.m_wheelAxleWS
                    //debug wheels (cylinders)
                    tmp.addBy(wheelPosWS, axle);
                    debugDrawer.drawLine(wheelPosWS, tmp, wheelColor);
                    debugDrawer.drawLine(wheelPosWS, wheelInfo.raycastInfo.contactPointWS, wheelColor);
                }
            }

            if (getDebugDrawer() != null && getDebugDrawer().getDebugMode() != 0) 
			{
                for (i in 0...actions.size()) 
				{
                    actions.getQuick(i).debugDraw(debugDrawer);
                }
            }
        }
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

    /**
     * Apply gravity, call this once per timestep.
     */
    public function applyGravity():Void
	{
        // todo: iterate over awake simulation islands!
        for (i in 0...collisionObjects.size()) 
		{
            var colObj:CollisionObject = collisionObjects.getQuick(i);

            var body:RigidBody = RigidBody.upcast(colObj);
            if (body != null && body.isActive())
			{
                body.applyGravity();
            }
        }
    }

	private var interpolatedTransform:Transform = new Transform();
	//private var tmpTrans:Transform = new Transform();
	//private var tmpLinVel:Vector3f = new Vector3f();
	//private var tmpAngVel:Vector3f = new Vector3f();
    private function synchronizeMotionStates():Void
	{
        // todo: iterate over awake simulation islands!
        for (i in 0...collisionObjects.size())
		{
            var colObj:CollisionObject = collisionObjects.getQuick(i);

            var body:RigidBody = RigidBody.upcast(colObj);
            if (body != null && body.getMotionState() != null && !body.isStaticOrKinematicObject())
			{
                // we need to call the update at least once, even for sleeping objects
                // otherwise the 'graphics' transform never updates properly
                // so todo: add 'dirty' flag
                //if (body->getActivationState() != ISLAND_SLEEPING)
                {
                    TransformUtil.integrateTransform(
                            body.getInterpolationWorldTransform(),
                            body.getInterpolationLinearVelocity(),
                            body.getInterpolationAngularVelocity(),
                            localTime * body.getHitFraction(), interpolatedTransform);
							
                    body.getMotionState().setWorldTransform(interpolatedTransform);
                }
            }
        }

        if (getDebugDrawer() != null && (getDebugDrawer().getDebugMode() & DebugDrawModes.DRAW_WIREFRAME) != 0)
		{
            for (i in 0...vehicles.size()) 
			{
				var vehicle:RaycastVehicle = vehicles.getQuick(i);
                for (v in 0...vehicle.getNumWheels())
				{
                    // synchronize the wheels with the (interpolated) chassis worldtransform
                    vehicle.updateWheelTransform(v, true);
                }
            }
        }
    }

    override public function stepSimulation(timeStep:Float, maxSubSteps:Int = 1, fixedTimeStep:Float = 1 / 60):Int
	{
        startProfiling(timeStep);

        var t0:Int = Lib.getTimer();

		#if BT_PROFILE
        BulletStats.pushProfile("stepSimulation");
		#end

		var numSimulationSubSteps:Int = 0;

		if (maxSubSteps != 0)
		{
			// fixed timestep with interpolation
			localTime += timeStep;
			if (localTime >= fixedTimeStep)
			{
				numSimulationSubSteps = Std.int(localTime / fixedTimeStep);
				localTime -= numSimulationSubSteps * fixedTimeStep;
			}
		} 
		else 
		{
			//variable timestep
			fixedTimeStep = timeStep;
			localTime = timeStep;
			if (ScalarUtil.fuzzyZero(timeStep)) 
			{
				numSimulationSubSteps = 0;
				maxSubSteps = 0;
			}
			else 
			{
				numSimulationSubSteps = 1;
				maxSubSteps = 1;
			}
		}

		// process some debugging flags
		if (getDebugDrawer() != null)
		{
			BulletGlobals.setDeactivationDisabled((getDebugDrawer().getDebugMode() & DebugDrawModes.NO_DEACTIVATION) != 0);
		}
		
		if (numSimulationSubSteps != 0) 
		{
			saveKinematicState(fixedTimeStep);

			applyGravity();

			// clamp the number of substeps, to prevent simulation grinding spiralling down to a halt
			var clampedSimulationSteps:Int = (numSimulationSubSteps > maxSubSteps) ? maxSubSteps : numSimulationSubSteps;

			for (i in 0...clampedSimulationSteps)
			{
				internalSingleStepSimulation(fixedTimeStep);
				synchronizeMotionStates();
			}
		}

		synchronizeMotionStates();

		clearForces();

		#if BT_PROFILE
		CProfileManager.incrementFrameCounter();
		BulletStats.popProfile();
		#end
		
		BulletStats.stepSimulationTime = Std.int((Lib.getTimer() - t0) / 1000);

		return numSimulationSubSteps;
    }

    private function internalSingleStepSimulation(timeStep:Float):Void
	{
		#if BT_PROFILE
        BulletStats.pushProfile("internalSingleStepSimulation");
		#end
		
		if (preTickCallback != null) 
		{
			preTickCallback.internalTick(this, timeStep);
		}

		// apply gravity, predict motion
		predictUnconstraintMotion(timeStep);

		var dispatchInfo:DispatcherInfo = getDispatchInfo();

		dispatchInfo.timeStep = timeStep;
		dispatchInfo.stepCount = 0;
		dispatchInfo.debugDraw = getDebugDrawer();

		// perform collision detection
		performDiscreteCollisionDetection();

		calculateSimulationIslands();

		getSolverInfo().timeStep = timeStep;

		// solve contact and other joint constraints
		solveConstraints(getSolverInfo());

		//CallbackTriggers();

		// integrate transforms
		integrateTransforms(timeStep);

		// update vehicle simulation
		updateActions(timeStep);

		// update vehicle simulation
		updateVehicles(timeStep);

		updateActivationState(timeStep);

		if (internalTickCallback != null)
		{
			internalTickCallback.internalTick(this, timeStep);
		}

		#if BT_PROFILE
		BulletStats.popProfile();
		#end
    }

    override public function setGravity(gravity:Vector3f):Void
	{
        this.gravity.copyFrom(gravity);
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
        out.copyFrom(gravity);
        return out;
    }
	
    override public function removeRigidBody(body:RigidBody):Void
	{
        removeCollisionObject(body);
    }
	
	override public function addRigidBody(body:RigidBody):Void 
	{
		if (!body.isStaticOrKinematicObject()) 
		{
            body.setGravity(gravity);
        }

        if (body.getCollisionShape() != null) 
		{
            var isDynamic:Bool = !(body.isStaticObject() || body.isKinematicObject());
            var collisionFilterGroup:Int = isDynamic ? CollisionFilterGroups.DEFAULT_FILTER :  CollisionFilterGroups.STATIC_FILTER;
            var collisionFilterMask:Int = isDynamic ? CollisionFilterGroups.ALL_FILTER : (CollisionFilterGroups.ALL_FILTER ^ CollisionFilterGroups.STATIC_FILTER);

            addCollisionObject(body, collisionFilterGroup, collisionFilterMask);
        }
	}

    public function addRigidBodyWithGroupMask(body:RigidBody, group:Int, mask:Int):Void 
	{
        if (!body.isStaticOrKinematicObject())
		{
            body.setGravity(gravity);
        }

        if (body.getCollisionShape() != null) 
		{
            addCollisionObject(body, group, mask);
        }
    }

    public function updateActions(timeStep:Float):Void
	{
		#if BT_PROFILE
        BulletStats.pushProfile("updateActions");
		#end

		for (i in 0...actions.size()) 
		{
			actions.getQuick(i).updateAction(this, timeStep);
		}

		#if BT_PROFILE
		BulletStats.popProfile();
		#end
    }

    private function updateVehicles(timeStep:Float):Void
	{
		#if BT_PROFILE
        BulletStats.pushProfile("updateVehicles");
		#end

		for (i in 0...vehicles.size())
		{
			var vehicle:RaycastVehicle = vehicles.getQuick(i);
			vehicle.updateVehicle(timeStep);
		}

		#if BT_PROFILE
		BulletStats.popProfile();
		#end
    }

    private function updateActivationState(timeStep:Float):Void
	{
        BulletStats.pushProfile("updateActivationState");

		var ZERO:Vector3f = new Vector3f(0, 0, 0);

		for (i in 0...collisionObjects.size())
		{
			var colObj:CollisionObject = collisionObjects.getQuick(i);
			var body:RigidBody = RigidBody.upcast(colObj);
			if (body != null)
			{
				body.updateDeactivation(timeStep);

				if (body.wantsSleeping())
				{
					if (body.isStaticOrKinematicObject())
					{
						body.setActivationState(CollisionObject.ISLAND_SLEEPING);
					} 
					else
					{
						if (body.getActivationState() == CollisionObject.ACTIVE_TAG)
						{
							body.setActivationState(CollisionObject.WANTS_DEACTIVATION);
						}
						if (body.getActivationState() == CollisionObject.ISLAND_SLEEPING) 
						{
							body.setAngularVelocity(ZERO);
							body.setLinearVelocity(ZERO);
						}
					}
				} 
				else 
				{
					if (body.getActivationState() != CollisionObject.DISABLE_DEACTIVATION) 
					{
						body.setActivationState(CollisionObject.ACTIVE_TAG);
					}
				}
			}
		}

		#if BT_PROFILE
		BulletStats.popProfile();
		#end
    }

    override public function addConstraint(constraint:TypedConstraint, disableCollisionsBetweenLinkedBodies:Bool = false):Void
	{
        constraints.add(constraint);
        if (disableCollisionsBetweenLinkedBodies)
		{
            constraint.getRigidBodyA().addConstraintRef(constraint);
            constraint.getRigidBodyB().addConstraintRef(constraint);
        }
    }

    override public function removeConstraint(constraint:TypedConstraint):Void
	{
        constraints.removeObject(constraint);
        constraint.getRigidBodyA().removeConstraintRef(constraint);
        constraint.getRigidBodyB().removeConstraintRef(constraint);
    }

    override public function addAction(action:ActionInterface):Void 
	{
        actions.add(action);
    }

    override public function removeAction(action:ActionInterface):Void 
	{
        actions.removeObject(action);
    }

    override public function addVehicle(vehicle:RaycastVehicle):Void
	{
        vehicles.add(vehicle);
    }

    override public function removeVehicle(vehicle:RaycastVehicle):Void
	{
        vehicles.removeObject(vehicle);
    }

    public static inline function getConstraintIslandId(lhs:TypedConstraint):Int
	{
        var rcolObj0:CollisionObject = lhs.getRigidBodyA();
        var rcolObj1:CollisionObject = lhs.getRigidBodyB();
        var islandId:Int = rcolObj0.getIslandTag() >= 0 ? rcolObj0.getIslandTag() : rcolObj1.getIslandTag();
        return islandId;
    }

    private var sortedConstraints:ObjectArrayList<TypedConstraint> = new ObjectArrayList<TypedConstraint>();
    private var solverCallback:InplaceSolverIslandCallback = new InplaceSolverIslandCallback();

    private function solveConstraints(solverInfo:ContactSolverInfo):Void
	{
		#if BT_PROFILE
        BulletStats.pushProfile("solveConstraints");
		#end

		// sorted version of all btTypedConstraint, based on islandId
		sortedConstraints.clear();
		for (i in 0...constraints.size()) 
		{
			sortedConstraints.add(constraints.getQuick(i));
		}
		//Collections.sort(sortedConstraints, sortConstraintOnIslandPredicate);
		sortedConstraints.quickSort(sortConstraintOnIslandPredicate);

		var constraintsPtr:ObjectArrayList<TypedConstraint> = getNumConstraints() != 0 ? sortedConstraints : null;

		solverCallback.init(solverInfo, constraintSolver, constraintsPtr, sortedConstraints.size(), debugDrawer, dispatcher1);

		constraintSolver.prepareSolve(getCollisionWorld().getNumCollisionObjects(), getCollisionWorld().getDispatcher().getNumManifolds());

		// solve all the constraints for this island
		islandManager.buildAndProcessIslands(getCollisionWorld().getDispatcher(), getCollisionWorld().getCollisionObjectArray(), solverCallback);

		constraintSolver.allSolved(solverInfo, debugDrawer);

		#if BT_PROFILE
		BulletStats.popProfile();
		#end
    }

    private function calculateSimulationIslands():Void
	{
		#if BT_PROFILE
        BulletStats.pushProfile("calculateSimulationIslands");
		#end

		getSimulationIslandManager().updateActivationState(getCollisionWorld(), getCollisionWorld().getDispatcher());

		{
			var numConstraints:Int = constraints.size();
			for (i in 0...numConstraints) 
			{
				var constraint:TypedConstraint = constraints.getQuick(i);

				var colObj0:RigidBody = constraint.getRigidBodyA();
				var colObj1:RigidBody = constraint.getRigidBodyB();

				if (((colObj0 != null) && (!colObj0.isStaticOrKinematicObject())) &&
					((colObj1 != null) && (!colObj1.isStaticOrKinematicObject()))) 
				{
					if (colObj0.isActive() || colObj1.isActive())
					{
						getSimulationIslandManager().getUnionFind().unite(colObj0.getIslandTag(), colObj1.getIslandTag());
					}
				}
			}
		}

		// Store the island id in each body
		getSimulationIslandManager().storeIslandActivationState(getCollisionWorld());

		#if BT_PROFILE
		BulletStats.popProfile();
		#end
    }

    private function integrateTransforms(timeStep:Float):Void
	{
		#if BT_PROFILE
        BulletStats.pushProfile("integrateTransforms");
		#end

		var predictedTrans:Transform = new Transform();
		for (i in 0...collisionObjects.size())
		{
			var colObj:CollisionObject = collisionObjects.getQuick(i);
			var body:RigidBody = RigidBody.upcast(colObj);
			if (body != null)
			{
				body.setHitFraction(1);

				if (body.isActive() && (!body.isStaticOrKinematicObject()))
				{
					body.predictIntegratedTransform(timeStep, predictedTrans);

					tmp.subtractBy(predictedTrans.origin, body.getWorldTransform().origin);
					
					var squareMotion:Float = tmp.lengthSquared;

					if (body.getCcdSquareMotionThreshold() != 0 && body.getCcdSquareMotionThreshold() < squareMotion)
					{
						#if BT_PROFILE
						BulletStats.pushProfile("CCD motion clamping");
						#end

						if (body.getCollisionShape().isConvex())
						{
							BulletStats.gNumClampedCcdMotions++;

							var sweepResults:ClosestNotMeConvexResultCallback = new ClosestNotMeConvexResultCallback(body, body.getWorldTransform().origin, predictedTrans.origin, getBroadphase().getOverlappingPairCache(), getDispatcher());
							//ConvexShape convexShape = (ConvexShape)body.getCollisionShape();
							var tmpSphere:SphereShape = new SphereShape(body.getCcdSweptSphereRadius()); //btConvexShape* convexShape = static_cast<btConvexShape*>(body->getCollisionShape());

							sweepResults.collisionFilterGroup = body.getBroadphaseProxy().collisionFilterGroup;
							sweepResults.collisionFilterMask = body.getBroadphaseProxy().collisionFilterMask;

							convexSweepTest(tmpSphere, body.getWorldTransform(), predictedTrans, sweepResults);
							// JAVA NOTE: added closestHitFraction test to prevent objects being stuck
							if (sweepResults.hasHit() && (sweepResults.closestHitFraction > 0.0001)) 
							{
								body.setHitFraction(sweepResults.closestHitFraction);
								body.predictIntegratedTransform(timeStep * body.getHitFraction(), predictedTrans);
								body.setHitFraction(0);
								//System.out.printf("clamped integration to hit fraction = %f\n", sweepResults.closestHitFraction);
							}
						}

						#if BT_PROFILE
						BulletStats.popProfile();
						#end
					}

					body.proceedToTransform(predictedTrans);
				}
			}
		}

		#if BT_PROFILE
		BulletStats.popProfile();
		#end
    }

	//private var tmpTrans:Transform = new Transform();
    private function predictUnconstraintMotion(timeStep:Float):Void 
	{
		#if BT_PROFILE
        BulletStats.pushProfile("predictUnconstraintMotion");
		#end

		for (i in 0...collisionObjects.size())
		{
			var colObj:CollisionObject = collisionObjects.getQuick(i);
			var body:RigidBody = RigidBody.upcast(colObj);
			if (body != null)
			{
				if (!body.isStaticOrKinematicObject()) 
				{
					if (body.isActive()) 
					{
						body.integrateVelocities(timeStep);
						// damping
						body.applyDamping(timeStep);

						//TODO 这里是不是应该用上面这个,计算tmpTrans的值毫无意义啊
						body.predictIntegratedTransform(timeStep, body.getInterpolationWorldTransform());
						//body.predictIntegratedTransform(timeStep, body.getInterpolationWorldTransformTo(tmpTrans));
					}
				}
			}
		}

		#if BT_PROFILE
		BulletStats.popProfile();
		#end
    }

    private function startProfiling(timeStep:Float):Void
	{
        #if BT_PROFILE
        CProfileManager.reset();
        #end
    }

    private function debugDrawSphere(radius:Float, transform:Transform, color:Vector3f):Void
	{
        var start:Vector3f = transform.origin.clone();

        var xoffs:Vector3f = new Vector3f();
        xoffs.setTo(radius, 0, 0);
        transform.basis.multVecLocal(xoffs);
        var yoffs:Vector3f = new Vector3f();
        yoffs.setTo(0, radius, 0);
        transform.basis.multVecLocal(yoffs);
        var zoffs:Vector3f = new Vector3f();
        zoffs.setTo(0, 0, radius);
        transform.basis.multVecLocal(zoffs);

        var tmp1:Vector3f = new Vector3f();
        var tmp2:Vector3f = new Vector3f();

        // XY
        tmp1.subtractBy(start, xoffs);
        tmp2.addBy(start, yoffs);
        getDebugDrawer().drawLine(tmp1, tmp2, color);
        tmp1.addBy(start, yoffs);
        tmp2.addBy(start, xoffs);
        getDebugDrawer().drawLine(tmp1, tmp2, color);
        tmp1.addBy(start, xoffs);
        tmp2.subtractBy(start, yoffs);
        getDebugDrawer().drawLine(tmp1, tmp2, color);
        tmp1.subtractBy(start, yoffs);
        tmp2.subtractBy(start, xoffs);
        getDebugDrawer().drawLine(tmp1, tmp2, color);

        // XZ
        tmp1.subtractBy(start, xoffs);
        tmp2.addBy(start, zoffs);
        getDebugDrawer().drawLine(tmp1, tmp2, color);
        tmp1.addBy(start, zoffs);
        tmp2.addBy(start, xoffs);
        getDebugDrawer().drawLine(tmp1, tmp2, color);
        tmp1.addBy(start, xoffs);
        tmp2.subtractBy(start, zoffs);
        getDebugDrawer().drawLine(tmp1, tmp2, color);
        tmp1.subtractBy(start, zoffs);
        tmp2.subtractBy(start, xoffs);
        getDebugDrawer().drawLine(tmp1, tmp2, color);

        // YZ
        tmp1.subtractBy(start, yoffs);
        tmp2.addBy(start, zoffs);
        getDebugDrawer().drawLine(tmp1, tmp2, color);
        tmp1.addBy(start, zoffs);
        tmp2.addBy(start, yoffs);
        getDebugDrawer().drawLine(tmp1, tmp2, color);
        tmp1.addBy(start, yoffs);
        tmp2.subtractBy(start, zoffs);
        getDebugDrawer().drawLine(tmp1, tmp2, color);
        tmp1.subtractBy(start, zoffs);
        tmp2.subtractBy(start, yoffs);
        getDebugDrawer().drawLine(tmp1, tmp2, color);
    }

    public function debugDrawObject(worldTransform:Transform, shape:CollisionShape, color:Vector3f):Void
	{
        var tmp:Vector3f = new Vector3f();
        var tmp2:Vector3f = new Vector3f();

        // Draw a small simplex at the center of the object
        {
            var start:Vector3f = worldTransform.origin.clone();

            tmp.setTo(1, 0, 0);
            worldTransform.basis.multVecLocal(tmp);
            tmp.addLocal(start);
            tmp2.setTo(1, 0, 0);
            getDebugDrawer().drawLine(start, tmp, tmp2);

            tmp.setTo(0, 1, 0);
            worldTransform.basis.multVecLocal(tmp);
            tmp.addLocal(start);
            tmp2.setTo(0, 1, 0);
            getDebugDrawer().drawLine(start, tmp, tmp2);

            tmp.setTo(0, 0, 1);
            worldTransform.basis.multVecLocal(tmp);
            tmp.addLocal(start);
            tmp2.setTo(0, 0, 1);
            getDebugDrawer().drawLine(start, tmp, tmp2);
        }

        // JAVA TODO: debugDrawObject, note that this commented code is from old version, use actual version when implementing

//		if (shape->getShapeType() == COMPOUND_SHAPE_PROXYTYPE)
//		{
//			const btCompoundShape* compoundShape = static_cast<const btCompoundShape*>(shape);
//			for (int i=compoundShape->getNumChildShapes()-1;i>=0;i--)
//			{
//				btTransform childTrans = compoundShape->getChildTransform(i);
//				const btCollisionShape* colShape = compoundShape->getChildShape(i);
//				debugDrawObject(worldTransform*childTrans,colShape,color);
//			}
//
//		} else
//		{
//			switch (shape->getShapeType())
//			{
//
//			case SPHERE_SHAPE_PROXYTYPE:
//				{
//					const btSphereShape* sphereShape = static_cast<const btSphereShape*>(shape);
//					btScalar radius = sphereShape->getMargin();//radius doesn't include the margin, so draw with margin
//
//					debugDrawSphere(radius, worldTransform, color);
//					break;
//				}
//			case MULTI_SPHERE_SHAPE_PROXYTYPE:
//				{
//					const btMultiSphereShape* multiSphereShape = static_cast<const btMultiSphereShape*>(shape);
//
//					for (int i = multiSphereShape->getSphereCount()-1; i>=0;i--)
//					{
//						btTransform childTransform = worldTransform;
//						childTransform.getOrigin() += multiSphereShape->getSpherePosition(i);
//						debugDrawSphere(multiSphereShape->getSphereRadius(i), childTransform, color);
//					}
//
//					break;
//				}
//			case CAPSULE_SHAPE_PROXYTYPE:
//				{
//					const btCapsuleShape* capsuleShape = static_cast<const btCapsuleShape*>(shape);
//
//					btScalar radius = capsuleShape->getRadius();
//					btScalar halfHeight = capsuleShape->getHalfHeight();
//
//					// Draw the ends
//					{
//						btTransform childTransform = worldTransform;
//						childTransform.getOrigin() = worldTransform * btVector3(0,halfHeight,0);
//						debugDrawSphere(radius, childTransform, color);
//					}
//
//					{
//						btTransform childTransform = worldTransform;
//						childTransform.getOrigin() = worldTransform * btVector3(0,-halfHeight,0);
//						debugDrawSphere(radius, childTransform, color);
//					}
//
//					// Draw some additional lines
//					btVector3 start = worldTransform.getOrigin();
//					getDebugDrawer()->drawLine(start+worldTransform.getBasis() * btVector3(-radius,halfHeight,0),start+worldTransform.getBasis() * btVector3(-radius,-halfHeight,0), color);
//					getDebugDrawer()->drawLine(start+worldTransform.getBasis() * btVector3(radius,halfHeight,0),start+worldTransform.getBasis() * btVector3(radius,-halfHeight,0), color);
//					getDebugDrawer()->drawLine(start+worldTransform.getBasis() * btVector3(0,halfHeight,-radius),start+worldTransform.getBasis() * btVector3(0,-halfHeight,-radius), color);
//					getDebugDrawer()->drawLine(start+worldTransform.getBasis() * btVector3(0,halfHeight,radius),start+worldTransform.getBasis() * btVector3(0,-halfHeight,radius), color);
//
//					break;
//				}
//			case CONE_SHAPE_PROXYTYPE:
//				{
//					const btConeShape* coneShape = static_cast<const btConeShape*>(shape);
//					btScalar radius = coneShape->getRadius();//+coneShape->getMargin();
//					btScalar height = coneShape->getHeight();//+coneShape->getMargin();
//					btVector3 start = worldTransform.getOrigin();
//
//					int upAxis= coneShape->getConeUpIndex();
//
//
//					btVector3	offsetHeight(0,0,0);
//					offsetHeight[upAxis] = height * btScalar(0.5);
//					btVector3	offsetRadius(0,0,0);
//					offsetRadius[(upAxis+1)%3] = radius;
//					btVector3	offset2Radius(0,0,0);
//					offset2Radius[(upAxis+2)%3] = radius;
//
//					getDebugDrawer()->drawLine(start+worldTransform.getBasis() * (offsetHeight),start+worldTransform.getBasis() * (-offsetHeight+offsetRadius),color);
//					getDebugDrawer()->drawLine(start+worldTransform.getBasis() * (offsetHeight),start+worldTransform.getBasis() * (-offsetHeight-offsetRadius),color);
//					getDebugDrawer()->drawLine(start+worldTransform.getBasis() * (offsetHeight),start+worldTransform.getBasis() * (-offsetHeight+offset2Radius),color);
//					getDebugDrawer()->drawLine(start+worldTransform.getBasis() * (offsetHeight),start+worldTransform.getBasis() * (-offsetHeight-offset2Radius),color);
//
//
//
//					break;
//
//				}
//			case CYLINDER_SHAPE_PROXYTYPE:
//				{
//					const btCylinderShape* cylinder = static_cast<const btCylinderShape*>(shape);
//					int upAxis = cylinder->getUpAxis();
//					btScalar radius = cylinder->getRadius();
//					btScalar halfHeight = cylinder->getHalfExtentsWithMargin()[upAxis];
//					btVector3 start = worldTransform.getOrigin();
//					btVector3	offsetHeight(0,0,0);
//					offsetHeight[upAxis] = halfHeight;
//					btVector3	offsetRadius(0,0,0);
//					offsetRadius[(upAxis+1)%3] = radius;
//					getDebugDrawer()->drawLine(start+worldTransform.getBasis() * (offsetHeight+offsetRadius),start+worldTransform.getBasis() * (-offsetHeight+offsetRadius),color);
//					getDebugDrawer()->drawLine(start+worldTransform.getBasis() * (offsetHeight-offsetRadius),start+worldTransform.getBasis() * (-offsetHeight-offsetRadius),color);
//					break;
//				}
//			default:
//				{
//
//					if (shape->isConcave())
//					{
//						btConcaveShape* concaveMesh = (btConcaveShape*) shape;
//
//						//todo pass camera, for some culling
//						btVector3 aabbMax(btScalar(1e30),btScalar(1e30),btScalar(1e30));
//						btVector3 aabbMin(btScalar(-1e30),btScalar(-1e30),btScalar(-1e30));
//
//						DebugDrawcallback drawCallback(getDebugDrawer(),worldTransform,color);
//						concaveMesh->processAllTriangles(&drawCallback,aabbMin,aabbMax);
//
//					}
//
//					if (shape->getShapeType() == CONVEX_TRIANGLEMESH_SHAPE_PROXYTYPE)
//					{
//						btConvexTriangleMeshShape* convexMesh = (btConvexTriangleMeshShape*) shape;
//						//todo: pass camera for some culling			
//						btVector3 aabbMax(btScalar(1e30),btScalar(1e30),btScalar(1e30));
//						btVector3 aabbMin(btScalar(-1e30),btScalar(-1e30),btScalar(-1e30));
//						//DebugDrawcallback drawCallback;
//						DebugDrawcallback drawCallback(getDebugDrawer(),worldTransform,color);
//						convexMesh->getMeshInterface()->InternalProcessAllTriangles(&drawCallback,aabbMin,aabbMax);
//					}
//
//
//					/// for polyhedral shapes
//					if (shape->isPolyhedral())
//					{
//						btPolyhedralConvexShape* polyshape = (btPolyhedralConvexShape*) shape;
//
//						int i;
//						for (i=0;i<polyshape->getNumEdges();i++)
//						{
//							btPoint3 a,b;
//							polyshape->getEdge(i,a,b);
//							btVector3 wa = worldTransform * a;
//							btVector3 wb = worldTransform * b;
//							getDebugDrawer()->drawLine(wa,wb,color);
//
//						}
//
//
//					}
//				}
//			}
//		}
    }

    override public function setConstraintSolver(solver:ConstraintSolver):Void
	{
        if (ownsConstraintSolver)
		{
            //btAlignedFree( m_constraintSolver);
        }
        ownsConstraintSolver = false;
        constraintSolver = solver;
    }

    override public function getConstraintSolver():ConstraintSolver 
	{
        return constraintSolver;
    }

    override public function getNumConstraints():Int
	{
        return constraints.size();
    }

    override public function getConstraint(index:Int):TypedConstraint
	{
        return constraints.getQuick(index);
    }

    // JAVA NOTE: not part of the original api
    override public function getNumActions():Int
	{
        return actions.size();
    }

    // JAVA NOTE: not part of the original api
    override public function getAction(index:Int):ActionInterface
	{
        return actions.getQuick(index);
    }

    public function getSimulationIslandManager():SimulationIslandManager
	{
        return islandManager;
    }

    public inline function getCollisionWorld():CollisionWorld
	{
        return this;
    }

    //public function setNumTasks(numTasks:Int):Void
	//{
    //}
	
	public function setPreTickCallback(callback:InternalTickCallback):Void
	{
		preTickCallback = callback;
	}

    private static function sortConstraintOnIslandPredicate(lhs:TypedConstraint, rhs:TypedConstraint):Int 
	{
		var rIslandId0:Int;
		var lIslandId0:Int;
		rIslandId0 = getConstraintIslandId(rhs);
		lIslandId0 = getConstraintIslandId(lhs);
		return lIslandId0 < rIslandId0 ? -1 : 1;
	}
}

class InplaceSolverIslandCallback implements IslandCallback
{
	public var solverInfo:ContactSolverInfo;
	public var solver:ConstraintSolver;
	public var sortedConstraints:ObjectArrayList<TypedConstraint>;
	public var numConstraints:Int;
	public var debugDrawer:IDebugDraw;
	public var dispatcher:Dispatcher;
	
	public function new()
	{
		
	}

	public function init(solverInfo:ContactSolverInfo, solver:ConstraintSolver, sortedConstraints:ObjectArrayList<TypedConstraint>, numConstraints:Int, debugDrawer:IDebugDraw, dispatcher:Dispatcher):Void
	{
		this.solverInfo = solverInfo;
		this.solver = solver;
		this.sortedConstraints = sortedConstraints;
		this.numConstraints = numConstraints;
		this.debugDrawer = debugDrawer;
		this.dispatcher = dispatcher;
	}

	public function processIsland(bodies:ObjectArrayList<CollisionObject>, numBodies:Int, manifolds:ObjectArrayList<PersistentManifold>, manifolds_offset:Int, numManifolds:Int, islandId:Int):Void
	{
		if (islandId < 0) 
		{
			// we don't split islands, so all constraints/contact manifolds/bodies are passed into the solver regardless the island id
			solver.solveGroup(bodies, numBodies, manifolds, manifolds_offset, numManifolds, sortedConstraints, 0, numConstraints, solverInfo, debugDrawer, dispatcher);
		}
		else 
		{
			// also add all non-contact constraints/joints for this island
			//ObjectArrayList<TypedConstraint> startConstraint = null;
			var startConstraint_idx:Int = -1;
			var numCurConstraints:Int = 0;

			// find the first constraint for this island
			var index:Int = 0;
			for (i in 0...numConstraints) 
			{
				if (DiscreteDynamicsWorld.getConstraintIslandId(sortedConstraints.getQuick(i)) == islandId)
				{
					//startConstraint = &m_sortedConstraints[i];
					//startConstraint = sortedConstraints.subList(i, sortedConstraints.size());
					startConstraint_idx = i;
					break;
				}
				index++;
			}
			
			// count the number of constraints in this island
			while (index < numConstraints) 
			{
				if (DiscreteDynamicsWorld.getConstraintIslandId(sortedConstraints.getQuick(index)) == islandId) 
				{
					numCurConstraints++;
				}
				index++;
			}

			// only call solveGroup if there is some work: avoid virtual function call, its overhead can be excessive
			if ((numManifolds + numCurConstraints) > 0) 
			{
				solver.solveGroup(bodies, numBodies, manifolds, manifolds_offset, numManifolds, sortedConstraints, startConstraint_idx, numCurConstraints, solverInfo, debugDrawer, dispatcher);
			}
		}
	}
}

//class DebugDrawcallback implements TriangleCallback, InternalTriangleIndexCallback 
//{
//		private var debugDrawer:IDebugDraw;
//		private var color:Vector3f = new Vector3f();
//		private var worldTrans:Transform = new Transform();
//
//		public function new(debugDrawer:IDebugDraw, worldTrans:Transform, color:Vector3f) {
//			this.debugDrawer = debugDrawer;
//			this.worldTrans.set(worldTrans);
//			this.color.fromVector3f(color);
//		}
//
//		public function internalProcessTriangleIndex(triangle:Array<Vector3f>, partId:Int, triangleIndex:Int):Void {
//			processTriangle(triangle,partId,triangleIndex);
//		}
//
//		private var wv0:Vector3f = new Vector3f();
//		private var wv1:Vector3f = new Vector3f();
//		private var wv2:Vector3f = new Vector3f();
//
//		public function processTriangle(triangle:Array<Vector3f>, partId:Int, triangleIndex:Int):Void {
//			wv0.fromVector3f(triangle[0]);
//			worldTrans.transform(wv0);
//			wv1.fromVector3f(triangle[1]);
//			worldTrans.transform(wv1);
//			wv2.fromVector3f(triangle[2]);
//			worldTrans.transform(wv2);
//
//			debugDrawer.drawLine(wv0, wv1, color);
//			debugDrawer.drawLine(wv1, wv2, color);
//			debugDrawer.drawLine(wv2, wv0, color);
//		}
//	}

class ClosestNotMeConvexResultCallback extends ClosestConvexResultCallback 
{
	private var me:CollisionObject;
	private var allowedPenetration:Float = 0;
	private var pairCache:OverlappingPairCache;
	private var dispatcher:Dispatcher;

	public function new(me:CollisionObject, fromA:Vector3f, toA:Vector3f, pairCache:OverlappingPairCache, dispatcher:Dispatcher)
	{
		super(fromA, toA);
		this.me = me;
		this.pairCache = pairCache;
		this.dispatcher = dispatcher;
	}

	override public function addSingleResult(convexResult:LocalConvexResult, normalInWorldSpace:Bool):Float 
	{
		if (convexResult.hitCollisionObject == me)
		{
			return 1;
		}

		var linVelA:Vector3f = new Vector3f();
		var linVelB:Vector3f = new Vector3f();
		linVelA.subtractBy(convexToWorld, convexFromWorld);
		linVelB.setTo(0, 0, 0);//toB.getOrigin()-fromB.getOrigin();

		var relativeVelocity:Vector3f = new Vector3f();
		relativeVelocity.subtractBy(linVelA, linVelB);
		// don't report time of impact for motion away from the contact normal (or causes minor penetration)
		if (convexResult.hitNormalLocal.dot(relativeVelocity) >= -allowedPenetration) 
		{
			return 1;
		}

		return super.addSingleResult(convexResult, normalInWorldSpace);
	}

	override public function needsCollision(proxy0:BroadphaseProxy):Bool
	{
		// don't collide with itself
		if (proxy0.clientObject == me)
		{
			return false;
		}

		// don't do CCD when the collision filters are not matching
		if (!super.needsCollision(proxy0))
		{
			return false;
		}

		var otherObj:CollisionObject = cast proxy0.clientObject;

		// call needsResponse, see http://code.google.com/p/bullet/issues/detail?id=179
		if (dispatcher.needsResponse(me, otherObj))
		{
			// don't do CCD when there are already contact points (touching contact/penetration)
			var manifoldArray:ObjectArrayList<PersistentManifold> = new ObjectArrayList<PersistentManifold>();
			var collisionPair:BroadphasePair = pairCache.findPair(me.getBroadphaseHandle(), proxy0);
			if (collisionPair != null)
			{
				if (collisionPair.algorithm != null)
				{
					//manifoldArray.resize(0);
					collisionPair.algorithm.getAllContactManifolds(manifoldArray);
					for (j in 0...manifoldArray.size())
					{
						var manifold:PersistentManifold = manifoldArray.getQuick(j);
						if (manifold.getNumContacts() > 0)
						{
							return false;
						}
					}
				}
			}
		}
		return true;
	}
}