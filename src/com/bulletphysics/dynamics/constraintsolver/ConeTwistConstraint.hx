package com.bulletphysics.dynamics.constraintsolver;
import com.bulletphysics.linearmath.QuaternionUtil;
import com.bulletphysics.linearmath.ScalarUtil;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.TransformUtil;
import vecmath.Matrix3f;
import vecmath.Quat4f;
import vecmath.Vector3f;

/**
 * ConeTwistConstraint can be used to simulate ragdoll joints (upper arm, leg etc).
 * @author weilichuang
 */
class ConeTwistConstraint extends TypedConstraint
{
	//3 orthogonal linear constraints
	private var jac:Array<JacobianEntry> = [new JacobianEntry(), new JacobianEntry(), new JacobianEntry()]; 

    private var rbAFrame:Transform = new Transform();
    private var rbBFrame:Transform = new Transform();

    private var limitSoftness:Float;
    private var biasFactor:Float;
    private var relaxationFactor:Float;

    private var swingSpan1:Float;
    private var swingSpan2:Float;
    private var twistSpan:Float;

    private var swingAxis:Vector3f = new Vector3f();
    private var twistAxis:Vector3f = new Vector3f();

    private var kSwing:Float;
    private var kTwist:Float;

    private var twistLimitSign:Float;
    private var swingCorrection:Float;
    private var twistCorrection:Float;

    private var accSwingLimitImpulse:Float;
    private var accTwistLimitImpulse:Float;

    private var angularOnly:Bool = false;
    private var solveTwistLimit:Bool;
    private var solveSwingLimit:Bool;
	
	public function new()
	{
		super(TypedConstraintType.CONETWIST_CONSTRAINT_TYPE);
	}

    public function init2(rbA:RigidBody, rbB:RigidBody, rbAFrame:Transform, rbBFrame:Transform)
	{
        this.init(TypedConstraintType.CONETWIST_CONSTRAINT_TYPE, rbA, rbB);
		
        this.rbAFrame.fromTransform(rbAFrame);
        this.rbBFrame.fromTransform(rbBFrame);

        swingSpan1 = 1e30;
        swingSpan2 = 1e30;
        twistSpan = 1e30;
        biasFactor = 0.3;
        relaxationFactor = 1.0;

        solveTwistLimit = false;
        solveSwingLimit = false;
    }

    public function init3(rbA:RigidBody, rbAFrame:Transform):Void
	{
        this.init(TypedConstraintType.CONETWIST_CONSTRAINT_TYPE, rbA);
		
        this.rbAFrame.fromTransform(rbAFrame);
        this.rbBFrame.fromTransform(this.rbAFrame);

        swingSpan1 = 1e30;
        swingSpan2 = 1e30;
        twistSpan = 1e30;
        biasFactor = 0.3;
        relaxationFactor = 1.0;

        solveTwistLimit = false;
        solveSwingLimit = false;
    }
	
	override public function buildJacobian():Void 
	{
		var tmp:Vector3f = new Vector3f();
        var tmp1:Vector3f = new Vector3f();
        var tmp2:Vector3f = new Vector3f();

        //var tmpTrans:Transform = new Transform();

        appliedImpulse = 0;

        // set bias, sign, clear accumulator
        swingCorrection = 0;
        twistLimitSign = 0;
        solveTwistLimit = false;
        solveSwingLimit = false;
        accTwistLimitImpulse = 0;
        accSwingLimitImpulse = 0;

        if (!angularOnly)
		{
            var pivotAInW:Vector3f = rbAFrame.origin.clone();
            rbA.getCenterOfMassTransform().transform(pivotAInW);

            var pivotBInW:Vector3f = rbBFrame.origin.clone();
            rbB.getCenterOfMassTransform().transform(pivotBInW);

            var relPos:Vector3f = new Vector3f();
            relPos.sub2(pivotBInW, pivotAInW);

            // TODO: stack
            var normal:Array<Vector3f> = [new Vector3f(), new Vector3f(), new Vector3f()];
            if (relPos.lengthSquared() > BulletGlobals.FLT_EPSILON) 
			{
                normal[0].normalize(relPos);
            } 
			else
			{
                normal[0].setTo(1, 0, 0);
            }

            TransformUtil.planeSpace1(normal[0], normal[1], normal[2]);

            for (i in 0...3) 
			{
                var mat1:Matrix3f = rbA.getCenterOfMassTransformTo(new Transform()).basis;
                mat1.transpose();

                var mat2:Matrix3f = rbB.getCenterOfMassTransformTo(new Transform()).basis;
                mat2.transpose();

                tmp1.sub2(pivotAInW, rbA.getCenterOfMassPosition());
                tmp2.sub2(pivotBInW, rbB.getCenterOfMassPosition());

                jac[i].init(
                        mat1,
                        mat2,
                        tmp1,
                        tmp2,
                        normal[i],
                        rbA.getInvInertiaDiagLocal(new Vector3f()),
                        rbA.getInvMass(),
                        rbB.getInvInertiaDiagLocal(new Vector3f()),
                        rbB.getInvMass());
            }
        }

        var b1Axis1:Vector3f = new Vector3f();
		var b1Axis2:Vector3f = new Vector3f();
		var b1Axis3:Vector3f = new Vector3f();
        var b2Axis1:Vector3f = new Vector3f();
		var b2Axis2:Vector3f = new Vector3f();

        rbAFrame.basis.getColumn(0, b1Axis1);
        getRigidBodyA().getCenterOfMassTransform().basis.transform(b1Axis1);

        rbBFrame.basis.getColumn(0, b2Axis1);
        getRigidBodyB().getCenterOfMassTransform().basis.transform(b2Axis1);

        var swing1:Float = 0;
		var swing2:Float = 0;

        var swx:Float = 0;
		var swy:Float = 0;
        var thresh:Float = 10;
        var fact:Float;

        // Get Frame into world space
        if (swingSpan1 >= 0.05)
		{
            rbAFrame.basis.getColumn(1, b1Axis2);
            getRigidBodyA().getCenterOfMassTransform().basis.transform(b1Axis2);
//			swing1 = ScalarUtil.atan2Fast(b2Axis1.dot(b1Axis2), b2Axis1.dot(b1Axis1));
            swx = b2Axis1.dot(b1Axis1);
            swy = b2Axis1.dot(b1Axis2);
            swing1 = ScalarUtil.atan2Fast(swy, swx);
            fact = (swy * swy + swx * swx) * thresh * thresh;
            fact = fact / (fact + 1);
            swing1 *= fact;
        }

        if (swingSpan2 >= 0.05) 
		{
            rbAFrame.basis.getColumn(2, b1Axis3);
            getRigidBodyA().getCenterOfMassTransform().basis.transform(b1Axis3);
//			swing2 = ScalarUtil.atan2Fast(b2Axis1.dot(b1Axis3), b2Axis1.dot(b1Axis1));
            swx = b2Axis1.dot(b1Axis1);
            swy = b2Axis1.dot(b1Axis3);
            swing2 = ScalarUtil.atan2Fast(swy, swx);
            fact = (swy * swy + swx * swx) * thresh * thresh;
            fact = fact / (fact + 1);
            swing2 *= fact;
        }

        var RMaxAngle1Sq:Float = 1.0 / (swingSpan1 * swingSpan1);
        var RMaxAngle2Sq:Float = 1.0 / (swingSpan2 * swingSpan2);
        var EllipseAngle:Float = Math.abs(swing1 * swing1) * RMaxAngle1Sq + Math.abs(swing2 * swing2) * RMaxAngle2Sq;

        if (EllipseAngle > 1.0)
		{
            swingCorrection = EllipseAngle - 1.0;
            solveSwingLimit = true;

            // Calculate necessary axis & factors
            tmp1.scale2(b2Axis1.dot(b1Axis2), b1Axis2);
            tmp2.scale2(b2Axis1.dot(b1Axis3), b1Axis3);
            tmp.add2(tmp1, tmp2);
            swingAxis.cross(b2Axis1, tmp);
            swingAxis.normalize();

            var swingAxisSign:Float = (b2Axis1.dot(b1Axis1) >= 0.0) ? 1.0 : -1.0;
            swingAxis.scale(swingAxisSign);

            kSwing = 1 / (getRigidBodyA().computeAngularImpulseDenominator(swingAxis) +
                    getRigidBodyB().computeAngularImpulseDenominator(swingAxis));

        }

        // Twist limits
        if (twistSpan >= 0) 
		{
            //Vector3f b2Axis2 = new Vector3f();
            rbBFrame.basis.getColumn(1, b2Axis2);
            getRigidBodyB().getCenterOfMassTransform().basis.transform(b2Axis2);

            var rotationArc:Quat4f = QuaternionUtil.shortestArcQuat(b2Axis1, b1Axis1, new Quat4f());
            var TwistRef:Vector3f = QuaternionUtil.quatRotate(rotationArc, b2Axis2, new Vector3f());
            var twist:Float = ScalarUtil.atan2Fast(TwistRef.dot(b1Axis3), TwistRef.dot(b1Axis2));

            var lockedFreeFactor:Float = (twistSpan > 0.05) ? limitSoftness : 0;
            if (twist <= -twistSpan * lockedFreeFactor)
			{
                twistCorrection = -(twist + twistSpan);
                solveTwistLimit = true;

                twistAxis.add2(b2Axis1, b1Axis1);
                twistAxis.scale(0.5);
                twistAxis.normalize();
                twistAxis.scale(-1.0);

                kTwist = 1 / (getRigidBodyA().computeAngularImpulseDenominator(twistAxis) +
                        getRigidBodyB().computeAngularImpulseDenominator(twistAxis));

            } 
			else if (twist > twistSpan * lockedFreeFactor) 
			{
                twistCorrection = (twist - twistSpan);
                solveTwistLimit = true;

                twistAxis.add2(b2Axis1, b1Axis1);
                twistAxis.scale(0.5);
                twistAxis.normalize();

                kTwist = 1 / (getRigidBodyA().computeAngularImpulseDenominator(twistAxis) +
                        getRigidBodyB().computeAngularImpulseDenominator(twistAxis));
            }
        }
	}
	
	override public function solveConstraint(timeStep:Float):Void 
	{
		var tmp:Vector3f = new Vector3f();
        var tmp2:Vector3f = new Vector3f();

        //var tmpTrans:Transform = new Transform();

        var pivotAInW:Vector3f = rbAFrame.origin.clone();
        rbA.getCenterOfMassTransform().transform(pivotAInW);

        var pivotBInW:Vector3f = rbBFrame.origin.clone();
        rbB.getCenterOfMassTransform().transform(pivotBInW);

        var tau:Float = 0.3;

        // linear part
        if (!angularOnly) 
		{
            var rel_pos1:Vector3f = new Vector3f();
            rel_pos1.sub2(pivotAInW, rbA.getCenterOfMassPosition());

            var rel_pos2:Vector3f = new Vector3f();
            rel_pos2.sub2(pivotBInW, rbB.getCenterOfMassPosition());

            var vel1:Vector3f = rbA.getVelocityInLocalPoint(rel_pos1, new Vector3f());
            var vel2:Vector3f = rbB.getVelocityInLocalPoint(rel_pos2, new Vector3f());
            var vel:Vector3f = new Vector3f();
            vel.sub2(vel1, vel2);

            for (i in 0...3)
			{
                var normal:Vector3f = jac[i].linearJointAxis;
                var jacDiagABInv:Float = 1 / jac[i].getDiagonal();

                var rel_vel:Float;
                rel_vel = normal.dot(vel);
                // positional error (zeroth order error)
                tmp.sub2(pivotAInW, pivotBInW);
                var depth:Float = -(tmp).dot(normal); // this is the error projected on the normal
                var impulse:Float = depth * tau / timeStep * jacDiagABInv - rel_vel * jacDiagABInv;
                appliedImpulse += impulse;
                var impulse_vector:Vector3f = new Vector3f();
                impulse_vector.scale2(impulse, normal);

                tmp.sub2(pivotAInW, rbA.getCenterOfMassPosition());
                rbA.applyImpulse(impulse_vector, tmp);

                tmp.negateBy(impulse_vector);
                tmp2.sub2(pivotBInW, rbB.getCenterOfMassPosition());
                rbB.applyImpulse(tmp, tmp2);
            }
        }

        {
            // solve angular part
            var angVelA:Vector3f = getRigidBodyA().getAngularVelocityTo(new Vector3f());
            var angVelB:Vector3f = getRigidBodyB().getAngularVelocityTo(new Vector3f());

            // solve swing limit
            if (solveSwingLimit)
			{
                tmp.sub2(angVelB, angVelA);
                var amplitude:Float = ((tmp).dot(swingAxis) * relaxationFactor * relaxationFactor + swingCorrection * (1 / timeStep) * biasFactor);
                var impulseMag:Float = amplitude * kSwing;

                // Clamp the accumulated impulse
                var temp:Float = accSwingLimitImpulse;
                accSwingLimitImpulse = Math.max(accSwingLimitImpulse + impulseMag, 0.0);
                impulseMag = accSwingLimitImpulse - temp;

                var impulse:Vector3f = new Vector3f();
                impulse.scale2(impulseMag, swingAxis);

                rbA.applyTorqueImpulse(impulse);

                tmp.negateBy(impulse);
                rbB.applyTorqueImpulse(tmp);
            }

            // solve twist limit
            if (solveTwistLimit)
			{
                tmp.sub2(angVelB, angVelA);
                var amplitude:Float = ((tmp).dot(twistAxis) * relaxationFactor * relaxationFactor + twistCorrection * (1 / timeStep) * biasFactor);
                var impulseMag:Float = amplitude * kTwist;

                // Clamp the accumulated impulse
                var temp:Float = accTwistLimitImpulse;
                accTwistLimitImpulse = Math.max(accTwistLimitImpulse + impulseMag, 0.0);
                impulseMag = accTwistLimitImpulse - temp;

                var impulse:Vector3f = new Vector3f();
                impulse.scale2(impulseMag, twistAxis);

                rbA.applyTorqueImpulse(impulse);

                tmp.negateBy(impulse);
                rbB.applyTorqueImpulse(tmp);
            }
        }
	}

    public function updateRHS(timeStep:Float):Void
	{
    }

    public function setAngularOnly(angularOnly:Bool):Void
	{
        this.angularOnly = angularOnly;
    }

    public function setLimit(_swingSpan1:Float, _swingSpan2:Float, _twistSpan:Float, ?_softness:Float = 0.8, ?_biasFactor:Float = 0.3, ?_relaxationFactor:Float = 1.0):Void
	{
        swingSpan1 = _swingSpan1;
        swingSpan2 = _swingSpan2;
        twistSpan = _twistSpan;

        limitSoftness = _softness;
        biasFactor = _biasFactor;
        relaxationFactor = _relaxationFactor;
    }

    public function getAFrame(out:Transform):Transform
	{
        out.fromTransform(rbAFrame);
        return out;
    }

    public function getBFrame(out:Transform):Transform
	{
        out.fromTransform(rbBFrame);
        return out;
    }

    public function getSolveTwistLimit():Bool
	{
        return solveTwistLimit;
    }

    public function getSolveSwingLimit():Bool
	{
        return solveTwistLimit;
    }

    public function getTwistLimitSign():Float
	{
        return twistLimitSign;
    }
	
}