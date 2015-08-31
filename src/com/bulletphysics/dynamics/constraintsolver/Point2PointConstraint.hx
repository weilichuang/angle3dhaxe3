package com.bulletphysics.dynamics.constraintsolver;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.LinearMathUtil;
import com.vecmath.Matrix3f;
import org.angle3d.math.Vector3f;

class ConstraintSetting 
{
	public var tau:Float = 0.3;
	public var damping:Float = 1;
	public var impulseClamp:Float = 0;
	
	public function new()
	{
		
	}
}
/**
 * Point to point constraint between two rigid bodies each with a pivot point that
 * descibes the "ballsocket" location in local space.
 * @author weilichuang
 */
class Point2PointConstraint extends TypedConstraint
{
	private var jac:Array<JacobianEntry> = [new JacobianEntry(), new JacobianEntry(), new JacobianEntry()]; // 3 orthogonal linear constraints

    private var pivotInA:Vector3f = new Vector3f();
    private var pivotInB:Vector3f = new Vector3f();

    public var setting:ConstraintSetting = new ConstraintSetting();

    public function new()
	{
        super(TypedConstraintType.POINT2POINT_CONSTRAINT_TYPE);
    }

    public function init2(rbA:RigidBody, rbB:RigidBody, pivotInA:Vector3f, pivotInB:Vector3f):Void
	{
        this.init(TypedConstraintType.POINT2POINT_CONSTRAINT_TYPE, rbA, rbB);
        this.pivotInA.copyFrom(pivotInA);
        this.pivotInB.copyFrom(pivotInB);
    }

    public function init3(rbA:RigidBody, pivotInA:Vector3f):Void
	{
        this.init(TypedConstraintType.POINT2POINT_CONSTRAINT_TYPE, rbA);
        this.pivotInA.copyFrom(pivotInA);
        this.pivotInB.copyFrom(pivotInA);
        rbA.getCenterOfMassTransform().transform(this.pivotInB);
    }

	override public function buildJacobian():Void 
	{
		appliedImpulse = 0;

        var normal:Vector3f = new Vector3f();
        normal.setTo(0, 0, 0);

        var tmpMat1:Matrix3f = new Matrix3f();
        var tmpMat2:Matrix3f = new Matrix3f();
        var tmp1:Vector3f = new Vector3f();
        var tmp2:Vector3f = new Vector3f();
        var tmpVec:Vector3f = new Vector3f();

        var centerOfMassA:Transform = rbA.getCenterOfMassTransformTo(new Transform());
        var centerOfMassB:Transform = rbB.getCenterOfMassTransformTo(new Transform());

        for (i in 0...3)
		{
            LinearMathUtil.setCoord(normal, i, 1);

            tmpMat1.transpose2(centerOfMassA.basis);
            tmpMat2.transpose2(centerOfMassB.basis);

            tmp1.copyFrom(pivotInA);
            centerOfMassA.transform(tmp1);
            tmp1.subtractLocal(rbA.getCenterOfMassPosition());

            tmp2.copyFrom(pivotInB);
            centerOfMassB.transform(tmp2);
            tmp2.subtractLocal(rbB.getCenterOfMassPosition());

            jac[i].init(
                    tmpMat1,
                    tmpMat2,
                    tmp1,
                    tmp2,
                    normal,
                    rbA.getInvInertiaDiagLocal(),
                    rbA.getInvMass(),
                    rbB.getInvInertiaDiagLocal(),
                    rbB.getInvMass());
            LinearMathUtil.setCoord(normal, i, 0);
        }
	}
	
	override public function solveConstraint(timeStep:Float):Void 
	{
		var tmp:Vector3f = new Vector3f();
        var tmp2:Vector3f = new Vector3f();

        var centerOfMassA:Transform = rbA.getCenterOfMassTransformTo(new Transform());
        var centerOfMassB:Transform = rbB.getCenterOfMassTransformTo(new Transform());

        var pivotAInW:Vector3f = pivotInA.clone();
        centerOfMassA.transform(pivotAInW);

        var pivotBInW:Vector3f = pivotInB.clone();
        centerOfMassB.transform(pivotBInW);

        var normal:Vector3f = new Vector3f();
        normal.setTo(0, 0, 0);

        //btVector3 angvelA = m_rbA.getCenterOfMassTransform().getBasis().transpose() * m_rbA.getAngularVelocity();
        //btVector3 angvelB = m_rbB.getCenterOfMassTransform().getBasis().transpose() * m_rbB.getAngularVelocity();

        for (i in 0...3) 
		{
            LinearMathUtil.setCoord(normal, i, 1);
            var jacDiagABInv:Float = 1 / jac[i].getDiagonal();

            var rel_pos1:Vector3f = new Vector3f();
            rel_pos1.subtractBy(pivotAInW, rbA.getCenterOfMassPosition());
            var rel_pos2:Vector3f = new Vector3f();
            rel_pos2.subtractBy(pivotBInW, rbB.getCenterOfMassPosition());
            // this jacobian entry could be re-used for all iterations

            var vel1:Vector3f = rbA.getVelocityInLocalPoint(rel_pos1, new Vector3f());
            var vel2:Vector3f = rbB.getVelocityInLocalPoint(rel_pos2, new Vector3f());
            var vel:Vector3f = new Vector3f();
            vel.subtractBy(vel1, vel2);

            var rel_vel:Float;
            rel_vel = normal.dot(vel);

			/*
            //velocity error (first order error)
			btScalar rel_vel = m_jac[i].getRelativeVelocity(m_rbA.getLinearVelocity(),angvelA,
			m_rbB.getLinearVelocity(),angvelB);
			 */

            // positional error (zeroth order error)
            tmp.subtractBy(pivotAInW, pivotBInW);
            var depth:Float = -tmp.dot(normal); //this is the error projected on the normal

            var impulse:Float = depth * setting.tau / timeStep * jacDiagABInv - setting.damping * rel_vel * jacDiagABInv;

            var impulseClamp:Float = setting.impulseClamp;
            if (impulseClamp > 0)
			{
                if (impulse < -impulseClamp)
				{
                    impulse = -impulseClamp;
                }
                if (impulse > impulseClamp)
				{
                    impulse = impulseClamp;
                }
            }

            appliedImpulse += impulse;
            var impulse_vector:Vector3f = new Vector3f();
            impulse_vector.scaleBy(impulse, normal);
            tmp.subtractBy(pivotAInW, rbA.getCenterOfMassPosition());
            rbA.applyImpulse(impulse_vector, tmp);
            tmp.negateBy(impulse_vector);
            tmp2.subtractBy(pivotBInW, rbB.getCenterOfMassPosition());
            rbB.applyImpulse(tmp, tmp2);

            LinearMathUtil.setCoord(normal, i, 0);
        }
	}

    public function updateRHS(timeStep:Float):Void
	{
    }

    public function setPivotA(pivotA:Vector3f):Void
	{
        pivotInA.copyFrom(pivotA);
    }

    public function setPivotB(pivotB:Vector3f):Void
	{
        pivotInB.copyFrom(pivotB);
    }

    public function getPivotInA(out:Vector3f):Vector3f 
	{
        out.copyFrom(pivotInA);
        return out;
    }

    public function getPivotInB(out:Vector3f):Vector3f
	{
        out.copyFrom(pivotInB);
        return out;
    }
}