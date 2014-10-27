package org.angle3d.bullet.objects;
import com.bulletphysics.collision.dispatch.CollisionFlags;
import com.bulletphysics.dynamics.RigidBody;
import com.bulletphysics.dynamics.RigidBodyConstructionInfo;
import com.bulletphysics.linearmath.Transform;
import org.angle3d.bullet.collision.PhysicsCollisionObject;
import org.angle3d.bullet.collision.shapes.CollisionShape;
import org.angle3d.bullet.collision.shapes.MeshCollisionShape;
import org.angle3d.bullet.joints.PhysicsJoint;
import org.angle3d.bullet.objects.infos.RigidBodyMotionState;
import org.angle3d.bullet.util.Converter;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;

using org.angle3d.utils.ArrayUtil;

/**
 * ...
 * @author weilichuang
 */
class PhysicsRigidBody extends PhysicsCollisionObject
{
	private var constructionInfo:RigidBodyConstructionInfo;
	private var rBody:RigidBody;
    private var motionState:RigidBodyMotionState = new RigidBodyMotionState();
    private var mass:Float = 1.0;
    private var kinematic:Bool = false;
    private var tempVec:vecmath.Vector3f = new vecmath.Vector3f();
    private var tempVec2:vecmath.Vector3f = new vecmath.Vector3f();
    private var tempTrans:Transform = new Transform();
    private var tempMatrix:vecmath.Matrix3f = new vecmath.Matrix3f();
    //TEMP VARIABLES
    private var localInertia:vecmath.Vector3f = new vecmath.Vector3f();
    private var joints:Array<PhysicsJoint> = new Array<PhysicsJoint>();
	
	public var showDebug:Bool = true;

	public function new(shape:CollisionShape, mass:Float = 1.0 ) 
	{
		super();
		this.collisionShape = shape;
		this.mass = mass;
		
		if(shape != null)
			rebuildRigidBody();
	}
	
	/**
     * Builds/rebuilds the phyiscs body when parameters have changed
     */
    private function rebuildRigidBody():Void
	{
        var removed:Bool = false;
        if (Std.is(collisionShape, MeshCollisionShape) && mass != 0)
		{
            throw ("Dynamic rigidbody can not have mesh collision shape!");
        }
		
        if (rBody != null)
		{
            if (rBody.isInWorld()) 
			{
                PhysicsSpace.getPhysicsSpace().remove(this);
                removed = true;
            }
            rBody.destroy();
        }
        preRebuild();
        rBody = new RigidBody();
		rBody.setupRigidBody(constructionInfo);
        postRebuild();
        if (removed) 
		{
            PhysicsSpace.getPhysicsSpace().add(this);
        }
    }

    private function preRebuild():Void
	{
        collisionShape.calculateLocalInertia(mass, localInertia);
        if (constructionInfo == null) 
		{
            constructionInfo = new RigidBodyConstructionInfo(mass, motionState, collisionShape.getCShape(), localInertia);
        }
		else
		{
            constructionInfo.mass = mass;
            constructionInfo.collisionShape = collisionShape.getCShape();
            constructionInfo.motionState = motionState;
        }
    }

    private function postRebuild():Void
	{
        rBody.setUserPointer(this);
        if (mass == 0.0)
		{
            rBody.setCollisionFlags(rBody.getCollisionFlags() | CollisionFlags.STATIC_OBJECT);
        } 
		else
		{
            rBody.setCollisionFlags(rBody.getCollisionFlags() & ~CollisionFlags.STATIC_OBJECT);
        }
    }

    /**
     * @return the motionState
     */
    public function getMotionState():RigidBodyMotionState
	{
        return motionState;
    }

    /**
     * Sets the physics object location
     * @param location the location of the actual physics object
     */
    public function setPhysicsLocation(location:Vector3f):Void
	{
        rBody.getCenterOfMassTransformTo(tempTrans);
        Converter.a2vVector3f(location, tempTrans.origin);
        rBody.setCenterOfMassTransform(tempTrans);
        motionState.setWorldTransform(tempTrans);
    }

    /**
     * Sets the physics object rotation
     * @param rotation the rotation of the actual physics object
     */
    public function setPhysicsRotationWithQuaternion(rotation:Quaternion):Void
	{
        rBody.getCenterOfMassTransformTo(tempTrans);
        Converter.aQuaterion2vMatrix3f(rotation, tempTrans.basis);
        rBody.setCenterOfMassTransform(tempTrans);
        motionState.setWorldTransform(tempTrans);
    }

    /**
     * Sets the physics object rotation
     * @param rotation the rotation of the actual physics object
     */
    public function setPhysicsRotation(rotation:Matrix3f):Void
	{
        rBody.getCenterOfMassTransformTo(tempTrans);
        Converter.a2vMatrix3f(rotation, tempTrans.basis);
        rBody.setCenterOfMassTransform(tempTrans);
        motionState.setWorldTransform(tempTrans);
    }

    /**
     * Gets the physics object location, no object instantiation
     * @param location the location of the actual physics object is stored in this Vector3f
     */
    public function getPhysicsLocation(location:Vector3f = null):Vector3f
	{
        if (location == null) 
		{
            location = new Vector3f();
        }
        return Converter.v2aVector3f(rBody.getCenterOfMassTransform().origin, location);
    }

    /**
     * Gets the physics object rotation as a matrix, no conversions and no object instantiation
     * @param rotation the rotation of the actual physics object is stored in this Matrix3f
     */
    public function getPhysicsRotationMatrix(rotation:Matrix3f = null):Matrix3f
	{
        if (rotation == null) 
		{
            rotation = new Matrix3f();
        }
        return Converter.v2aMatrix3f(rBody.getCenterOfMassTransform().basis, rotation);
    }

    /**
     * Gets the physics object rotation as a quaternion, converts the bullet Matrix3f value
     * @param rotation the rotation of the actual physics object is stored in this Quaternion
     */
    public function getPhysicsRotation(rotation:Quaternion = null):Quaternion
	{
        if (rotation == null) 
		{
            rotation = new Quaternion();
        }
        return Converter.vMatrix3f2Quaterion(rBody.getCenterOfMassTransform().basis, rotation);
    }

    /**
     * Gets the physics object location
     * @param location the location of the actual physics object is stored in this Vector3f
     */
    public function getInterpolatedPhysicsLocation(location:Vector3f = null):Vector3f
	{
        if (location == null)
		{
            location = new Vector3f();
        }
        return Converter.v2aVector3f(rBody.getInterpolationWorldTransform().origin, location);
    }

    /**
     * Gets the physics object rotation
     * @param rotation the rotation of the actual physics object is stored in this Matrix3f
     */
    public function getInterpolatedPhysicsRotation(rotation:Matrix3f = null):Matrix3f
	{
        if (rotation == null)
		{
            rotation = new Matrix3f();
        }
        return Converter.v2aMatrix3f(rBody.getInterpolationWorldTransform().basis, rotation);
    }

    /**
     * Sets the node to kinematic mode. in this mode the node is not affected by physics
     * but affects other physics objects. Its kinetic force is calculated by the amount
     * of movement it is exposed to and its weight.
     * @param kinematic
     */
    public function setKinematic(kinematic:Bool):Void
	{
        this.kinematic = kinematic;
        if (kinematic)
		{
            rBody.setCollisionFlags(rBody.getCollisionFlags() | CollisionFlags.KINEMATIC_OBJECT);
            rBody.setActivationState(com.bulletphysics.collision.dispatch.CollisionObject.DISABLE_DEACTIVATION);
        } 
		else 
		{
            rBody.setCollisionFlags(rBody.getCollisionFlags() & ~CollisionFlags.KINEMATIC_OBJECT);
            rBody.setActivationState(com.bulletphysics.collision.dispatch.CollisionObject.ACTIVE_TAG);
        }
    }

    public function isKinematic():Bool
	{
        return kinematic;
    }

    public function setCcdSweptSphereRadius(radius:Float):Void
	{
        rBody.setCcdSweptSphereRadius(radius);
    }

    /**
     * Sets the amount of motion that has to happen in one physics tick to trigger the continuous motion detection<br/>
     * This avoids the problem of fast objects moving through other objects, set to zero to disable (default)
     * @param threshold
     */
    public function setCcdMotionThreshold(threshold:Float):Void
	{
        rBody.setCcdMotionThreshold(threshold);
    }

    public function getCcdSweptSphereRadius():Float 
	{
        return rBody.getCcdSweptSphereRadius();
    }

    public function getCcdMotionThreshold():Float
	{
        return rBody.getCcdMotionThreshold();
    }

    public function getCcdSquareMotionThreshold():Float
	{
        return rBody.getCcdSquareMotionThreshold();
    }

    public function getMass():Float
	{
        return mass;
    }

    /**
     * Sets the mass of this PhysicsRigidBody, objects with mass=0 are static.
     * @param mass
     */
    public function setMass(mass:Float):Void
	{
        this.mass = mass;
        if (Std.is(collisionShape, MeshCollisionShape) && mass != 0)
		{
            throw ("Dynamic rigidbody can not have mesh collision shape!");
        }
		
        if (collisionShape != null) 
		{
            collisionShape.calculateLocalInertia(mass, localInertia);
        }
        if (rBody != null) 
		{
            rBody.setMassProps(mass, localInertia);
            if (mass == 0.0)
			{
                rBody.setCollisionFlags(rBody.getCollisionFlags() | CollisionFlags.STATIC_OBJECT);
            } 
			else
			{
                rBody.setCollisionFlags(rBody.getCollisionFlags() & ~CollisionFlags.STATIC_OBJECT);
            }
        }
    }

    public function getGravity(gravity:Vector3f = null):Vector3f
	{
        if (gravity == null)
		{
            gravity = new Vector3f();
        }
        ;
        return Converter.v2aVector3f(rBody.getGravity(), gravity);
    }

    /**
     * Set the local gravity of this PhysicsRigidBody<br/>
     * Set this after adding the node to the PhysicsSpace,
     * the PhysicsSpace assigns its current gravity to the physics node when its added.
     * @param gravity the gravity vector to set
     */
    public function setGravity(gravity:Vector3f):Void
	{
        rBody.setGravity(Converter.a2vVector3f(gravity, tempVec));
    }

    public function getFriction():Float
	{
        return rBody.getFriction();
    }

    /**
     * Sets the friction of this physics object
     * @param friction the friction of this physics object
     */
    public function setFriction(friction:Float):Void
	{
        constructionInfo.friction = friction;
        rBody.setFriction(friction);
    }

    public function setDamping(linearDamping:Float, angularDamping:Float):Void 
	{
        constructionInfo.linearDamping = linearDamping;
        constructionInfo.angularDamping = angularDamping;
        rBody.setDamping(linearDamping, angularDamping);
    }

    public function setLinearDamping(linearDamping:Float):Void 
	{
        constructionInfo.linearDamping = linearDamping;
        rBody.setDamping(linearDamping, constructionInfo.angularDamping);
    }

    public function setAngularDamping(angularDamping:Float):Void
	{
        constructionInfo.angularDamping = angularDamping;
        rBody.setDamping(constructionInfo.linearDamping, angularDamping);
    }

    public function getLinearDamping():Float
	{
        return constructionInfo.linearDamping;
    }

    public function getAngularDamping():Float
	{
        return constructionInfo.angularDamping;
    }

    public function getRestitution():Float
	{
        return rBody.getRestitution();
    }

    /**
     * The "bouncyness" of the PhysicsRigidBody, best performance if restitution=0
     * @param restitution
     */
    public function setRestitution(restitution:Float):Void 
	{
        constructionInfo.restitution = restitution;
        rBody.setRestitution(restitution);
    }

    /**
     * Get the current angular velocity of this PhysicsRigidBody
     * @param vec the vector to store the velocity in
     */
    public function getAngularVelocity(vec:Vector3f = null):Vector3f
	{
		if (vec == null)
			vec = new Vector3f();
        return Converter.v2aVector3f(rBody.getAngularVelocity(), vec);
    }

    /**
     * Sets the angular velocity of this PhysicsRigidBody
     * @param vec the angular velocity of this PhysicsRigidBody
     */
    public function setAngularVelocity(vec:Vector3f):Void
	{
        rBody.setAngularVelocity(Converter.a2vVector3f(vec, tempVec));
        rBody.activate();
    }

    /**
     * Get the current linear velocity of this PhysicsRigidBody
     * @param vec the vector to store the velocity in
     */
    public function getLinearVelocity(vec:Vector3f = null):Vector3f
	{
		if (vec == null)
			vec = new Vector3f();
        return Converter.v2aVector3f(rBody.getLinearVelocity(tempVec), vec);
    }

    /**
     * Sets the linear velocity of this PhysicsRigidBody
     * @param vec the linear velocity of this PhysicsRigidBody
     */
    public function setLinearVelocity(vec:Vector3f):Void 
	{
        rBody.setLinearVelocity(Converter.a2vVector3f(vec, tempVec));
        rBody.activate();
    }

    /**
     * Apply a force to the PhysicsRigidBody, only applies force if the next physics update call
     * updates the physics space.<br>
     * To apply an impulse, use applyImpulse, use applyContinuousForce to apply continuous force.
     * @param force the force
     * @param location the location of the force
     */
    public function applyForce(force:Vector3f, location:Vector3f):Void 
	{
        rBody.applyForce(Converter.a2vVector3f(force, tempVec), Converter.a2vVector3f(location, tempVec2));
        rBody.activate();
    }

    /**
     * Apply a force to the PhysicsRigidBody, only applies force if the next physics update call
     * updates the physics space.<br>
     * To apply an impulse, use applyImpulse.
     * 
     * @param force the force
     */
    public function applyCentralForce(force:Vector3f):Void
	{
        rBody.applyCentralForce(Converter.a2vVector3f(force, tempVec));
        rBody.activate();
    }

    /**
     * Apply a force to the PhysicsRigidBody, only applies force if the next physics update call
     * updates the physics space.<br>
     * To apply an impulse, use applyImpulse.
     * 
     * @param torque the torque
     */
    public function applyTorque(torque:Vector3f):Void
	{
        rBody.applyTorque(Converter.a2vVector3f(torque, tempVec));
        rBody.activate();
    }

    /**
     * Apply an impulse to the PhysicsRigidBody in the next physics update.
     * @param impulse applied impulse
     * @param rel_pos location relative to object
     */
    public function applyImpulse( impulse:Vector3f, rel_pos:Vector3f):Void
	{
        rBody.applyImpulse(Converter.a2vVector3f(impulse, tempVec), Converter.a2vVector3f(rel_pos, tempVec2));
        rBody.activate();
    }

    /**
     * Apply a torque impulse to the PhysicsRigidBody in the next physics update.
     * @param vec
     */
    public function applyTorqueImpulse(vec:Vector3f):Void
	{
        rBody.applyTorqueImpulse(Converter.a2vVector3f(vec, tempVec));
        rBody.activate();
    }

    /**
     * Clear all forces from the PhysicsRigidBody
     * 
     */
    public function clearForces():Void 
	{
        rBody.clearForces();
    }

    override public function setCollisionShape(collisionShape:CollisionShape):Void 
	{
        super.setCollisionShape(collisionShape);
        if (Std.is(collisionShape, MeshCollisionShape) && mass != 0)
		{
            throw ("Dynamic rigidbody can not have mesh collision shape!");
        }
        if (rBody == null)
		{
            rebuildRigidBody();
        } 
		else 
		{
            collisionShape.calculateLocalInertia(mass, localInertia);
            constructionInfo.collisionShape = collisionShape.getCShape();
            rBody.setCollisionShape(collisionShape.getCShape());
        }
    }

    /**
     * reactivates this PhysicsRigidBody when it has been deactivated because it was not moving
     */
    public function activate():Void 
	{
        rBody.activate();
    }

    public function isActive():Bool 
	{
        return rBody.isActive();
    }

    /**
     * sets the sleeping thresholds, these define when the object gets deactivated
     * to save ressources. Low values keep the object active when it barely moves
     * @param linear the linear sleeping threshold
     * @param angular the angular sleeping threshold
     */
    public function setSleepingThresholds(linear:Float, angular:Float):Void
	{
        constructionInfo.linearSleepingThreshold = linear;
        constructionInfo.angularSleepingThreshold = angular;
        rBody.setSleepingThresholds(linear, angular);
    }

    public function setLinearSleepingThreshold(linearSleepingThreshold:Float):Void 
	{
        constructionInfo.linearSleepingThreshold = linearSleepingThreshold;
        rBody.setSleepingThresholds(linearSleepingThreshold, constructionInfo.angularSleepingThreshold);
    }

    public function setAngularSleepingThreshold(angularSleepingThreshold:Float):Void 
	{
        constructionInfo.angularSleepingThreshold = angularSleepingThreshold;
        rBody.setSleepingThresholds(constructionInfo.linearSleepingThreshold, angularSleepingThreshold);
    }

    public function getLinearSleepingThreshold():Float
	{
        return constructionInfo.linearSleepingThreshold;
    }

    public function getAngularSleepingThreshold():Float
	{
        return constructionInfo.angularSleepingThreshold;
    }

    public function getAngularFactor():Float
	{
        return rBody.getAngularFactor();
    }

    public function setAngularFactor(factor:Float):Void
	{
        rBody.setAngularFactor(factor);
    }

    /**
     * do not use manually, joints are added automatically
     */
    public function addJoint(joint:PhysicsJoint):Void
	{
        if (!joints.contains(joint))
		{
            joints.push(joint);
        }
    }

    /**
     * 
     */
    public function removeJoint(joint:PhysicsJoint):Void
	{
        joints.remove(joint);
    }

    /**
     * Returns a list of connected joints. This list is only filled when
     * the PhysicsRigidBody is actually added to the physics space or loaded from disk.
     * @return list of active joints connected to this PhysicsRigidBody
     */
    public function getJoints():Array<PhysicsJoint>
	{
        return joints;
    }

    /**
     * used internally
     */
    public function getObjectId():RigidBody
	{
        return rBody;
    }

    /**
     * destroys this PhysicsRigidBody and removes it from memory
     */
    public function destroy():Void
	{
        rBody.destroy();
    }
	
}