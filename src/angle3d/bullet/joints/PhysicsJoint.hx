package angle3d.bullet.joints;

import com.bulletphysics.dynamics.constraintsolver.TypedConstraint;
import angle3d.bullet.objects.PhysicsRigidBody;
import angle3d.math.Vector3f;

/**
 * <p>PhysicsJoint - Basic Phyiscs Joint</p>

 */
class PhysicsJoint {
	private var constraint:TypedConstraint;
	private var nodeA:PhysicsRigidBody;
	private var nodeB:PhysicsRigidBody;
	private var pivotA:Vector3f = new Vector3f();
	private var pivotB:Vector3f = new Vector3f();
	private var collisionBetweenLinkedBodys:Bool = true;

	/**
	 * @param pivotA local translation of the joint connection point in node A
	 * @param pivotB local translation of the joint connection point in node B
	 */
	public function new(nodeA:PhysicsRigidBody, nodeB:PhysicsRigidBody, pivotA:Vector3f, pivotB:Vector3f) {
		this.nodeA = nodeA;
		this.nodeB = nodeB;
		this.pivotA.copyFrom(pivotA);
		this.pivotB.copyFrom(pivotB);
		nodeA.addJoint(this);
		nodeB.addJoint(this);
	}

	public inline function getAppliedImpulse():Float {
		return constraint.getAppliedImpulse();
	}

	/**
	 * @return the constraint
	 */
	public inline function getObjectId():TypedConstraint {
		return constraint;
	}

	/**
	 * @return the collisionBetweenLinkedBodys
	 */
	public inline function isCollisionBetweenLinkedBodys():Bool {
		return collisionBetweenLinkedBodys;
	}

	/**
	 * toggles collisions between linked bodys<br>
	 * joint has to be removed from and added to PhyiscsSpace to apply this.
	 * @param collisionBetweenLinkedBodys set to false to have no collisions between linked bodys
	 */
	public inline function setCollisionBetweenLinkedBodys(collisionBetweenLinkedBodys:Bool):Void {
		this.collisionBetweenLinkedBodys = collisionBetweenLinkedBodys;
	}

	public inline function getBodyA():PhysicsRigidBody {
		return nodeA;
	}

	public inline function getBodyB():PhysicsRigidBody {
		return nodeB;
	}

	public inline function getPivotA():Vector3f {
		return pivotA;
	}

	public inline function getPivotB():Vector3f {
		return pivotB;
	}

	/**
	 * destroys this joint and removes it from its connected PhysicsRigidBodys joint lists
	 */
	public inline function destroy():Void {
		getBodyA().removeJoint(this);
		getBodyB().removeJoint(this);
	}
}
