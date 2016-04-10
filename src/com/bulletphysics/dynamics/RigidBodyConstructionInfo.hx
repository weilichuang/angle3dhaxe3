package com.bulletphysics.dynamics;
import com.bulletphysics.collision.shapes.CollisionShape;
import com.bulletphysics.linearmath.MotionState;
import com.bulletphysics.linearmath.Transform;
import org.angle3d.math.Vector3f;

/**
 * RigidBodyConstructionInfo provides information to create a rigid body.<p>
 * <p/>
 * Setting mass to zero creates a fixed (non-dynamic) rigid body. For dynamic objects,
 * you can use the collision shape to approximate the local inertia tensor, otherwise
 * use the zero vector (default argument).<p>
 * <p/>
 * You can use {MotionState} to synchronize the world transform
 * between physics and graphics objects. And if the motion state is provided, the rigid
 * body will initialize its initial world transform from the motion state,
 * {#startWorldTransform startWorldTransform} is only used when you don't provide
 * a motion state.
 * 
 
 */
class RigidBodyConstructionInfo
{

	public var mass:Float;

    /**
     * When a motionState is provided, the rigid body will initialize its world transform
     * from the motion state. In this case, startWorldTransform is ignored.
     */
    public var motionState:MotionState;
    public var startWorldTransform:Transform = new Transform();

    public var collisionShape:CollisionShape;
    public var localInertia:Vector3f = new Vector3f();
    public var linearDamping:Float = 0;
    public var angularDamping:Float = 0;

    /**
     * Best simulation results when friction is non-zero.
     */
    public var friction:Float = 0.5;
    /**
     * Best simulation results using zero restitution.
     */
    public var restitution:Float = 0;

    public var linearSleepingThreshold:Float = 0.8;
    public var angularSleepingThreshold:Float = 1.0;

    /**
     * Additional damping can help avoiding lowpass jitter motion, help stability for ragdolls etc.
     * Such damping is undesirable, so once the overall simulation quality of the rigid body dynamics
     * system has improved, this should become obsolete.
     */
    public var additionalDamping:Bool = false;
    public var additionalDampingFactor:Float = 0.005;
    public var additionalLinearDampingThresholdSqr:Float = 0.01;
    public var additionalAngularDampingThresholdSqr:Float = 0.01;
    public var additionalAngularDampingFactor:Float = 0.01;

    public function new(mass:Float, motionState:MotionState, collisionShape:CollisionShape, localInertia:Vector3f = null)
	{
        this.mass = mass;
        this.motionState = motionState;
        this.collisionShape = collisionShape;
		
		if(localInertia != null)
			this.localInertia.copyFrom(localInertia);
		else
			this.localInertia.setTo(0, 0, 0);

        startWorldTransform.setIdentity();
    }
	
}