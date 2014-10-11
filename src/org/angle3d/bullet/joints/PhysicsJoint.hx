package org.angle3d.bullet.joints;

import com.bulletphysics.dynamics.constraintsolver.TypedConstraint;
import org.angle3d.bullet.objects.PhysicsRigidBody;
import org.angle3d.math.Vector3f;

/**
 * <p>PhysicsJoint - Basic Phyiscs Joint</p>
 * @author normenhansen
 */
class PhysicsJoint
{
    private var constraint:TypedConstraint;
    private var nodeA:PhysicsRigidBody;
    private var nodeB:PhysicsRigidBody;
    private var pivotA:Vector3f;
    private var pivotB:Vector3f;
    private var collisionBetweenLinkedBodys:Bool = true;

    /**
     * @param pivotA local translation of the joint connection point in node A
     * @param pivotB local translation of the joint connection point in node B
     */
    public function new(nodeA:PhysicsRigidBody, nodeB:PhysicsRigidBody, pivotA:Vector3f, pivotB:Vector3f)
	{
        this.nodeA = nodeA;
        this.nodeB = nodeB;
        this.pivotA = pivotA;
        this.pivotB = pivotB;
        nodeA.addJoint(this);
        nodeB.addJoint(this);
    }

    public function getAppliedImpulse():Float
	{
        return constraint.getAppliedImpulse();
    }

    /**
     * @return the constraint
     */
    public function getObjectId():TypedConstraint
	{
        return constraint;
    }

    /**
     * @return the collisionBetweenLinkedBodys
     */
    public function isCollisionBetweenLinkedBodys():Bool
	{
        return collisionBetweenLinkedBodys;
    }

    /**
     * toggles collisions between linked bodys<br>
     * joint has to be removed from and added to PhyiscsSpace to apply this.
     * @param collisionBetweenLinkedBodys set to false to have no collisions between linked bodys
     */
    public function setCollisionBetweenLinkedBodys(collisionBetweenLinkedBodys:Bool):Void
	{
        this.collisionBetweenLinkedBodys = collisionBetweenLinkedBodys;
    }

    public function getBodyA():PhysicsRigidBody
	{
        return nodeA;
    }

    public function getBodyB():PhysicsRigidBody
	{
        return nodeB;
    }

    public function getPivotA():Vector3f
	{
        return pivotA;
    }

    public function getPivotB():Vector3f
	{
        return pivotB;
    }

    /**
     * destroys this joint and removes it from its connected PhysicsRigidBodys joint lists
     */
    public function destroy():Void
	{
        getBodyA().removeJoint(this);
        getBodyB().removeJoint(this);
    }
}
