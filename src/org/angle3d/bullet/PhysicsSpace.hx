package org.angle3d.bullet;

import com.bulletphysics.BulletGlobals;
import com.bulletphysics.ContactAddedCallback;
import com.bulletphysics.ContactDestroyedCallback;
import com.bulletphysics.ContactProcessedCallback;
import com.bulletphysics.collision.broadphase.AxisSweep3;
import com.bulletphysics.collision.broadphase.AxisSweep3_32;
import com.bulletphysics.collision.broadphase.BroadphaseInterface;
import com.bulletphysics.collision.broadphase.BroadphaseProxy;
import com.bulletphysics.collision.broadphase.CollisionFilterGroups;
import com.bulletphysics.collision.broadphase.DbvtBroadphase;
import com.bulletphysics.collision.broadphase.OverlapFilterCallback;
import com.bulletphysics.collision.broadphase.SimpleBroadphase;
import com.bulletphysics.collision.dispatch.CollisionDispatcher;
import com.bulletphysics.collision.dispatch.CollisionObject;
import com.bulletphysics.collision.dispatch.CollisionWorld;
import com.bulletphysics.collision.dispatch.CollisionWorld.LocalConvexResult;
import com.bulletphysics.collision.dispatch.CollisionWorld.LocalRayResult;
import com.bulletphysics.collision.dispatch.DefaultCollisionConfiguration;
import com.bulletphysics.collision.dispatch.GhostPairCallback;
import com.bulletphysics.collision.dispatch.PairCachingGhostObject;
import com.bulletphysics.collision.narrowphase.ManifoldPoint;
import com.bulletphysics.collision.shapes.ConvexShape;
import com.bulletphysics.dynamics.DiscreteDynamicsWorld;
import com.bulletphysics.dynamics.DynamicsWorld;
import com.bulletphysics.dynamics.InternalTickCallback;
import com.bulletphysics.dynamics.RigidBody;
import com.bulletphysics.dynamics.constraintsolver.ConstraintSolver;
import com.bulletphysics.dynamics.constraintsolver.SequentialImpulseConstraintSolver;
import com.bulletphysics.dynamics.constraintsolver.TypedConstraint;
import com.bulletphysics.dynamics.vehicle.RaycastVehicle;
import com.bulletphysics.extras.gimpact.GImpactCollisionAlgorithm;
import org.angle3d.bullet.collision.PhysicsCollisionEvent;
import org.angle3d.bullet.collision.PhysicsCollisionEventFactory;
import org.angle3d.bullet.collision.PhysicsCollisionGroupListener;
import org.angle3d.bullet.collision.PhysicsCollisionListener;
import org.angle3d.bullet.collision.PhysicsCollisionObject;
import org.angle3d.bullet.collision.PhysicsRayTestResult;
import org.angle3d.bullet.collision.PhysicsSweepTestResult;
import org.angle3d.bullet.collision.shapes.CollisionShape;
import org.angle3d.bullet.control.PhysicsControl;
import org.angle3d.bullet.control.RigidBodyControl;
import org.angle3d.bullet.joints.PhysicsJoint;
import org.angle3d.bullet.objects.PhysicsCharacter;
import org.angle3d.bullet.objects.PhysicsGhostObject;
import org.angle3d.bullet.objects.PhysicsRigidBody;
import org.angle3d.bullet.objects.PhysicsVehicle;
import org.angle3d.bullet.util.Converter;
import org.angle3d.math.Transform;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Node;
import org.angle3d.scene.Spatial;
import de.polygonal.ds.error.Assert;
import org.angle3d.utils.Logger;

using org.angle3d.utils.ArrayUtil;

/**
 * <p>PhysicsSpace - The central jbullet-jme physics space</p>
 * @author normenhansen
 */
class PhysicsSpace
{
    public static inline var AXIS_X:Int = 0;
    public static inline var AXIS_Y:Int = 1;
    public static inline var AXIS_Z:Int = 2;
	
    private var dynamicsWorld:DiscreteDynamicsWorld = null;
    private var broadphase:BroadphaseInterface;
    private var broadphaseType:BroadphaseType = BroadphaseType.SIMPLE;
    private var dispatcher:CollisionDispatcher;
    private var solver:ConstraintSolver;
    private var collisionConfiguration:DefaultCollisionConfiguration;
	
    private var physicsGhostObjects:Map<PairCachingGhostObject, PhysicsGhostObject> = new Map<PairCachingGhostObject, PhysicsGhostObject>();
    private var physicsCharacters:Map<PairCachingGhostObject, PhysicsCharacter> = new Map<PairCachingGhostObject, PhysicsCharacter>();
    private var physicsBodies:Map<RigidBody, PhysicsRigidBody> = new Map<RigidBody, PhysicsRigidBody>();
    private var physicsJoints:Map<TypedConstraint, PhysicsJoint> = new Map<TypedConstraint, PhysicsJoint>();
    private var physicsVehicles:Map<RaycastVehicle, PhysicsVehicle> = new Map<RaycastVehicle, PhysicsVehicle>();
    
	
	private var physicsGhostObjectList:Array<PhysicsGhostObject> = [];
	private var physicsCharacterList:Array<PhysicsCharacter> = [];
	private var physicsBodyList:Array<PhysicsRigidBody> = [];
	private var physicsJointList:Array<PhysicsJoint> = [];
	private var physicsVehicleList:Array<PhysicsVehicle> = [];
	
	private var collisionGroupListeners:Map<Int, PhysicsCollisionGroupListener> = new Map<Int, PhysicsCollisionGroupListener>();
    private var tickListeners:Array<PhysicsTickListener> = new Array<PhysicsTickListener>();
	
    private var collisionListeners:Array<PhysicsCollisionListener> = new Array<PhysicsCollisionListener>();
    private var collisionEvents:Array<PhysicsCollisionEvent> = new Array<PhysicsCollisionEvent>();
    private var eventFactory:PhysicsCollisionEventFactory = new PhysicsCollisionEventFactory();
    private var worldMin:Vector3f = new Vector3f(-5000, -5000, -5000);
    private var worldMax:Vector3f = new Vector3f(5000, 5000, 5000);
    private var accuracy:Float = 1 / 60;
    private var maxSubSteps:Int = 1;
	
    private var rayVec1:vecmath.Vector3f = new vecmath.Vector3f();
    private var rayVec2:vecmath.Vector3f = new vecmath.Vector3f();
    private var sweepTrans1:com.bulletphysics.linearmath.Transform = new com.bulletphysics.linearmath.Transform();
    private var sweepTrans2:com.bulletphysics.linearmath.Transform = new com.bulletphysics.linearmath.Transform();

    /**
     * Get the current PhysicsSpace <b>running on this thread</b><br/>
     * For parallel physics, this can also be called from the OpenGL thread to receive the PhysicsSpace
     * @return the PhysicsSpace running on this thread
     */
	private static var _instance:PhysicsSpace;
    public static function getPhysicsSpace():PhysicsSpace
	{
        if (_instance == null)
			_instance = new PhysicsSpace();
		return _instance;
    }

    public function new(worldMin:Vector3f = null, worldMax:Vector3f = null, broadphaseType:BroadphaseType = null) 
	{
		_instance = this;
		this.worldMax = worldMin != null ? worldMin : new Vector3f( -10000, -10000, -10000);
		this.worldMax = worldMax != null ? worldMax : new Vector3f( 10000, 10000, 10000);
		this.broadphaseType = broadphaseType != null ? broadphaseType : BroadphaseType.SIMPLE;
		create();
    }
	
    /**
     * Has to be called from the (designated) physics thread
     */
    public function create():Void
	{
        var collisionConfiguration:DefaultCollisionConfiguration = new DefaultCollisionConfiguration();
        dispatcher = new CollisionDispatcher(collisionConfiguration);
		
        switch (broadphaseType)
		{
            case SIMPLE:
                broadphase = new SimpleBroadphase();
            case AXIS_SWEEP_3:
                broadphase = new AxisSweep3(Converter.a2vVector3f(worldMin), Converter.a2vVector3f(worldMax));
            case AXIS_SWEEP_3_32:
                broadphase = new AxisSweep3_32(Converter.a2vVector3f(worldMin), Converter.a2vVector3f(worldMax));
            case DBVT:
                broadphase = new DbvtBroadphase();
        }

        solver = new SequentialImpulseConstraintSolver();

        dynamicsWorld = new DiscreteDynamicsWorld(dispatcher, broadphase, solver, collisionConfiguration);
        dynamicsWorld.setGravity(new vecmath.Vector3f(0, -9.81, 0));

        broadphase.getOverlappingPairCache().setInternalGhostPairCallback(new GhostPairCallback());
        GImpactCollisionAlgorithm.registerAlgorithm(dispatcher);

        //register filter callback for tick / collision
        setTickCallback();
        setContactCallbacks();
        //register filter callback for collision groups
        setOverlapFilterCallback();
    }

    private function setOverlapFilterCallback():Void
	{
        var callback:OverlapFilterCallback = new Angle3dOverlapFilterCallback(this);
        dynamicsWorld.getPairCache().setOverlapFilterCallback(callback);
    }

    private function setTickCallback():Void
	{
        var space:PhysicsSpace = this;
        //var callback2:InternalTickCallback = new Angle3dPreInternalTickCallback(this);
        //dynamicsWorld.setPreTickCallback(callback2);
		
        var callback:InternalTickCallback = new Angle3dInternalTickCallback(this);
        dynamicsWorld.setInternalTickCallback(callback, this);
    }

    private function setContactCallbacks():Void
	{
        BulletGlobals.setContactAddedCallback(new Angle3dContactAddedCallback(this));
		
        BulletGlobals.setContactProcessedCallback(new Angle3dContactProcessedCallback(this));

        BulletGlobals.setContactDestroyedCallback(new Angle3dContactDestroyedCallback(this));
    }

    /**
     * updates the physics space, uses maxSteps<br>
     * @param time the current time value
     * @param maxSteps
     */
    public function update(time:Float, maxSteps:Int = 4)
	{
        if (dynamicsWorld == null)
            return;

        //step simulation
        dynamicsWorld.stepSimulation(time, maxSteps, accuracy);
    }

    public function distributeEvents():Void
	{
        //add collision callbacks
        var clistsize:Int = collisionListeners.length;
        while ( collisionEvents.length > 0 )
		{
            var physicsCollisionEvent:PhysicsCollisionEvent = collisionEvents.pop();
			
            for (i in 0...clistsize)
			{
                collisionListeners[i].collision(physicsCollisionEvent);
            }
            //recycle events
            eventFactory.recycle(physicsCollisionEvent);
        }
    }

    /**
     * adds an object to the physics space
     * @param obj the PhysicsControl or Spatial with PhysicsControl to add
     */
    public function add(obj:Dynamic):Void
	{
        if (obj == null) 
			return;
			
        if (Std.is(obj,PhysicsControl))
		{
            cast(obj,PhysicsControl).setPhysicsSpace(this);
        } 
		else if (Std.is(obj,Spatial)) 
		{
            add(cast(obj,Spatial).getControl(PhysicsControl));
        } 
		else if (Std.is(obj,PhysicsCollisionObject))
		{
            addCollisionObject(cast obj);
        } 
		else if (Std.is(obj,PhysicsJoint)) 
		{
            addJoint(cast obj);
        }
		else 
		{
            throw ("Cannot add this kind of object to the physics space.");
        }
    }

    public function addCollisionObject(obj:PhysicsCollisionObject):Void
	{
        if (Std.is(obj,PhysicsGhostObject)) 
		{
            addGhostObject(cast obj);
        } 
		else if (Std.is(obj,PhysicsRigidBody)) 
		{
            addRigidBody(cast obj);
        } 
		else if (Std.is(obj,PhysicsVehicle)) 
		{
            addRigidBody(cast obj);
        } 
		else if (Std.is(obj,PhysicsCharacter))
		{
            addCharacter(cast obj);
        }
    }

    /**
     * removes an object from the physics space
     *
     * @param obj the PhysicsControl or Spatial with PhysicsControl to remove
     */
    public function remove(obj:Dynamic):Void
	{
        if (obj == null) 
			return;
			
		if (Std.is(obj,PhysicsControl))
		{
            cast(obj,PhysicsControl).setPhysicsSpace(null);
        } 
		else if (Std.is(obj,Spatial)) 
		{
            remove(cast(obj,Spatial).getControl(PhysicsControl));
        } 
		else if (Std.is(obj,PhysicsCollisionObject))
		{
            removeCollisionObject(cast obj);
        } 
		else if (Std.is(obj,PhysicsJoint)) 
		{
            removeJoint(cast obj);
        }
		else 
		{
            throw ("Cannot remove this kind of object from the physics space.");
        }
    }

    public function removeCollisionObject(obj:PhysicsCollisionObject):Void
	{
        if (Std.is(obj, PhysicsGhostObject))
		{
            removeGhostObject(cast obj);
        }
		else if (Std.is(obj, PhysicsRigidBody))
		{
            removeRigidBody(cast obj);
        }
		else if (Std.is(obj, PhysicsCharacter))
		{
            removeCharacter(cast obj);
        }
    }

    /**
     * adds all physics controls and joints in the given spatial node to the physics space
     * (e.g. after loading from disk) - recursive if node
     * @param spatial the rootnode containing the physics objects
     */
    public function addAll(spatial:Spatial):Void
	{
        if (spatial.getControl(RigidBodyControl) != null) 
		{
            var physicsNode:RigidBodyControl = cast spatial.getControl(RigidBodyControl);
            add(physicsNode);
            //add joints with physicsNode as BodyA
            var joints:Array<PhysicsJoint> = physicsNode.getJoints();
			for (i in 0...joints.length)
			{
				var physicsJoint:PhysicsJoint = joints[i];
				if (physicsNode == physicsJoint.getBodyA())
				{
                    //add(physicsJoint.getBodyB());
                    add(physicsJoint);
                }
			}
        } 
		else
		{
            add(spatial);
        }
		
        //recursion
        if (Std.is(spatial, Node))
		{
            var children:Array<Spatial> = cast(spatial, Node).children;
            for (i in 0...children.length)
			{
                addAll(children[i]);
            }
        }
    }

    /**
     * Removes all physics controls and joints in the given spatial from the physics space
     * (e.g. before saving to disk) - recursive if node
     * @param spatial the rootnode containing the physics objects
     */
    public function removeAll(spatial:Spatial):Void
	{
		if (spatial.getControl(RigidBodyControl) != null) 
		{
            var physicsNode:RigidBodyControl = cast spatial.getControl(RigidBodyControl);
			
            //remove joints with physicsNode as BodyA
            var joints:Array<PhysicsJoint> = physicsNode.getJoints();
			for (i in 0...joints.length)
			{
				var physicsJoint:PhysicsJoint = joints[i];
				if (physicsNode == physicsJoint.getBodyA())
				{
                    removeJoint(physicsJoint);
					//removeJoint(physicsJoint.getBodyB());
                }
			}
			
			remove(physicsNode);
        } 
		else if (spatial.getControl(PhysicsControl) != null) 
		{
            remove(spatial);
        }
		
        //recursion
        if (Std.is(spatial, Node))
		{
            var children:Array<Spatial> = cast(spatial, Node).children;
            for (i in 0...children.length)
			{
                removeAll(children[i]);
            }
        }
    }

    private function addGhostObject(node:PhysicsGhostObject):Void
	{
        if (physicsGhostObjects.exists(node.getObjectId()))
		{
            Logger.warn( 'GhostObject $node already exists in PhysicsSpace, cannot add.');
            return;
        }
		
        physicsGhostObjects.set(node.getObjectId(), node);
		physicsGhostObjectList.push(node);
		
        Logger.log('Adding ghost object ${node.getObjectId()} to physics space.');
        dynamicsWorld.addCollisionObject(node.getObjectId());
    }

    private function removeGhostObject(node:PhysicsGhostObject):Void
	{
        if (!physicsGhostObjects.exists(node.getObjectId()))
		{
            Logger.warn( 'GhostObject ${node} does not exist in PhysicsSpace, cannot remove.');
            return;
        }
		
        physicsGhostObjects.remove(node.getObjectId());
		physicsGhostObjectList.remove(node);
		
        Logger.log('Removing ghost object ${node.getObjectId()} from physics space.');
        dynamicsWorld.removeCollisionObject(node.getObjectId());
    }

    private function addCharacter(node:PhysicsCharacter):Void
	{
        if (physicsCharacters.exists(node.getObjectId()))
		{
            Logger.warn( 'Character ${node} already exists in PhysicsSpace, cannot add.');
            return;
        }
		
        physicsCharacters.set(node.getObjectId(), node);
		physicsCharacterList.push(node);
		
        Logger.log("Adding character ${node.getObjectId()} to physics space.");
        dynamicsWorld.addCollisionObject(node.getObjectId(), CollisionFilterGroups.CHARACTER_FILTER, (CollisionFilterGroups.STATIC_FILTER | CollisionFilterGroups.DEFAULT_FILTER));
        dynamicsWorld.addAction(node.getControllerId());
    }

    private function removeCharacter(node:PhysicsCharacter):Void
	{
        if (!physicsCharacters.exists(node.getObjectId()))
		{
            Logger.warn( 'Character ${node} does not exist in PhysicsSpace, cannot remove.');
            return;
        }
		
        physicsCharacters.remove(node.getObjectId());
		physicsCharacterList.remove(node);
		
        Logger.log('Removing character ${node.getObjectId()} from physics space.');
        dynamicsWorld.removeAction(node.getControllerId());
        dynamicsWorld.removeCollisionObject(node.getObjectId());
    }

    private function addRigidBody(node:PhysicsRigidBody):Void
	{
        if (physicsBodies.exists(node.getObjectId()))
		{
            Logger.warn( 'RigidBody ${node} already exists in PhysicsSpace, cannot add.');
            return;
        }
		
        physicsBodies.set(node.getObjectId(), node);
		physicsBodyList.push(node);

        //Workaround
        //It seems that adding a Kinematic RigidBody to the dynamicWorld prevent it from being non kinematic again afterward.
        //so we add it non kinematic, then set it kinematic again.
        var kinematic:Bool = false;
        if (node.isKinematic())
		{
            kinematic = true;
            node.setKinematic(false);
        }
        dynamicsWorld.addRigidBody(node.getObjectId());
        if (kinematic)
		{
            node.setKinematic(true);
        }

        Logger.log('Adding RigidBody ${node.getObjectId()} to physics space.');
        if (Std.is(node,PhysicsVehicle))
		{
            Logger.log('Adding vehicle constraint ${cast(node,PhysicsVehicle).getVehicleId()} to physics space.');
            cast(node, PhysicsVehicle).createVehicle(this);
			
            physicsVehicles.set(cast(node, PhysicsVehicle).getVehicleId(), cast node);
			physicsVehicleList.push(cast node);
			
            dynamicsWorld.addVehicle(cast(node,PhysicsVehicle).getVehicleId());
        }
    }

    private function removeRigidBody(node:PhysicsRigidBody):Void
	{
        if (!physicsBodies.exists(node.getObjectId()))
		{
            Logger.warn( 'RigidBody ${node} does not exist in PhysicsSpace, cannot remove.');
            return;
        }
		
        if (Std.is(node, PhysicsVehicle))
		{
            Logger.log('Removing vehicle constraint ${cast(node,PhysicsVehicle).getVehicleId()} from physics space.');
			
            physicsVehicles.remove(cast(node, PhysicsVehicle).getVehicleId());
			physicsVehicleList.remove(cast node);
            dynamicsWorld.removeVehicle(cast(node,PhysicsVehicle).getVehicleId());
        }
		
        Logger.log('Removing RigidBody ${node.getObjectId()} from physics space.');
        physicsBodies.remove(node.getObjectId());
		physicsBodyList.remove(node);
		
        dynamicsWorld.removeRigidBody(node.getObjectId());
    }

    private function addJoint(joint:PhysicsJoint):Void
	{
        if (physicsJoints.exists(joint.getObjectId()))
		{
            Logger.warn( 'Joint ${joint} already exists in PhysicsSpace, cannot add.');
            return;
        }
		
        Logger.log('Adding Joint ${joint.getObjectId()} to physics space.');
		
        physicsJoints.set(joint.getObjectId(), joint);
		physicsJointList.push(joint);
		
        dynamicsWorld.addConstraint(joint.getObjectId(), !joint.isCollisionBetweenLinkedBodys());
    }

    private function removeJoint(joint:PhysicsJoint):Void
	{
        if (!physicsJoints.exists(joint.getObjectId()))
		{
            Logger.warn( 'Joint ${joint} does not exist in PhysicsSpace, cannot remove.');
            return;
        }
        Logger.log('Removing Joint ${joint.getObjectId()} from physics space.');
		
        physicsJoints.remove(joint.getObjectId());
		physicsJointList.remove(joint);
		
        dynamicsWorld.removeConstraint(joint.getObjectId());
    }
    
    public function getRigidBodyList():Array<PhysicsRigidBody>
	{
        return physicsBodyList;
    }

    public function getGhostObjectList():Array<PhysicsGhostObject>
	{
		return physicsGhostObjectList;
    }
    
    public function getCharacterList():Array<PhysicsCharacter>
	{
        return physicsCharacterList;
    }
    
    public function getJointList():Array<PhysicsJoint>
	{
        return physicsJointList;
    }
    
    public function getVehicleList():Array<PhysicsVehicle>
	{
        return physicsVehicleList;
    }
    
    /**
     * Sets the gravity of the PhysicsSpace, set before adding physics objects!
     * @param gravity
     */
    public function setGravity(gravity:Vector3f):Void
	{
        dynamicsWorld.setGravity(Converter.a2vVector3f(gravity));
    }

    /**
     * Gets the gravity of the PhysicsSpace
     * @param gravity
     */
    public function getGravity(gravity:Vector3f):Vector3f
	{
        var tempVec:vecmath.Vector3f = new vecmath.Vector3f();
        dynamicsWorld.getGravity(tempVec);
        return Converter.v2aVector3f(tempVec, gravity);
    }
    
    /**
     * applies gravity value to all objects
     */
    public function applyGravity():Void
	{
        dynamicsWorld.applyGravity();
    }

    /**
     * clears forces of all objects
     */
    public function clearForces():Void
	{
        dynamicsWorld.clearForces();
    }

    /**
     * Adds the specified listener to the physics tick listeners.
     * The listeners are called on each physics step, which is not necessarily
     * each frame but is determined by the accuracy of the physics space.
     * @param listener
     */
    public function addTickListener(listener:PhysicsTickListener):Void 
	{
        tickListeners.push(listener);
    }

    public function removeTickListener(listener:PhysicsTickListener):Void
	{
        tickListeners.remove(listener);
    }

    /**
     * Adds a CollisionListener that will be informed about collision events
     * @param listener the CollisionListener to add
     */
    public function addCollisionListener(listener:PhysicsCollisionListener):Void
	{
        collisionListeners.push(listener);
    }

    /**
     * Removes a CollisionListener from the list
     * @param listener the CollisionListener to remove
     */
    public function removeCollisionListener(listener:PhysicsCollisionListener):Void
	{
        collisionListeners.remove(listener);
    }

    /**
     * Adds a listener for a specific collision group, such a listener can disable collisions when they happen.<br>
     * There can be only one listener per collision group.
     * @param listener
     * @param collisionGroup
     */
    public function addCollisionGroupListener(listener:PhysicsCollisionGroupListener, collisionGroup:Int):Void
	{
        collisionGroupListeners.set(collisionGroup, listener);
    }

    public function removeCollisionGroupListener(collisionGroup:Int):Void
	{
        collisionGroupListeners.remove(collisionGroup);
    }

    /**
     * Performs a ray collision test and returns the results as a list of PhysicsRayTestResults
     */
    public function rayTest(from:Vector3f, to:Vector3f, results:Array<PhysicsRayTestResult> = null):Array<PhysicsRayTestResult>
	{
		if (results == null)
			results = new Array<PhysicsRayTestResult>();
        dynamicsWorld.rayTest(Converter.a2vVector3f(from, rayVec1), Converter.a2vVector3f(to, rayVec2), new InternalRayListener(results));
        return results;
    }

    

    /**
     * Performs a sweep collision test and returns the results as a list of PhysicsSweepTestResults<br/>
     * You have to use different Transforms for start and end (at least distance > 0.4f).
     * SweepTest will not see a collision if it starts INSIDE an object and is moving AWAY from its center.
     */
    public function sweepTest(shape:CollisionShape, 
							start:org.angle3d.math.Transform, 
							end:org.angle3d.math.Transform,
							results:Array<PhysicsSweepTestResult> = null):Array<PhysicsSweepTestResult>
	{
		if(results == null)
			results = new Array<PhysicsSweepTestResult>();
        if (!Std.is(shape.getCShape(), ConvexShape))
		{
            Logger.warn( "Trying to sweep test with incompatible mesh shape!");
            return results;
        }
        dynamicsWorld.convexSweepTest(cast shape.getCShape(), Converter.a2vTransform(start, sweepTrans1), Converter.a2vTransform(end, sweepTrans2), new InternalSweepListener(results));
        return results;

    }

    /**
     * destroys the current PhysicsSpace so that a new one can be created
     */
    public function destroy():Void
	{
        physicsBodies = new Map<RigidBody,PhysicsRigidBody>();
        physicsJoints = new Map<TypedConstraint,PhysicsJoint>();

        dynamicsWorld.destroy();
        dynamicsWorld = null;
		
		_instance = null;
    }

    /**
     * used internally
     * @return the dynamicsWorld
     */
    public function getDynamicsWorld():DynamicsWorld
	{
        return dynamicsWorld;
    }

    public function getBroadphaseType():BroadphaseType
	{
        return broadphaseType;
    }

    public function setBroadphaseType(broadphaseType:BroadphaseType):Void
	{
        this.broadphaseType = broadphaseType;
    }

    /**
     * Sets the maximum amount of extra steps that will be used to step the physics
     * when the fps is below the physics fps. Doing this maintains determinism in physics.
     * For example a maximum number of 2 can compensate for framerates as low as 30fps
     * when the physics has the default accuracy of 60 fps. Note that setting this
     * value too high can make the physics drive down its own fps in case its overloaded.
     * @param steps The maximum number of extra steps, default is 4.
     */
    public function setMaxSubSteps(steps:Int):Void
	{
        maxSubSteps = steps;
    }

    /**
     * get the current accuracy of the physics computation
     * @return the current accuracy
     */
    public function getAccuracy():Float
	{
        return accuracy;
    }

    /**
     * sets the accuracy of the physics computation, default=1/60s<br>
     * @param accuracy
     */
    public function setAccuracy(accuracy:Float):Void
	{
        this.accuracy = accuracy;
    }

    public function getWorldMin():Vector3f
	{
        return worldMin;
    }

    /**
     * only applies for AXIS_SWEEP broadphase
     * @param worldMin
     */
    public function setWorldMin(worldMin:Vector3f):Void
	{
        this.worldMin.copyFrom(worldMin);
    }

    public function getWorldMax():Vector3f
	{
        return worldMax;
    }

    /**
     * only applies for AXIS_SWEEP broadphase
     * @param worldMax
     */
    public function setWorldMax(worldMax:Vector3f):Void
	{
        this.worldMax.copyFrom(worldMax);
    }
}

@:access(org.angle3d.bullet.PhysicsSpace.collisionGroupListeners)
class Angle3dOverlapFilterCallback implements OverlapFilterCallback
{
	private var space:PhysicsSpace;
	private var collisionGroupListeners:Map<Int, PhysicsCollisionGroupListener>;
	public function new(space:PhysicsSpace)
	{
		this.space = space;
		collisionGroupListeners = this.space.collisionGroupListeners;
	}
	
	public function needBroadphaseCollision(bp:BroadphaseProxy, bp1:BroadphaseProxy):Bool 
	{
		var collides:Bool = (bp.collisionFilterGroup & bp1.collisionFilterMask) != 0;
		if (collides)
		{
			collides = (bp1.collisionFilterGroup & bp.collisionFilterMask) != 0;
		}
		
		if (collides)
		{
			#if debug
			Assert.assert(Std.is(bp.clientObject, com.bulletphysics.collision.dispatch.CollisionObject)
						&& Std.is(bp1.clientObject, com.bulletphysics.collision.dispatch.CollisionObject));
			#end
					
						
			var colOb:com.bulletphysics.collision.dispatch.CollisionObject = cast bp.clientObject;
			var colOb1:com.bulletphysics.collision.dispatch.CollisionObject = cast bp1.clientObject;
			
			#if debug
			Assert.assert (colOb.getUserPointer() != null && colOb1.getUserPointer() != null);
			#end
			
			var collisionObject:PhysicsCollisionObject = cast colOb.getUserPointer();
			var collisionObject1:PhysicsCollisionObject = cast colOb1.getUserPointer();
			var group:Int = collisionObject.getCollisionGroup();
			var group1:Int = collisionObject1.getCollisionGroup();
			if ((collisionObject.getCollideWithGroups() & group1) > 0 ||
				(collisionObject1.getCollideWithGroups() & group) > 0)
			{
				var listener:PhysicsCollisionGroupListener = collisionGroupListeners.get(group);
				var listener1:PhysicsCollisionGroupListener = collisionGroupListeners.get(group1);
				if (listener != null)
				{
					return listener.collide(collisionObject, collisionObject1);
				}
				else if (listener1 != null)
				{
					return listener1.collide(collisionObject, collisionObject1);
				}
				return true;
			}
			else
			{
				return false;
			}
		}
		return collides;
	}
}

@:access(org.angle3d.bullet.PhysicsSpace.tickListeners)
class Angle3dPreInternalTickCallback implements InternalTickCallback
{
	private var space:PhysicsSpace;
	private var tickListeners:Array<PhysicsTickListener>;
	public function new(space:PhysicsSpace)
	{
		this.space = space;
		tickListeners = space.tickListeners;
	}
	
	public function internalTick(world:DynamicsWorld, timeStep:Float):Void 
	{
		for (i in 0...tickListeners.length)
		{
			var physicsTickCallback:PhysicsTickListener = tickListeners[i];
			physicsTickCallback.prePhysicsTick(space, timeStep);
		}
	}
}

@:access(org.angle3d.bullet.PhysicsSpace.tickListeners)
class Angle3dInternalTickCallback implements InternalTickCallback
{
	private var space:PhysicsSpace;
	private var tickListeners:Array<PhysicsTickListener>;
	public function new(space:PhysicsSpace)
	{
		this.space = space;
		tickListeners = space.tickListeners;
	}
	
	public function internalTick(world:DynamicsWorld, timeStep:Float):Void 
	{
		for (i in 0...tickListeners.length)
		{
			var physicsTickCallback:PhysicsTickListener = tickListeners[i];
			physicsTickCallback.physicsTick(space, timeStep);
		}
	}
}

class Angle3dContactAddedCallback implements ContactAddedCallback
{
	private var space:PhysicsSpace;
	public function new(space:PhysicsSpace)
	{
		this.space = space;
	}
	
	public function contactAdded(cp:ManifoldPoint, colObj0:CollisionObject, partId0:Int, index0:Int, colObj1:CollisionObject, partId1:Int, index1:Int):Bool 
	{
		Logger.log("contact added");
		return true;
	}
}

class Angle3dContactProcessedCallback implements ContactProcessedCallback
{
	private var space:PhysicsSpace;
	public function new(space:PhysicsSpace)
	{
		this.space = space;
	}
	
	@:access(org.angle3d.bullet.PhysicsSpace.eventFactory)
	@:access(org.angle3d.bullet.PhysicsSpace.collisionEvents)
	public function contactProcessed(cp:ManifoldPoint, body0:Dynamic, body1:Dynamic):Bool 
	{
		if (Std.is(body0,CollisionObject) && Std.is(body1,CollisionObject))
		{
			space.collisionEvents.push(space.eventFactory.getEvent(PhysicsCollisionEvent.TYPE_PROCESSED, 
																cast body0.getUserPointer(),
																cast body1.getUserPointer(), cp));
		}
		return true;
	}
}

class Angle3dContactDestroyedCallback implements ContactDestroyedCallback
{
	private var space:PhysicsSpace;
	public function new(space:PhysicsSpace)
	{
		this.space = space;
	}
	
	public function contactDestroyed(userPersistentData:Dynamic):Bool 
	{
		Logger.log("contact destroyed");
		return true;
	}
}

class InternalRayListener extends CollisionWorld.RayResultCallback
{
	private var results:Array<PhysicsRayTestResult>;

	public function new(results:Array<PhysicsRayTestResult>)
	{
		super();
		this.results = results;
	}
	
	override public function addSingleResult(rayResult:LocalRayResult, normalInWorldSpace:Bool):Float
	{
		var obj:PhysicsCollisionObject = cast rayResult.collisionObject.getUserPointer();
		results.push(new PhysicsRayTestResult(obj, Converter.v2aVector3f(rayResult.hitNormalLocal), rayResult.hitFraction, normalInWorldSpace));
		return rayResult.hitFraction;
	}
}

class InternalSweepListener extends CollisionWorld.ConvexResultCallback 
{

	private var results:Array<PhysicsSweepTestResult>;

	public function new(results:Array<PhysicsSweepTestResult>)
	{
		super();
		this.results = results;
	}
	
	override public function addSingleResult(convexResult:LocalConvexResult, normalInWorldSpace:Bool):Float
	{
		var obj:PhysicsCollisionObject = cast convexResult.hitCollisionObject.getUserPointer();
		results.push(new PhysicsSweepTestResult(obj, Converter.v2aVector3f(convexResult.hitNormalLocal), convexResult.hitFraction, normalInWorldSpace));
		return convexResult.hitFraction;
	}
}