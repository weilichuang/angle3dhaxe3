package com.bulletphysics.dynamics.constraintsolver;
import com.bulletphysics.linearmath.QuaternionUtil;
import com.bulletphysics.linearmath.ScalarUtil;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.TransformUtil;
import org.angle3d.math.Matrix3f;
import com.vecmath.Quat4f;
import org.angle3d.math.Vector3f;

/**
 * Hinge constraint between two rigid bodies each with a pivot point that descibes
 * the axis location in local space. Axis defines the orientation of the hinge axis.
 * @author weilichuang
 */
class HingeConstraint extends TypedConstraint
{
	// 3 orthogonal linear constraints
	private var jac:Array<JacobianEntry> = [new JacobianEntry(), new JacobianEntry(), new JacobianEntry()]; 
	// 2 orthogonal angular constraints+ 1 for limit/motor
    private var jacAng:Array<JacobianEntry> = [new JacobianEntry(), new JacobianEntry(), new JacobianEntry()]; 

    private var rbAFrame:Transform = new Transform(); // constraint axii. Assumes z is hinge axis.
    private var rbBFrame:Transform = new Transform();

    private var motorTargetVelocity:Float;
    private var maxMotorImpulse:Float;

    private var limitSoftness:Float;
    private var biasFactor:Float;
    private var relaxationFactor:Float;

    private var lowerLimit:Float;
    private var upperLimit:Float;

    private var kHinge:Float;

    private var limitSign:Float;
    private var correction:Float;

    private var accLimitImpulse:Float;

    private var angularOnly:Bool;
    private var _enableAngularMotor:Bool;
    private var solveLimit:Bool;

    public function new()
	{
        super(TypedConstraintType.HINGE_CONSTRAINT_TYPE);
        _enableAngularMotor = false;
    }

    public function init2(rbA:RigidBody, rbB:RigidBody, pivotInA:Vector3f, pivotInB:Vector3f, axisInA:Vector3f, axisInB:Vector3f):Void
	{
        this.init(TypedConstraintType.HINGE_CONSTRAINT_TYPE, rbA, rbB);
		
        angularOnly = false;
        _enableAngularMotor = false;

        rbAFrame.origin.copyFrom(pivotInA);

        // since no frame is given, assume this to be zero angle and just pick rb transform axis
        var rbAxisA1:Vector3f = new Vector3f();
        var rbAxisA2:Vector3f = new Vector3f();

        var centerOfMassA:Transform = rbA.getCenterOfMassTransformTo(new Transform());
        centerOfMassA.basis.copyColumnTo(0, rbAxisA1);
        var projection:Float = axisInA.dot(rbAxisA1);

        if (projection >= 1.0 - BulletGlobals.SIMD_EPSILON) 
		{
            centerOfMassA.basis.copyColumnTo(2, rbAxisA1);
            rbAxisA1.negateLocal();
            centerOfMassA.basis.copyColumnTo(1, rbAxisA2);
        } 
		else if (projection <= -1.0 + BulletGlobals.SIMD_EPSILON) 
		{
            centerOfMassA.basis.copyColumnTo(2, rbAxisA1);
            centerOfMassA.basis.copyColumnTo(1, rbAxisA2);
        }
		else
		{
            rbAxisA2.crossBy(axisInA, rbAxisA1);
            rbAxisA1.crossBy(rbAxisA2, axisInA);
        }

        rbAFrame.basis.setRowXYZ(0, rbAxisA1.x, rbAxisA2.x, axisInA.x);
        rbAFrame.basis.setRowXYZ(1, rbAxisA1.y, rbAxisA2.y, axisInA.y);
        rbAFrame.basis.setRowXYZ(2, rbAxisA1.z, rbAxisA2.z, axisInA.z);

        var rotationArc:Quat4f = QuaternionUtil.shortestArcQuat(axisInA, axisInB, new Quat4f());
        var rbAxisB1:Vector3f = QuaternionUtil.quatRotate(rotationArc, rbAxisA1, new Vector3f());
        var rbAxisB2:Vector3f = new Vector3f();
        rbAxisB2.crossBy(axisInB, rbAxisB1);

        rbBFrame.origin.copyFrom(pivotInB);
        rbBFrame.basis.setRowXYZ(0, rbAxisB1.x, rbAxisB2.x, -axisInB.x);
        rbBFrame.basis.setRowXYZ(1, rbAxisB1.y, rbAxisB2.y, -axisInB.y);
        rbBFrame.basis.setRowXYZ(2, rbAxisB1.z, rbAxisB2.z, -axisInB.z);

        // start with free
        lowerLimit = 1e30;
        upperLimit = -1e30;
        biasFactor = 0.3;
        relaxationFactor = 1.0;
        limitSoftness = 0.9;
        solveLimit = false;
    }

    public function init3(rbA:RigidBody, pivotInA:Vector3f, axisInA:Vector3f):Void
	{
        this.init(TypedConstraintType.HINGE_CONSTRAINT_TYPE, rbA);
        angularOnly = false;
        _enableAngularMotor = false;

        // since no frame is given, assume this to be zero angle and just pick rb transform axis
        // fixed axis in worldspace
        var rbAxisA1:Vector3f = new Vector3f();
        var centerOfMassA:Transform = rbA.getCenterOfMassTransformTo(new Transform());
        centerOfMassA.basis.copyColumnTo(0, rbAxisA1);

        var projection:Float = rbAxisA1.dot(axisInA);
        if (projection > BulletGlobals.FLT_EPSILON) 
		{
            rbAxisA1.scaleLocal(projection);
            rbAxisA1.subtractLocal(axisInA);
        }
		else
		{
            centerOfMassA.basis.copyColumnTo(1, rbAxisA1);
        }

        var rbAxisA2:Vector3f = new Vector3f();
        rbAxisA2.crossBy(axisInA, rbAxisA1);

        rbAFrame.origin.copyFrom(pivotInA);
        rbAFrame.basis.setRowXYZ(0, rbAxisA1.x, rbAxisA2.x, axisInA.x);
        rbAFrame.basis.setRowXYZ(1, rbAxisA1.y, rbAxisA2.y, axisInA.y);
        rbAFrame.basis.setRowXYZ(2, rbAxisA1.z, rbAxisA2.z, axisInA.z);

        var axisInB:Vector3f = new Vector3f();
        axisInB.negateBy(axisInA);
        centerOfMassA.basis.multVecLocal(axisInB);

        var rotationArc:Quat4f = QuaternionUtil.shortestArcQuat(axisInA, axisInB, new Quat4f());
        var rbAxisB1:Vector3f = QuaternionUtil.quatRotate(rotationArc, rbAxisA1, new Vector3f());
        var rbAxisB2:Vector3f = new Vector3f();
        rbAxisB2.crossBy(axisInB, rbAxisB1);

        rbBFrame.origin.copyFrom(pivotInA);
        centerOfMassA.transform(rbBFrame.origin);
        rbBFrame.basis.setRowXYZ(0, rbAxisB1.x, rbAxisB2.x, axisInB.x);
        rbBFrame.basis.setRowXYZ(1, rbAxisB1.y, rbAxisB2.y, axisInB.y);
        rbBFrame.basis.setRowXYZ(2, rbAxisB1.z, rbAxisB2.z, axisInB.z);

        // start with free
        lowerLimit = 1e30;
        upperLimit = -1e30;
        biasFactor = 0.3;
        relaxationFactor = 1.0;
        limitSoftness = 0.9;
        solveLimit = false;
    }

    public function init4(rbA:RigidBody, rbB:RigidBody, rbAFrame:Transform, rbBFrame:Transform):Void
	{
        this.init(TypedConstraintType.HINGE_CONSTRAINT_TYPE, rbA, rbB);
		
        this.rbAFrame.fromTransform(rbAFrame);
        this.rbBFrame.fromTransform(rbBFrame);
        angularOnly = false;
        _enableAngularMotor = false;

        // flip axis
        this.rbBFrame.basis.m02 *= -1;
        this.rbBFrame.basis.m12 *= -1;
        this.rbBFrame.basis.m22 *= -1;

        // start with free
        lowerLimit = 1e30;
        upperLimit = -1e30;
        biasFactor = 0.3;
        relaxationFactor = 1.0;
        limitSoftness = 0.9;
        solveLimit = false;
    }

    public function init5(rbA:RigidBody, rbAFrame:Transform):Void
	{
        this.init(TypedConstraintType.HINGE_CONSTRAINT_TYPE, rbA);
		
        this.rbAFrame.fromTransform(rbAFrame);
        this.rbBFrame.fromTransform(rbAFrame);
        angularOnly = false;
        _enableAngularMotor = false;

        // not providing rigidbody B means implicitly using worldspace for body B

        // flip axis
        this.rbBFrame.basis.m02 *= -1;
        this.rbBFrame.basis.m12 *= -1;
        this.rbBFrame.basis.m22 *= -1;

        this.rbBFrame.origin.copyFrom(this.rbAFrame.origin);
        rbA.getCenterOfMassTransform().transform(this.rbBFrame.origin);

        // start with free
        lowerLimit = 1e30;
        upperLimit = -1e30;
        biasFactor = 0.3;
        relaxationFactor = 1.0;
        limitSoftness = 0.9;
        solveLimit = false;
    }
	
	override public function buildJacobian():Void 
	{
		var tmp:Vector3f = new Vector3f();
        var tmp1:Vector3f = new Vector3f();
        var tmp2:Vector3f = new Vector3f();
        var tmpVec:Vector3f = new Vector3f();
        var mat1:Matrix3f = new Matrix3f();
        var mat2:Matrix3f = new Matrix3f();

        var centerOfMassA:Transform = rbA.getCenterOfMassTransformTo(new Transform());
        var centerOfMassB:Transform = rbB.getCenterOfMassTransformTo(new Transform());

        appliedImpulse = 0;

        if (!angularOnly)
		{
            var pivotAInW:Vector3f = rbAFrame.origin.clone();
            centerOfMassA.transform(pivotAInW);

            var pivotBInW:Vector3f = rbBFrame.origin.clone();
            centerOfMassB.transform(pivotBInW);

            var relPos:Vector3f = new Vector3f();
            relPos.subtractBy(pivotBInW, pivotAInW);

            var normal:Array<Vector3f> = [new Vector3f(), new Vector3f(), new Vector3f()];
            if (relPos.lengthSquared > BulletGlobals.FLT_EPSILON)
			{
                normal[0].copyFrom(relPos);
                normal[0].normalizeLocal();
            }
			else
			{
                normal[0].setTo(1, 0, 0);
            }

            TransformUtil.planeSpace1(normal[0], normal[1], normal[2]);

            for (i in 0...3)
			{
                mat1.transposeBy(centerOfMassA.basis);
                mat2.transposeBy(centerOfMassB.basis);

                tmp1.subtractBy(pivotAInW, rbA.getCenterOfMassPosition());
                tmp2.subtractBy(pivotBInW, rbB.getCenterOfMassPosition());

                jac[i].init(
                        mat1,
                        mat2,
                        tmp1,
                        tmp2,
                        normal[i],
                        rbA.getInvInertiaDiagLocal(),
                        rbA.getInvMass(),
                        rbB.getInvInertiaDiagLocal(),
                        rbB.getInvMass());
            }
        }

        // calculate two perpendicular jointAxis, orthogonal to hingeAxis
        // these two jointAxis require equal angular velocities for both bodies

        // this is unused for now, it's a todo
        var jointAxis0local:Vector3f = new Vector3f();
        var jointAxis1local:Vector3f = new Vector3f();

        rbAFrame.basis.copyColumnTo(2, tmp);
        TransformUtil.planeSpace1(tmp, jointAxis0local, jointAxis1local);

        // TODO: check this
        //getRigidBodyA().getCenterOfMassTransform().getBasis() * m_rbAFrame.getBasis().getColumn(2);

        var jointAxis0:Vector3f = jointAxis0local.clone();
        centerOfMassA.basis.multVecLocal(jointAxis0);

        var jointAxis1:Vector3f = jointAxis1local.clone();
        centerOfMassA.basis.multVecLocal(jointAxis1);

        var hingeAxisWorld:Vector3f = new Vector3f();
        rbAFrame.basis.copyColumnTo(2, hingeAxisWorld);
        centerOfMassA.basis.multVecLocal(hingeAxisWorld);

        mat1.transposeBy(centerOfMassA.basis);
        mat2.transposeBy(centerOfMassB.basis);
        jacAng[0].init2(jointAxis0,
                mat1,
                mat2,
                rbA.getInvInertiaDiagLocal(),
                rbB.getInvInertiaDiagLocal());

        // JAVA NOTE: reused mat1 and mat2, as recomputation is not needed
        jacAng[1].init2(jointAxis1,
                mat1,
                mat2,
                rbA.getInvInertiaDiagLocal(),
                rbB.getInvInertiaDiagLocal());

        // JAVA NOTE: reused mat1 and mat2, as recomputation is not needed
        jacAng[2].init2(hingeAxisWorld,
                mat1,
                mat2,
                rbA.getInvInertiaDiagLocal(),
                rbB.getInvInertiaDiagLocal());

        // Compute limit information
        var hingeAngle:Float = getHingeAngle();

        //set bias, sign, clear accumulator
        correction = 0;
        limitSign = 0;
        solveLimit = false;
        accLimitImpulse = 0;

        if (lowerLimit < upperLimit)
		{
            if (hingeAngle <= lowerLimit * limitSoftness)
			{
                correction = (lowerLimit - hingeAngle);
                limitSign = 1.0;
                solveLimit = true;
            } 
			else if (hingeAngle >= upperLimit * limitSoftness) 
			{
                correction = upperLimit - hingeAngle;
                limitSign = -1.0;
                solveLimit = true;
            }
        }

        // Compute K = J*W*J' for hinge axis
        var axisA:Vector3f = new Vector3f();
        rbAFrame.basis.copyColumnTo(2, axisA);
        centerOfMassA.basis.multVecLocal(axisA);

        kHinge = 1.0 / (getRigidBodyA().computeAngularImpulseDenominator(axisA) +
                getRigidBodyB().computeAngularImpulseDenominator(axisA));
	}
	
	override public function solveConstraint(timeStep:Float):Void 
	{
		var tmp:Vector3f = new Vector3f();
        var tmp2:Vector3f = new Vector3f();

        var centerOfMassA:Transform = rbA.getCenterOfMassTransformTo(new Transform());
        var centerOfMassB:Transform = rbB.getCenterOfMassTransformTo(new Transform());

        var pivotAInW:Vector3f = rbAFrame.origin.clone();
        centerOfMassA.transform(pivotAInW);

        var pivotBInW:Vector3f = rbBFrame.origin.clone();
        centerOfMassB.transform(pivotBInW);

        var tau:Float = 0.3;

        // linear part
        if (!angularOnly) 
		{
            var rel_pos1:Vector3f = new Vector3f();
            rel_pos1.subtractBy(pivotAInW, rbA.getCenterOfMassPosition());

            var rel_pos2:Vector3f = new Vector3f();
            rel_pos2.subtractBy(pivotBInW, rbB.getCenterOfMassPosition());

            var vel1:Vector3f = rbA.getVelocityInLocalPoint(rel_pos1, new Vector3f());
            var vel2:Vector3f = rbB.getVelocityInLocalPoint(rel_pos2, new Vector3f());
            var vel:Vector3f = new Vector3f();
            vel.subtractBy(vel1, vel2);

            for (i in 0...3)
			{
                var normal:Vector3f = jac[i].linearJointAxis;
                var jacDiagABInv:Float = 1 / jac[i].getDiagonal();

                var rel_vel:Float;
                rel_vel = normal.dot(vel);
                // positional error (zeroth order error)
                tmp.subtractBy(pivotAInW, pivotBInW);
                var depth:Float = -(tmp).dot(normal); // this is the error projected on the normal
                var impulse:Float = depth * tau / timeStep * jacDiagABInv - rel_vel * jacDiagABInv;
                appliedImpulse += impulse;
                var impulse_vector:Vector3f = new Vector3f();
                impulse_vector.scaleBy(impulse, normal);

                tmp.subtractBy(pivotAInW, rbA.getCenterOfMassPosition());
                rbA.applyImpulse(impulse_vector, tmp);

                tmp.negateBy(impulse_vector);
                tmp2.subtractBy(pivotBInW, rbB.getCenterOfMassPosition());
                rbB.applyImpulse(tmp, tmp2);
            }
        }


        {
            // solve angular part

            // get axes in world space
            var axisA:Vector3f = new Vector3f();
            rbAFrame.basis.copyColumnTo(2, axisA);
            centerOfMassA.basis.multVecLocal(axisA);

            var axisB:Vector3f = new Vector3f();
            rbBFrame.basis.copyColumnTo(2, axisB);
            centerOfMassB.basis.multVecLocal(axisB);

            var angVelA:Vector3f = getRigidBodyA().getAngularVelocityTo(new Vector3f());
            var angVelB:Vector3f = getRigidBodyB().getAngularVelocityTo(new Vector3f());

            var angVelAroundHingeAxisA:Vector3f = new Vector3f();
            angVelAroundHingeAxisA.scaleBy(axisA.dot(angVelA), axisA);

            var angVelAroundHingeAxisB:Vector3f = new Vector3f();
            angVelAroundHingeAxisB.scaleBy(axisB.dot(angVelB), axisB);

            var angAorthog:Vector3f = new Vector3f();
            angAorthog.subtractBy(angVelA, angVelAroundHingeAxisA);

            var angBorthog:Vector3f = new Vector3f();
            angBorthog.subtractBy(angVelB, angVelAroundHingeAxisB);

            var velrelOrthog:Vector3f = new Vector3f();
            velrelOrthog.subtractBy(angAorthog, angBorthog);

            {
                // solve orthogonal angular velocity correction
                var relaxation:Float = 1;
                var len:Float = velrelOrthog.length;
                if (len > 0.00001)
				{
                    var normal:Vector3f = new Vector3f();
                    normal.normalizeBy(velrelOrthog);

                    var denom:Float = getRigidBodyA().computeAngularImpulseDenominator(normal) +
                            getRigidBodyB().computeAngularImpulseDenominator(normal);
                    // scale for mass and relaxation
                    // todo:  expose this 0.9 factor to developer
                    velrelOrthog.scaleLocal((1 / denom) * relaxationFactor);
                }

                // solve angular positional correction
                // TODO: check
                //Vector3f angularError = -axisA.cross(axisB) *(btScalar(1.)/timeStep);
                var angularError:Vector3f = new Vector3f();
                angularError.crossBy(axisA, axisB);
                angularError.negateLocal();
                angularError.scaleLocal(1 / timeStep);
                var len2:Float = angularError.length;
                if (len2 > 0.00001)
				{
                    var normal2:Vector3f = new Vector3f();
                    normal2.normalizeBy(angularError);

                    var denom2:Float = getRigidBodyA().computeAngularImpulseDenominator(normal2) +
                            getRigidBodyB().computeAngularImpulseDenominator(normal2);
                    angularError.scaleLocal((1 / denom2) * relaxation);
                }

                tmp.negateBy(velrelOrthog);
                tmp.addLocal(angularError);
                rbA.applyTorqueImpulse(tmp);

                tmp.subtractBy(velrelOrthog, angularError);
                rbB.applyTorqueImpulse(tmp);

                // solve limit
                if (solveLimit)
				{
                    tmp.subtractBy(angVelB, angVelA);
                    var amplitude:Float = ((tmp).dot(axisA) * relaxationFactor + correction * (1 / timeStep) * biasFactor) * limitSign;

                    var impulseMag:Float = amplitude * kHinge;

                    // Clamp the accumulated impulse
                    var temp:Float = accLimitImpulse;
                    accLimitImpulse = Math.max(accLimitImpulse + impulseMag, 0);
                    impulseMag = accLimitImpulse - temp;

                    var impulse:Vector3f = new Vector3f();
                    impulse.scaleBy(impulseMag * limitSign, axisA);

                    rbA.applyTorqueImpulse(impulse);

                    tmp.negateBy(impulse);
                    rbB.applyTorqueImpulse(tmp);
                }
            }

            // apply motor
            if (_enableAngularMotor)
			{
                // todo: add limits too
                var angularLimit:Vector3f = new Vector3f();
                angularLimit.setTo(0, 0, 0);

                var velrel:Vector3f = new Vector3f();
                velrel.subtractBy(angVelAroundHingeAxisA, angVelAroundHingeAxisB);
                var projRelVel:Float = velrel.dot(axisA);

                var desiredMotorVel:Float = motorTargetVelocity;
                var motor_relvel:Float = desiredMotorVel - projRelVel;

                var unclippedMotorImpulse:Float = kHinge * motor_relvel;
                // todo: should clip against accumulated impulse
                var clippedMotorImpulse:Float = unclippedMotorImpulse > maxMotorImpulse ? maxMotorImpulse : unclippedMotorImpulse;
                clippedMotorImpulse = clippedMotorImpulse < -maxMotorImpulse ? -maxMotorImpulse : clippedMotorImpulse;
                var motorImp:Vector3f = new Vector3f();
                motorImp.scaleBy(clippedMotorImpulse, axisA);

                tmp.addBy(motorImp, angularLimit);
                rbA.applyTorqueImpulse(tmp);

                tmp.negateBy(motorImp);
                tmp.subtractLocal(angularLimit);
                rbB.applyTorqueImpulse(tmp);
            }
        }
	}

    public function updateRHS(timeStep:Float):Void
	{
    }

    public function getHingeAngle():Float
	{
        var centerOfMassA:Transform = rbA.getCenterOfMassTransformTo(new Transform());
        var centerOfMassB:Transform = rbB.getCenterOfMassTransformTo(new Transform());

        var refAxis0:Vector3f = new Vector3f();
        rbAFrame.basis.copyColumnTo(0, refAxis0);
        centerOfMassA.basis.multVecLocal(refAxis0);

        var refAxis1:Vector3f = new Vector3f();
        rbAFrame.basis.copyColumnTo(1, refAxis1);
        centerOfMassA.basis.multVecLocal(refAxis1);

        var swingAxis:Vector3f = new Vector3f();
        rbBFrame.basis.copyColumnTo(1, swingAxis);
        centerOfMassB.basis.multVecLocal(swingAxis);

        return ScalarUtil.atan2Fast(swingAxis.dot(refAxis0), swingAxis.dot(refAxis1));
    }

    public function setAngularOnly(angularOnly:Bool):Void
	{
        this.angularOnly = angularOnly;
    }

    public function enableAngularMotor(enableMotor:Bool, targetVelocity:Float, maxMotorImpulse:Float):Void
	{
        this._enableAngularMotor = enableMotor;
        this.motorTargetVelocity = targetVelocity;
        this.maxMotorImpulse = maxMotorImpulse;
    }

    public function setLimit(low:Float, high:Float, _softness:Float = 0.9, _biasFactor:Float = 0.3, _relaxationFactor:Float = 1.0):Void
	{
        lowerLimit = low;
        upperLimit = high;

        limitSoftness = _softness;
        biasFactor = _biasFactor;
        relaxationFactor = _relaxationFactor;
    }

    public function getLowerLimit():Float
	{
        return lowerLimit;
    }

    public function getUpperLimit():Float
	{
        return upperLimit;
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

    public function getSolveLimit():Bool
	{
        return solveLimit;
    }

    public function getLimitSign():Float
	{
        return limitSign;
    }

    public function getAngularOnly():Bool
	{
        return angularOnly;
    }

    public function getEnableAngularMotor():Bool
	{
        return _enableAngularMotor;
    }

    public function getMotorTargetVelosity():Float 
	{
        return motorTargetVelocity;
    }

    public function getMaxMotorImpulse():Float
	{
        return maxMotorImpulse;
    }
	
}