package com.bulletphysics.dynamics;

import com.bulletphysics.collision.broadphase.BroadphaseProxy;
import com.bulletphysics.collision.dispatch.CollisionFlags;
import com.bulletphysics.collision.dispatch.CollisionObject;
import com.bulletphysics.collision.dispatch.CollisionObjectType;
import com.bulletphysics.collision.shapes.CollisionShape;
import com.bulletphysics.dynamics.constraintsolver.TypedConstraint;
import com.bulletphysics.linearmath.MatrixUtil;
import com.bulletphysics.linearmath.MiscUtil;
import com.bulletphysics.linearmath.MotionState;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.TransformUtil;
import com.bulletphysics.util.ObjectArrayList;
import com.bulletphysics.util.StackPool;
import org.angle3d.error.Assert;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;

/**
 * RigidBody is the main class for rigid body objects. It is derived from
 * {CollisionObject}, so it keeps reference to {CollisionShape}.<p>
 * <p/>
 * It is recommended for performance and memory use to share {CollisionShape}
 * objects whenever possible.<p>
 * <p/>
 * There are 3 types of rigid bodies:<br>
 * <ol>
 * <li>Dynamic rigid bodies, with positive mass. Motion is controlled by rigid body dynamics.</li>
 * <li>Fixed objects with zero mass. They are not moving (basically collision objects).</li>
 * <li>Kinematic objects, which are objects without mass, but the user can move them. There
 * is on-way interaction, and Bullet calculates a velocity based on the timestep and
 * previous and current world transform.</li>
 * </ol>
 * <p/>
 * Bullet automatically deactivates dynamic rigid bodies, when the velocity is below
 * a threshold for a given time.<p>
 * <p/>
 * Deactivated (sleeping) rigid bodies don't take any processing time, except a minor
 * broadphase collision detection impact (to allow active objects to activate/wake up
 * sleeping objects).
 * 
 
 */
class RigidBody extends CollisionObject
{

	private static inline var MAX_ANGVEL:Float = 1.570796326794896558;// BulletGlobals.SIMD_HALF_PI;

    private var invInertiaTensorWorld:Matrix3f = new Matrix3f();
    private var linearVelocity:Vector3f = new Vector3f();
    private var angularVelocity:Vector3f = new Vector3f();
	
	private var inverseMass:Float;
    private var angularFactor:Float;
    

    private var gravity:Vector3f = new Vector3f();
    private var invInertiaLocal:Vector3f = new Vector3f();
    private var totalForce:Vector3f = new Vector3f();
    private var totalTorque:Vector3f = new Vector3f();

    private var linearDamping:Float;
    private var angularDamping:Float;

    private var additionalDamping:Bool;
    private var additionalDampingFactor:Float;
    private var additionalLinearDampingThresholdSqr:Float;
    private var additionalAngularDampingThresholdSqr:Float;

    private var linearSleepingThreshold:Float;
    private var angularSleepingThreshold:Float;

    // optionalMotionState allows to automatic synchronize the world transform for active objects
    private var optionalMotionState:MotionState;

    // keep track of typed constraints referencing this rigid body
    private var constraintRefs:ObjectArrayList<TypedConstraint> = new ObjectArrayList<TypedConstraint>();

    // for experimental overriding of friction/contact solver func
    public var contactSolverType:Int;
    public var frictionSolverType:Int;

    private static var uniqueId:Int = 0;
    public var debugBodyId:Int;

	public function new()
	{
		super();
	}
	
    public function init(mass:Float, motionState:MotionState, collisionShape:CollisionShape, localInertia:Vector3f = null)
	{
        var cinfo:RigidBodyConstructionInfo = new RigidBodyConstructionInfo(mass, motionState, collisionShape, localInertia);
        setupRigidBody(cinfo);
    }

    public function setupRigidBody(constructionInfo:RigidBodyConstructionInfo):Void
	{
        internalType = CollisionObjectType.RIGID_BODY;

        linearVelocity.setTo(0, 0, 0);
        angularVelocity.setTo(0, 0, 0);
        angularFactor = 1;
        gravity.setTo(0, 0, 0);
        totalForce.setTo(0, 0, 0);
        totalTorque.setTo(0, 0, 0);
        linearDamping = 0;
        angularDamping = 0.5;
        linearSleepingThreshold = constructionInfo.linearSleepingThreshold;
        angularSleepingThreshold = constructionInfo.angularSleepingThreshold;
        optionalMotionState = constructionInfo.motionState;
        contactSolverType = 0;
        frictionSolverType = 0;
        additionalDamping = constructionInfo.additionalDamping;
        additionalDampingFactor = constructionInfo.additionalDampingFactor;
        additionalLinearDampingThresholdSqr = constructionInfo.additionalLinearDampingThresholdSqr;
        additionalAngularDampingThresholdSqr = constructionInfo.additionalAngularDampingThresholdSqr;

        if (optionalMotionState != null)
		{
            optionalMotionState.getWorldTransform(worldTransform);
        } 
		else
		{
            worldTransform.fromTransform(constructionInfo.startWorldTransform);
        }

        interpolationWorldTransform.fromTransform(worldTransform);
        interpolationLinearVelocity.setTo(0, 0, 0);
        interpolationAngularVelocity.setTo(0, 0, 0);

        // moved to CollisionObject
        friction = constructionInfo.friction;
        restitution = constructionInfo.restitution;

        setCollisionShape(constructionInfo.collisionShape);
        debugBodyId = uniqueId++;

        setMassProps(constructionInfo.mass, constructionInfo.localInertia);
        setDamping(constructionInfo.linearDamping, constructionInfo.angularDamping);
        updateInertiaTensor();
    }

    public function destroy():Void
	{
        // No constraints should point to this rigidbody
        // Remove constraints from the dynamics world before you delete the related rigidbodies.
        Assert.assert (constraintRefs.size() == 0);
    }

    public function proceedToTransform(newTrans:Transform):Void
	{
        setCenterOfMassTransform(newTrans);
    }

    /**
     * To keep collision detection and dynamics separate we don't store a rigidbody pointer,
     * but a rigidbody is derived from CollisionObject, so we can safely perform an upcast.
     */
    public static inline function upcast(colObj:CollisionObject):RigidBody
	{
        //if (colObj.getInternalType() == CollisionObjectType.RIGID_BODY) 
		//{
            //return cast colObj;
        //}
        //return null;
		
		return Std.downcast(colObj, RigidBody);
    }

    /**
     * Continuous collision detection needs prediction.
     */
    public function predictIntegratedTransform(timeStep:Float, predictedTransform:Transform):Void
	{
        TransformUtil.integrateTransform(worldTransform, linearVelocity, angularVelocity, timeStep, predictedTransform);
    }

    public function saveKinematicState(timeStep:Float):Void
	{
        //todo: clamp to some (user definable) safe minimum timestep, to limit maximum angular/linear velocities
        if (timeStep != 0) 
		{
            //if we use motionstate to synchronize world transforms, get the new kinematic/animated world transform
            if (getMotionState() != null)
			{
                getMotionState().getWorldTransform(worldTransform);
            }
            //Vector3f linVel = new Vector3f(), angVel = new Vector3f();

            TransformUtil.calculateVelocity(interpolationWorldTransform, worldTransform, timeStep, linearVelocity, angularVelocity);
            interpolationLinearVelocity.copyFrom(linearVelocity);
            interpolationAngularVelocity.copyFrom(angularVelocity);
            interpolationWorldTransform.fromTransform(worldTransform);
            //printf("angular = %f %f %f\n",m_angularVelocity.getX(),m_angularVelocity.getY(),m_angularVelocity.getZ());
        }
    }

    public function applyGravity():Void
	{
        if (isStaticOrKinematicObject())
            return;

        applyCentralForce(gravity);
    }

    public function setGravity(acceleration:Vector3f):Void
	{
        if (inverseMass != 0) 
		{
            gravity.scaleBy(1 / inverseMass, acceleration);
        }
    }

    public inline function getGravityTo(out:Vector3f):Vector3f
	{
        out.copyFrom(gravity);
        return out;
    }
	
	public inline function getGravity():Vector3f
	{
        return gravity;
    }

    public function setDamping(lin_damping:Float, ang_damping:Float):Void
	{
        linearDamping = MiscUtil.GEN_clamped(lin_damping, 0, 1);
        angularDamping = MiscUtil.GEN_clamped(ang_damping, 0, 1);
    }

    public inline function getLinearDamping():Float
	{
        return linearDamping;
    }

    public inline function getAngularDamping():Float
	{
        return angularDamping;
    }

    public inline function getLinearSleepingThreshold():Float
	{
        return linearSleepingThreshold;
    }

    public function getAngularSleepingThreshold():Float
	{
        return angularSleepingThreshold;
    }

    public inline function getAngularFactor():Float
	{
        return angularFactor;
    }

    /**
	 * 减弱速度
     * Damps the velocity, using the given linearDamping and angularDamping.
     */
    public function applyDamping(timeStep:Float):Void
	{
        // On new damping: see discussion/issue report here: http://code.google.com/p/bullet/issues/detail?id=74
        // todo: do some performance comparisons (but other parts of the engine are probably bottleneck anyway

        //#define USE_OLD_DAMPING_METHOD 1
        //#ifdef USE_OLD_DAMPING_METHOD
        //linearVelocity.scale(MiscUtil.GEN_clamped((1f - timeStep * linearDamping), 0f, 1f));
        //angularVelocity.scale(MiscUtil.GEN_clamped((1f - timeStep * angularDamping), 0f, 1f));
        //#else
		if(linearDamping != 0)
			linearVelocity.scaleLocal(Math.pow(1 - linearDamping, timeStep));
		if(angularDamping != 0)
			angularVelocity.scaleLocal(Math.pow(1 - angularDamping, timeStep));
        //#endif

        if (additionalDamping) 
		{
            // Additional damping can help avoiding lowpass jitter motion, help stability for ragdolls etc.
            // Such damping is undesirable, so once the overall simulation quality of the rigid body dynamics system has improved, this should become obsolete
            if ((angularVelocity.lengthSquared < additionalAngularDampingThresholdSqr) &&
				(linearVelocity.lengthSquared < additionalLinearDampingThresholdSqr))
			{
                angularVelocity.scaleLocal(additionalDampingFactor);
                linearVelocity.scaleLocal(additionalDampingFactor);
            }

            var speed:Float = linearVelocity.length;
            if (speed < linearDamping) 
			{
                var dampVel:Float = 0.005;
                if (speed > dampVel)
				{
                    var dir:Vector3f = linearVelocity.clone();
                    dir.normalizeLocal();
                    dir.scaleLocal(dampVel);
                    linearVelocity.subtractLocal(dir);
                }
				else 
				{
                    linearVelocity.setTo(0, 0, 0);
                }
            }

            var angSpeed:Float = angularVelocity.length;
            if (angSpeed < angularDamping)
			{
                var angDampVel:Float = 0.005;
                if (angSpeed > angDampVel)
				{
                    var dir:Vector3f = angularVelocity.clone();
                    dir.normalizeLocal();
                    dir.scaleLocal(angDampVel);
                    angularVelocity.subtractLocal(dir);
                } 
				else 
				{
                    angularVelocity.setTo(0, 0, 0);
                }
            }
        }
    }

    public function setMassProps(mass:Float, inertia:Vector3f):Void
	{
        if (mass == 0) 
		{
            collisionFlags = collisionFlags.add(CollisionFlags.STATIC_OBJECT);
            inverseMass = 0;
        } 
		else
		{
            collisionFlags = collisionFlags.remove(CollisionFlags.STATIC_OBJECT);
            inverseMass = 1 / mass;
        }

        invInertiaLocal.setTo(inertia.x != 0 ? 1 / inertia.x : 0,
                inertia.y != 0 ? 1 / inertia.y : 0,
                inertia.z != 0 ? 1 / inertia.z : 0);
    }

    public inline function getInvMass():Float
	{
        return inverseMass;
    }

    public inline function getInvInertiaTensorWorldTo(out:Matrix3f):Matrix3f
	{
        out.copyFrom(invInertiaTensorWorld);
        return out;
    }
	
	public inline function getInvInertiaTensorWorld():Matrix3f
	{
        return invInertiaTensorWorld;
    }

	private var tmpTorque:Vector3f = new Vector3f();
    public function integrateVelocities(step:Float):Void
	{
        if (isStaticOrKinematicObject()) 
		{
            return;
        }

        linearVelocity.scaleAddBy(inverseMass * step, totalForce, linearVelocity);
		
        invInertiaTensorWorld.multVec(totalTorque, tmpTorque);
        angularVelocity.scaleAddBy(step, tmpTorque, angularVelocity);

        // clamp angular velocity. collision calculations will fail on higher angular velocities
        var angvel:Float = angularVelocity.length;
        if (angvel * step > MAX_ANGVEL) 
		{
            angularVelocity.scaleLocal((MAX_ANGVEL / step) / angvel);
        }
    }

    public function setCenterOfMassTransform(xform:Transform):Void
	{
        if (isStaticOrKinematicObject())
		{
            interpolationWorldTransform.fromTransform(worldTransform);
        } 
		else 
		{
            interpolationWorldTransform.fromTransform(xform);
        }
        getLinearVelocity(interpolationLinearVelocity);
        getAngularVelocityTo(interpolationAngularVelocity);
        worldTransform.fromTransform(xform);
        updateInertiaTensor();
    }

    public function applyCentralForce(force:Vector3f):Void
	{
        totalForce.addLocal(force);
    }

    public inline function getInvInertiaDiagLocalTo(out:Vector3f):Vector3f
	{
        out.copyFrom(invInertiaLocal);
        return out;
    }
	
	public inline function getInvInertiaDiagLocal():Vector3f
	{
        return invInertiaLocal;
    }

    public function setInvInertiaDiagLocal(diagInvInertia:Vector3f):Void
	{
        invInertiaLocal.copyFrom(diagInvInertia);
    }

    public function setSleepingThresholds( linear:Float, angular:Float):Void
	{
        linearSleepingThreshold = linear;
        angularSleepingThreshold = angular;
    }

    public inline function applyTorque(torque:Vector3f):Void
	{
        totalTorque.addLocal(torque);
    }

    public inline function applyForce(force:Vector3f, rel_pos:Vector3f):Void
	{
        applyCentralForce(force);

        tmpVec.crossBy(rel_pos, force);
        applyTorque(tmpVec);
    }

    public inline function applyCentralImpulse(impulse:Vector3f):Void
	{
        linearVelocity.scaleAddBy(inverseMass, impulse, linearVelocity);
    }

    public inline function applyTorqueImpulse(torque:Vector3f):Void
	{
		tmpTorque.copyFrom(torque);
        invInertiaTensorWorld.multVecLocal(tmpTorque);
        angularVelocity.addLocal(tmpTorque);
    }

    public function applyImpulse(impulse:Vector3f, rel_pos:Vector3f):Void
	{
        if (inverseMass != 0)
		{
            applyCentralImpulse(impulse);
            tmpVec.crossBy(rel_pos, impulse);
            applyTorqueImpulse(tmpVec);
        }
    }

    /**
     * Optimization for the iterative solver: avoid calculating constant terms involving inertia, normal, relative position.
     */
    public function internalApplyImpulse(linearComponent:Vector3f, angularComponent:Vector3f, impulseMagnitude:Float):Void
	{
        if (inverseMass != 0)
		{
            linearVelocity.scaleAddBy(impulseMagnitude, linearComponent, linearVelocity);
			if (angularFactor != 0)
			{
				angularVelocity.scaleAddBy(impulseMagnitude * angularFactor, angularComponent, angularVelocity);
			}
        }
    }

    public function clearForces():Void
	{
        totalForce.setTo(0, 0, 0);
        totalTorque.setTo(0, 0, 0);
    }

	private static var tmpMatrix3f:Matrix3f = new Matrix3f();
	private static var tmpMatrix3f2:Matrix3f = new Matrix3f();
    public function updateInertiaTensor():Void
	{
        MatrixUtil.scale(tmpMatrix3f, worldTransform.basis, invInertiaLocal);

		tmpMatrix3f2.copyFrom(worldTransform.basis);
        tmpMatrix3f2.transposeLocal();

        invInertiaTensorWorld.multBy(tmpMatrix3f, tmpMatrix3f2);
    }

    public inline function getCenterOfMassPositionTo(out:Vector3f):Vector3f
	{
        out.copyFrom(worldTransform.origin);
        return out;
    }

	public inline function getCenterOfMassPosition():Vector3f
	{
        return worldTransform.origin;
    }
	
    public inline function getOrientation(out:Quaternion):Quaternion
	{
        MatrixUtil.getRotation(worldTransform.basis, out);
        return out;
    }

    public inline function getCenterOfMassTransformTo(out:Transform):Transform
	{
        out.fromTransform(worldTransform);
        return out;
    }
	
	public inline function getCenterOfMassTransform():Transform
	{
        return worldTransform;
    }

    public inline function getLinearVelocity(out:Vector3f):Vector3f
	{
        out.copyFrom(linearVelocity);
        return out;
    }

    public inline function getAngularVelocityTo(out:Vector3f):Vector3f
	{
        out.copyFrom(angularVelocity);
        return out;
    }
	
	public inline function getAngularVelocity():Vector3f
	{
        return angularVelocity;
    }

    public inline function setLinearVelocity(lin_vel:Vector3f):Void
	{
		#if debug
        Assert.assert (collisionFlags != CollisionFlags.STATIC_OBJECT);
		#end
        linearVelocity.copyFrom(lin_vel);
    }

    public inline function setAngularVelocity(ang_vel:Vector3f):Void
	{
		#if debug
        Assert.assert (collisionFlags != CollisionFlags.STATIC_OBJECT);
		#end
        angularVelocity.copyFrom(ang_vel);
    }

    public inline function getVelocityInLocalPoint(rel_pos:Vector3f, out:Vector3f):Vector3f
	{
        // we also calculate lin/ang velocity for kinematic objects
        out.crossBy(angularVelocity, rel_pos);
        out.addLocal(linearVelocity);
        return out;

        //for kinematic objects, we could also use use:
        //		return 	(m_worldTransform(rel_pos) - m_interpolationWorldTransform(rel_pos)) / m_kinematicTimeStep;
    }

    public inline function translate(v:Vector3f):Void
	{
        worldTransform.origin.addLocal(v);
    }

    public inline function getAabb(aabbMin:Vector3f, aabbMax:Vector3f):Void
	{
        getCollisionShape().getAabb(worldTransform, aabbMin, aabbMax);
    }

    public function computeImpulseDenominator( pos:Vector3f, normal:Vector3f):Float
	{
		var pool:StackPool = StackPool.get();
		
        var r0:Vector3f = pool.getVector3f();
        r0.subtractBy(pos, getCenterOfMassPosition());

        var c0:Vector3f = pool.getVector3f();
        c0.crossBy(r0, normal);

        var tmp:Vector3f = pool.getVector3f();
        MatrixUtil.transposeTransform(tmp, c0, getInvInertiaTensorWorld());

        var vec:Vector3f = pool.getVector3f();
        vec.crossBy(tmp, r0);
		
		pool.release();

        return inverseMass + normal.dot(vec);
    }

	private static var tmpVec:Vector3f = new Vector3f();
    public inline function computeAngularImpulseDenominator(axis:Vector3f):Float
	{
        MatrixUtil.transposeTransform(tmpVec, axis, getInvInertiaTensorWorld());

        return axis.dot(tmpVec);
    }

    public function updateDeactivation(timeStep:Float):Void
	{
        if ((getActivationState() == CollisionObject.ISLAND_SLEEPING) || 
			(getActivationState() == CollisionObject.DISABLE_DEACTIVATION))
		{
            return;
        }
		
        if ((linearVelocity.lengthSquared < linearSleepingThreshold * linearSleepingThreshold) &&
			(angularVelocity.lengthSquared < angularSleepingThreshold * angularSleepingThreshold)) 
		{
            deactivationTime += timeStep;
        } 
		else
		{
            deactivationTime = 0;
            setActivationState(0);
        }
    }

    public function wantsSleeping():Bool
	{
		var state:Int = getActivationState();
		
        if (state == CollisionObject.DISABLE_DEACTIVATION)
		{
            return false;
        }

        // disable deactivation
        if (BulletGlobals.isDeactivationDisabled() || 
			(BulletGlobals.getDeactivationTime() == 0))
		{
            return false;
        }

        if ((state == CollisionObject.ISLAND_SLEEPING) || 
			(state == CollisionObject.WANTS_DEACTIVATION))
		{
            return true;
        }

        if (deactivationTime > BulletGlobals.getDeactivationTime())
		{
            return true;
        }
        return false;
    }

    public inline function getBroadphaseProxy():BroadphaseProxy
	{
        return broadphaseHandle;
    }

    public function setNewBroadphaseProxy(broadphaseProxy:BroadphaseProxy):Void
	{
        this.broadphaseHandle = broadphaseProxy;
    }

    public inline function getMotionState():MotionState
	{
        return optionalMotionState;
    }

    public function setMotionState( motionState:MotionState):Void
	{
        this.optionalMotionState = motionState;
        if (optionalMotionState != null)
		{
            motionState.getWorldTransform(worldTransform);
        }
    }

    public function setAngularFactor(angFac:Float):Void
	{
        angularFactor = angFac;
    }

    /**
     * Is this rigidbody added to a CollisionWorld/DynamicsWorld/Broadphase?
     */
    public function isInWorld():Bool
	{
        return (getBroadphaseProxy() != null);
    }

	override public function checkCollideWithOverride(co:CollisionObject):Bool 
	{
		// TODO: change to cast
        var otherRb:RigidBody = RigidBody.upcast(co);
        if (otherRb == null) 
		{
            return true;
        }

        for (i in 0...constraintRefs.size())
		{
            var c:TypedConstraint = constraintRefs.getQuick(i);
            if (c.getRigidBodyA() == otherRb || c.getRigidBodyB() == otherRb) 
			{
                return false;
            }
        }

        return true;
	}

    public function addConstraintRef(c:TypedConstraint):Void
	{
        var index:Int = constraintRefs.indexOf(c);
        if (index == -1)
		{
            constraintRefs.add(c);
        }

        _checkCollideWith = true;
    }

    public function removeConstraintRef(c:TypedConstraint):Void
	{
        constraintRefs.removeObject(c);
        _checkCollideWith = (constraintRefs.size() > 0);
    }

    public function getConstraintRef(index:Int):TypedConstraint
	{
        return constraintRefs.getQuick(index);
    }

    public function getNumConstraintRefs():Int
	{
        return constraintRefs.size();
    }
	
}