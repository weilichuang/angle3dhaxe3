package org.angle3d.bullet.joints;

import com.bulletphysics.dynamics.constraintsolver.ConeTwistConstraint;
import com.bulletphysics.linearmath.Transform;
import org.angle3d.bullet.objects.PhysicsRigidBody;
import org.angle3d.bullet.util.Converter;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Vector3f;

/**
 * <i>From bullet manual:</i><br>
 * To create ragdolls, the conve twist constraint is very useful for limbs like the upper arm.
 * It is a special point to point constraint that adds cone and twist axis limits.
 * The x-axis serves as twist axis.
 */
class ConeJoint extends PhysicsJoint 
{

    private var rotA:Matrix3f = new Matrix3f();
	private var rotB:Matrix3f = new Matrix3f();
    private var swingSpan1:Float = 1e30;
    private var swingSpan2:Float = 1e30;
    private var twistSpan:Float = 1e30;
    private var angularOnly:Bool = false;

    /**
     * @param pivotA local translation of the joint connection point in node A
     * @param pivotB local translation of the joint connection point in node B
     */
    public function new(nodeA:PhysicsRigidBody, nodeB:PhysicsRigidBody, pivotA:Vector3f, pivotB:Vector3f,
						rotA:Matrix3f = null, rotB:Matrix3f = null)
	{
        super(nodeA, nodeB, pivotA, pivotB);
		
		if (rotA != null)
			this.rotA.copyFrom(rotA);
		
		if (rotB != null)
			this.rotB.copyFrom(rotB);

        createJoint();
    }

    public function setLimit(swingSpan1:Float, swingSpan2:Float, twistSpan:Float):Void
	{
        this.swingSpan1 = swingSpan1;
        this.swingSpan2 = swingSpan2;
        this.twistSpan = twistSpan;
        cast(constraint,ConeTwistConstraint).setLimit(swingSpan1, swingSpan2, twistSpan);
    }

    public function setAngularOnly(value:Bool):Void
	{
        angularOnly = value;
        cast(constraint,ConeTwistConstraint).setAngularOnly(value);
    }

    private function createJoint():Void
	{
		var tmpMatrix3:org.angle3d.math.Matrix3f = new org.angle3d.math.Matrix3f();
        var transA:Transform = new Transform();
		transA.fromMatrix3f(rotA);
		
        transA.origin.copyFrom(pivotA);
        transA.basis.copyFrom(rotA);

        var transB:Transform = new Transform();
		transB.fromMatrix3f(rotB);
        transB.origin.copyFrom(pivotB);
        transB.basis.copyFrom(rotB);

        constraint = new ConeTwistConstraint();//
		cast(constraint,ConeTwistConstraint).init2(nodeA.getObjectId(), nodeB.getObjectId(), transA, transB);
        cast(constraint,ConeTwistConstraint).setLimit(swingSpan1, swingSpan2, twistSpan);
        cast(constraint,ConeTwistConstraint).setAngularOnly(angularOnly);
    }
}
