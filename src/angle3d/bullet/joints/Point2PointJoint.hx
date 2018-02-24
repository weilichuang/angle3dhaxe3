package angle3d.bullet.joints;

import com.bulletphysics.dynamics.constraintsolver.Point2PointConstraint;
import angle3d.bullet.objects.PhysicsRigidBody;
import angle3d.bullet.util.Converter;
import angle3d.math.Vector3f;

/**
 * <i>From bullet manual:</i><br>
 * Point to point constraint, also known as ball socket joint limits the translation
 * so that the local pivot points of 2 rigidbodies match in worldspace.
 * A chain of rigidbodies can be connected using this constraint.

 */
class Point2PointJoint extends PhysicsJoint {
	/**
	 * @param pivotA local translation of the joint connection point in node A
	 * @param pivotB local translation of the joint connection point in node B
	 */
	public function new(nodeA:PhysicsRigidBody, nodeB:PhysicsRigidBody, pivotA:Vector3f, pivotB:Vector3f) {
		super(nodeA, nodeB, pivotA, pivotB);
		createJoint();
	}

	public function setDamping(value:Float):Void {
		cast(constraint,Point2PointConstraint).setting.damping = value;
	}

	public function setImpulseClamp(value:Float) {
		cast(constraint,Point2PointConstraint).setting.impulseClamp = value;
	}

	public function setTau(value:Float):Void {
		cast(constraint,Point2PointConstraint).setting.tau = value;
	}

	public function getDamping():Float {
		return cast(constraint,Point2PointConstraint).setting.damping;
	}

	public function getImpulseClamp():Float {
		return cast(constraint,Point2PointConstraint).setting.impulseClamp;
	}

	public function getTau():Float {
		return cast(constraint,Point2PointConstraint).setting.tau;
	}

	private function createJoint():Void {
		constraint = new Point2PointConstraint();
		cast(constraint,Point2PointConstraint).init2(nodeA.getObjectId(), nodeB.getObjectId(), pivotA, pivotB);
	}
}
