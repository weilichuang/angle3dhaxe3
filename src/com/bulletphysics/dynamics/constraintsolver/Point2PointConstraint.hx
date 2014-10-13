package com.bulletphysics.dynamics.constraintsolver;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.VectorUtil;
import vecmath.Matrix3f;
import vecmath.Vector3f;

class ConstraintSetting {
	public var tau:Float = 0.3;
	public var damping:Float = 1;
	public var impulseClamp:Float = 0;
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
        this.pivotInA.fromVector3f(pivotInA);
        this.pivotInB.fromVector3f(pivotInB);
    }

    public function init3(rbA:RigidBody, pivotInA:Vector3f):Void
	{
        this.init(TypedConstraintType.POINT2POINT_CONSTRAINT_TYPE, rbA);
        this.pivotInA.fromVector3f(pivotInA);
        this.pivotInB.fromVector3f(pivotInA);
        rbA.getCenterOfMassTransform(new Transform()).transform(this.pivotInB);
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

        var centerOfMassA:Transform = rbA.getCenterOfMassTransform(new Transform());
        var centerOfMassB:Transform = rbB.getCenterOfMassTransform(new Transform());

        for (i in 0...3)
		{
            VectorUtil.setCoord(normal, i, 1);

            tmpMat1.transpose(centerOfMassA.basis);
            tmpMat2.transpose(centerOfMassB.basis);

            tmp1.fromVector3f(pivotInA);
            centerOfMassA.transform(tmp1);
            tmp1.sub(rbA.getCenterOfMassPosition(tmpVec));

            tmp2.fromVector3f(pivotInB);
            centerOfMassB.transform(tmp2);
            tmp2.sub(rbB.getCenterOfMassPosition(tmpVec));

            jac[i].init(
                    tmpMat1,
                    tmpMat2,
                    tmp1,
                    tmp2,
                    normal,
                    rbA.getInvInertiaDiagLocal(new Vector3f()),
                    rbA.getInvMass(),
                    rbB.getInvInertiaDiagLocal(new Vector3f()),
                    rbB.getInvMass());
            VectorUtil.setCoord(normal, i, 0);
        }
	}
	
	override public function solveConstraint(timeStep:Float):Void 
	{
		var tmp:Vector3f = new Vector3f();
        var tmp2:Vector3f = new Vector3f();
        var tmpVec:Vector3f = new Vector3f();

        var centerOfMassA:Transform = rbA.getCenterOfMassTransform(new Transform());
        var centerOfMassB:Transform = rbB.getCenterOfMassTransform(new Transform());

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
            VectorUtil.setCoord(normal, i, 1);
            var jacDiagABInv:Float = 1 / jac[i].getDiagonal();

            var rel_pos1:Vector3f = new Vector3f();
            rel_pos1.sub(pivotAInW, rbA.getCenterOfMassPosition(tmpVec));
            var rel_pos2:Vector3f = new Vector3f();
            rel_pos2.sub(pivotBInW, rbB.getCenterOfMassPosition(tmpVec));
            // this jacobian entry could be re-used for all iterations

            var vel1:Vector3f = rbA.getVelocityInLocalPoint(rel_pos1, new Vector3f());
            var vel2:Vector3f = rbB.getVelocityInLocalPoint(rel_pos2, new Vector3f());
            var vel:Vector3f = new Vector3f();
            vel.sub(vel1, vel2);

            var rel_vel:Float;
            rel_vel = normal.dot(vel);

			/*
            //velocity error (first order error)
			btScalar rel_vel = m_jac[i].getRelativeVelocity(m_rbA.getLinearVelocity(),angvelA,
			m_rbB.getLinearVelocity(),angvelB);
			 */

            // positional error (zeroth order error)
            tmp.sub(pivotAInW, pivotBInW);
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
            impulse_vector.scale(impulse, normal);
            tmp.sub(pivotAInW, rbA.getCenterOfMassPosition(tmpVec));
            rbA.applyImpulse(impulse_vector, tmp);
            tmp.negate(impulse_vector);
            tmp2.sub(pivotBInW, rbB.getCenterOfMassPosition(tmpVec));
            rbB.applyImpulse(tmp, tmp2);

            VectorUtil.setCoord(normal, i, 0);
        }
	}

    public function updateRHS(timeStep:Float):Void
	{
    }

    public function setPivotA(pivotA:Vector3f):Void
	{
        pivotInA.fromVector3f(pivotA);
    }

    public function setPivotB(pivotB:Vector3f):Void
	{
        pivotInB.fromVector3f(pivotB);
    }

    public function getPivotInA(out:Vector3f):Vector3f 
	{
        out.fromVector3f(pivotInA);
        return out;
    }

    public function getPivotInB(out:Vector3f):Vector3f
	{
        out.fromVector3f(pivotInB);
        return out;
    }
}