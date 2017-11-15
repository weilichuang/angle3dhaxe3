package org.angle3d.bullet.joints;

import com.bulletphysics.dynamics.constraintsolver.HingeConstraint;
import org.angle3d.bullet.objects.PhysicsRigidBody;
import org.angle3d.bullet.util.Converter;
import org.angle3d.math.Vector3f;

/**
 * <i>From bullet manual:</i><br>
 * Hinge constraint, or revolute joint restricts two additional angular degrees of freedom,
 * so the body can only rotate around one axis, the hinge axis.
 * This can be useful to represent doors or wheels rotating around one axis.
 * The user can specify limits and motor for the hinge.

 */
class HingeJoint extends PhysicsJoint {

	private var axisA:Vector3f;
	private var axisB:Vector3f;
	private var angularOnly:Bool = false;
	private var biasFactor:Float = 0.3;
	private var relaxationFactor:Float = 1.0;
	private var limitSoftness:Float = 0.9;
	/**
	 * Creates a new HingeJoint
	 * @param pivotA local translation of the joint connection point in node A
	 * @param pivotB local translation of the joint connection point in node B
	 */
	public function new(nodeA:PhysicsRigidBody, nodeB:PhysicsRigidBody, pivotA:Vector3f, pivotB:Vector3f,
						axisA:Vector3f = null, axisB:Vector3f = null) {
		super(nodeA, nodeB, pivotA, pivotB);
		this.axisA = axisA;
		this.axisB = axisB;
		createJoint();
	}

	/**
	 * Enables the motor.
	 * @param enable if true, motor is enabled.
	 * @param targetVelocity the target velocity of the rotation.
	 * @param maxMotorImpulse the max force applied to the hinge to rotate it.
	 */
	public function enableMotor(enable:Bool, targetVelocity:Float, maxMotorImpulse:Float):Void {
		cast(constraint,HingeConstraint).enableAngularMotor(enable, targetVelocity, maxMotorImpulse);
	}

	/**
	 * Sets the limits of this joint.
	 * If you're above the softness, velocities that would shoot through the actual limit are slowed down. The bias be in the range of 0.2 - 0.5.
	 * @param low the low limit in radians.
	 * @param high the high limit in radians.
	 * @param _softness the factor at which the velocity error correction starts operating,i.e a softness of 0.9 means that the vel. corr starts at 90% of the limit range.
	 * @param _biasFactor the magnitude of the position correction. It tells you how strictly the position error (drift ) is corrected.
	 * @param _relaxationFactor the rate at which velocity errors are corrected. This can be seen as the strength of the limits. A low value will make the the limits more spongy.
	 */
	public function setLimit(low:Float, high:Float, _softness:Float = 0.9, _biasFactor:Float = 0.3, _relaxationFactor:Float = 1.0):Void {
		biasFactor = _biasFactor;
		relaxationFactor = _relaxationFactor;
		limitSoftness = _softness;
		cast(constraint,HingeConstraint).setLimit(low, high, _softness, _biasFactor, _relaxationFactor);
	}

	public function getUpperLimit():Float {
		return cast(constraint,HingeConstraint).getUpperLimit();
	}

	public function getLowerLimit():Float {
		return cast(constraint,HingeConstraint).getLowerLimit();
	}

	public function setAngularOnly(angularOnly:Bool):Void {
		this.angularOnly = angularOnly;
		cast(constraint,HingeConstraint).setAngularOnly(angularOnly);
	}

	public function getHingeAngle():Float {
		return cast(constraint,HingeConstraint).getHingeAngle();
	}

	private function createJoint():Void {
		constraint = new HingeConstraint();//
		cast(constraint,HingeConstraint).init2(nodeA.getObjectId(), nodeB.getObjectId(),
		pivotA, pivotB,
		axisA, axisB);
	}
}
