package org.angle3d.bullet.joints;

import com.bulletphysics.dynamics.constraintsolver.Generic6DofConstraint;
import org.angle3d.bullet.joints.motors.RotationalLimitMotor;
import org.angle3d.bullet.joints.motors.TranslationalLimitMotor;
import com.bulletphysics.linearmath.Transform;
import org.angle3d.bullet.objects.PhysicsRigidBody;
import org.angle3d.bullet.util.Converter;
import org.angle3d.math.FastMath;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Vector3f;

/**
 * <i>From bullet manual:</i><br>
 * This generic constraint can emulate a variety of standard constraints,
 * by configuring each of the 6 degrees of freedom (dof).
 * The first 3 dof axis are linear axis, which represent translation of rigidbodies,
 * and the latter 3 dof axis represent the angular motion. Each axis can be either locked,
 * free or limited. On construction of a new btGeneric6DofConstraint, all axis are locked.
 * Afterwards the axis can be reconfigured. Note that several combinations that
 * include free and/or limited angular degrees of freedom are undefined.

 */
class SixDofJoint extends PhysicsJoint 
{

    private var useLinearReferenceFrameA:Bool = true;
    private var rotationalMotors:Array<RotationalLimitMotor> = new Array<RotationalLimitMotor>();
    private var translationalMotor:TranslationalLimitMotor;
    private var angularUpperLimit:Vector3f = new Vector3f(FastMath.POSITIVE_INFINITY,FastMath.POSITIVE_INFINITY,FastMath.POSITIVE_INFINITY);
    private var angularLowerLimit:Vector3f = new Vector3f(FastMath.NEGATIVE_INFINITY,FastMath.NEGATIVE_INFINITY,FastMath.NEGATIVE_INFINITY);
    private var linearUpperLimit:Vector3f = new Vector3f(FastMath.POSITIVE_INFINITY,FastMath.POSITIVE_INFINITY,FastMath.POSITIVE_INFINITY);
    private var linearLowerLimit:Vector3f = new Vector3f(FastMath.NEGATIVE_INFINITY,FastMath.NEGATIVE_INFINITY,FastMath.NEGATIVE_INFINITY);

    /**
     * @param pivotA local translation of the joint connection point in node A
     * @param pivotB local translation of the joint connection point in node B
     */
	public function new(nodeA:PhysicsRigidBody, nodeB:PhysicsRigidBody, pivotA:Vector3f, pivotB:Vector3f,
						rotA:Matrix3f = null, rotB:Matrix3f = null, useLinearReferenceFrameA:Bool = true)
    {
        super(nodeA, nodeB, pivotA, pivotB);
		
        this.useLinearReferenceFrameA = useLinearReferenceFrameA;
		
		if (rotA == null)
			rotA = new Matrix3f();
		if (rotB == null)
			rotB = new Matrix3f();

        var transA:Transform = new Transform();
		transA.fromMatrix3f(rotA);
        transA.origin.copyFrom(pivotA);
        transA.basis.copyFrom(rotA);

        var transB:Transform = new Transform();
		transB.fromMatrix3f(rotB);
        transB.origin.copyFrom(pivotB);
        transB.basis.copyFrom(rotB);

        constraint = new Generic6DofConstraint();
		cast(constraint,Generic6DofConstraint).init2(nodeA.getObjectId(), nodeB.getObjectId(), transA, transB, useLinearReferenceFrameA);
        gatherMotors();
    }

    private function gatherMotors():Void 
	{
        for (i in 0...3)
		{
            var rmot:RotationalLimitMotor = new RotationalLimitMotor(cast(constraint,Generic6DofConstraint).getRotationalLimitMotor(i));
            rotationalMotors.push(rmot);
        }
        translationalMotor = new TranslationalLimitMotor(cast(constraint,Generic6DofConstraint).getTranslationalLimitMotor());
    }

    /**
     * returns the TranslationalLimitMotor of this 6DofJoint which allows
     * manipulating the translational axis
     * @return the TranslationalLimitMotor
     */
    public function getTranslationalLimitMotor():TranslationalLimitMotor
	{
        return translationalMotor;
    }

    /**
     * returns one of the three RotationalLimitMotors of this 6DofJoint which
     * allow manipulating the rotational axes
     * @param index the index of the RotationalLimitMotor
     * @return the RotationalLimitMotor at the given index
     */
    public function getRotationalLimitMotor(index:Int):RotationalLimitMotor
	{
        return rotationalMotors[index];
    }

    public function setLinearUpperLimit(vector:Vector3f):Void 
	{
        linearUpperLimit.copyFrom(vector);
        cast(constraint,Generic6DofConstraint).setLinearUpperLimit(vector);
    }

    public function setLinearLowerLimit(vector:Vector3f):Void
	{
        linearLowerLimit.copyFrom(vector);
        cast(constraint,Generic6DofConstraint).setLinearLowerLimit(vector);
    }

    public function setAngularUpperLimit(vector:Vector3f):Void
	{
        angularUpperLimit.copyFrom(vector);
        cast(constraint,Generic6DofConstraint).setAngularUpperLimit(vector);
    }

    public function setAngularLowerLimit(vector:Vector3f):Void 
	{
        angularLowerLimit.copyFrom(vector);
        cast(constraint,Generic6DofConstraint).setAngularLowerLimit(vector);
    }
}
