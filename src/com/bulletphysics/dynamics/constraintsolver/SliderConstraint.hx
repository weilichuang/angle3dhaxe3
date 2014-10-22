package com.bulletphysics.dynamics.constraintsolver;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.VectorUtil;
import vecmath.Matrix3f;
import vecmath.Vector3f;

/**
 * ...
 * @author weilichuang
 */
class SliderConstraint extends TypedConstraint
{

	public static inline var SLIDER_CONSTRAINT_DEF_SOFTNESS:Float = 1.0;
    public static inline var SLIDER_CONSTRAINT_DEF_DAMPING:Float = 1.0;
    public static inline var SLIDER_CONSTRAINT_DEF_RESTITUTION:Float = 0.7;

    private var frameInA:Transform = new Transform();
    private var frameInB:Transform = new Transform();
    // use frameA fo define limits, if true
    private var useLinearReferenceFrameA:Bool;
    // linear limits
    private var lowerLinLimit:Float;
    private var upperLinLimit:Float;
    // angular limits
    private var lowerAngLimit:Float;
    private var upperAngLimit:Float;
    // softness, restitution and damping for different cases
    // DirLin - moving inside linear limits
    // LimLin - hitting linear limit
    // DirAng - moving inside angular limits
    // LimAng - hitting angular limit
    // OrthoLin, OrthoAng - against constraint axis
    private var softnessDirLin:Float;
    private var restitutionDirLin:Float;
    private var dampingDirLin:Float;
    private var softnessDirAng:Float;
    private var restitutionDirAng:Float;
    private var dampingDirAng:Float;
    private var softnessLimLin:Float;
    private var restitutionLimLin:Float;
    private var dampingLimLin:Float;
    private var softnessLimAng:Float;
    private var restitutionLimAng:Float;
    private var dampingLimAng:Float;
    private var softnessOrthoLin:Float;
    private var restitutionOrthoLin:Float;
    private var dampingOrthoLin:Float;
    private var softnessOrthoAng:Float;
    private var restitutionOrthoAng:Float;
    private var dampingOrthoAng:Float;

    // for interlal use
    private var solveLinLim:Bool;
    private var solveAngLim:Bool;

    private var jacLin:Array<JacobianEntry> = [new JacobianEntry(), new JacobianEntry(), new JacobianEntry()];
    private var jacLinDiagABInv:Array<Float> = [0, 0, 0];

    private var jacAng:Array<JacobianEntry> = [new JacobianEntry(), new JacobianEntry(), new JacobianEntry()];

    private var timeStep:Float;
    private var calculatedTransformA:Transform = new Transform();
    private var calculatedTransformB:Transform = new Transform();

    private var sliderAxis:Vector3f = new Vector3f();
    private var realPivotAInW:Vector3f = new Vector3f();
    private var realPivotBInW:Vector3f = new Vector3f();
    private var projPivotInW:Vector3f = new Vector3f();
    private var delta:Vector3f = new Vector3f();
    private var depth:Vector3f = new Vector3f();
    private var relPosA:Vector3f = new Vector3f();
    private var relPosB:Vector3f = new Vector3f();

    private var linPos:Float;

    private var angDepth:Float;
    private var kAngle:Float;

    private var poweredLinMotor:Bool;
    private var targetLinMotorVelocity:Float;
    private var maxLinMotorForce:Float;
    private var accumulatedLinMotorImpulse:Float;

    private var poweredAngMotor:Bool;
    private var targetAngMotorVelocity:Float;
    private var maxAngMotorForce:Float;
    private var accumulatedAngMotorImpulse:Float;

    public function new()
	{
        super(TypedConstraintType.SLIDER_CONSTRAINT_TYPE);
        useLinearReferenceFrameA = true;
        initParams();
    }

    public function init2(rbA:RigidBody, rbB:RigidBody, frameInA:Transform, frameInB:Transform, useLinearReferenceFrameA:Bool):Void
	{
        this.init(TypedConstraintType.SLIDER_CONSTRAINT_TYPE, rbA, rbB);
        this.frameInA.fromTransform(frameInA);
        this.frameInB.fromTransform(frameInB);
        this.useLinearReferenceFrameA = useLinearReferenceFrameA;
        initParams();
    }

    private function initParams():Void
	{
        lowerLinLimit = 1;
        upperLinLimit = -1;
        lowerAngLimit = 0;
        upperAngLimit = 0;
        softnessDirLin = SLIDER_CONSTRAINT_DEF_SOFTNESS;
        restitutionDirLin = SLIDER_CONSTRAINT_DEF_RESTITUTION;
        dampingDirLin = 0;
        softnessDirAng = SLIDER_CONSTRAINT_DEF_SOFTNESS;
        restitutionDirAng = SLIDER_CONSTRAINT_DEF_RESTITUTION;
        dampingDirAng = 0;
        softnessOrthoLin = SLIDER_CONSTRAINT_DEF_SOFTNESS;
        restitutionOrthoLin = SLIDER_CONSTRAINT_DEF_RESTITUTION;
        dampingOrthoLin = SLIDER_CONSTRAINT_DEF_DAMPING;
        softnessOrthoAng = SLIDER_CONSTRAINT_DEF_SOFTNESS;
        restitutionOrthoAng = SLIDER_CONSTRAINT_DEF_RESTITUTION;
        dampingOrthoAng = SLIDER_CONSTRAINT_DEF_DAMPING;
        softnessLimLin = SLIDER_CONSTRAINT_DEF_SOFTNESS;
        restitutionLimLin = SLIDER_CONSTRAINT_DEF_RESTITUTION;
        dampingLimLin = SLIDER_CONSTRAINT_DEF_DAMPING;
        softnessLimAng = SLIDER_CONSTRAINT_DEF_SOFTNESS;
        restitutionLimAng = SLIDER_CONSTRAINT_DEF_RESTITUTION;
        dampingLimAng = SLIDER_CONSTRAINT_DEF_DAMPING;

        poweredLinMotor = false;
        targetLinMotorVelocity = 0;
        maxLinMotorForce = 0;
        accumulatedLinMotorImpulse = 0;

        poweredAngMotor = false;
        targetAngMotorVelocity = 0;
        maxAngMotorForce = 0;
        accumulatedAngMotorImpulse = 0;
    }
	
	override public function buildJacobian():Void 
	{
		if (useLinearReferenceFrameA)
		{
            buildJacobianInt(rbA, rbB, frameInA, frameInB);
        }
		else
		{
            buildJacobianInt(rbB, rbA, frameInB, frameInA);
        }
	}

    override public function solveConstraint(timeStep:Float):Void 
	{
		this.timeStep = timeStep;
        if (useLinearReferenceFrameA)
		{
            solveConstraintInt(rbA, rbB);
        } 
		else
		{
            solveConstraintInt(rbB, rbA);
        }
	}

    public function getCalculatedTransformA(out:Transform):Transform 
	{
        out.fromTransform(calculatedTransformA);
        return out;
    }

    public function getCalculatedTransformB(out:Transform):Transform
	{
        out.fromTransform(calculatedTransformB);
        return out;
    }

    public function getFrameOffsetA(out:Transform):Transform
	{
        out.fromTransform(frameInA);
        return out;
    }

    public function getFrameOffsetB(out:Transform):Transform
	{
        out.fromTransform(frameInB);
        return out;
    }

    public function getLowerLinLimit():Float
	{
        return lowerLinLimit;
    }

    public function setLowerLinLimit( lowerLimit:Float):Void
	{
        this.lowerLinLimit = lowerLimit;
    }

    public function getUpperLinLimit():Float
	{
        return upperLinLimit;
    }

    public function setUpperLinLimit(upperLimit:Float):Void 
	{
        this.upperLinLimit = upperLimit;
    }

    public function getLowerAngLimit():Float
	{
        return lowerAngLimit;
    }

    public function setLowerAngLimit(lowerLimit:Float):Void
	{
        this.lowerAngLimit = lowerLimit;
    }

    public function getUpperAngLimit():Float 
	{
        return upperAngLimit;
    }

    public function setUpperAngLimit( upperLimit:Float):Void
	{
        this.upperAngLimit = upperLimit;
    }

    public function getUseLinearReferenceFrameA():Bool
	{
        return useLinearReferenceFrameA;
    }

    public function getSoftnessDirLin():Float
	{
        return softnessDirLin;
    }

    public function getRestitutionDirLin():Float
	{
        return restitutionDirLin;
    }

    public function getDampingDirLin():Float 
	{
        return dampingDirLin;
    }

    public function getSoftnessDirAng():Float 
	{
        return softnessDirAng;
    }

    public function getRestitutionDirAng():Float 
	{
        return restitutionDirAng;
    }

    public function getDampingDirAng():Float 
	{
        return dampingDirAng;
    }

    public function getSoftnessLimLin():Float 
	{
        return softnessLimLin;
    }

    public function getRestitutionLimLin():Float
	{
        return restitutionLimLin;
    }

    public function getDampingLimLin():Float 
	{
        return dampingLimLin;
    }

    public function getSoftnessLimAng():Float
	{
        return softnessLimAng;
    }

    public function getRestitutionLimAng():Float
	{
        return restitutionLimAng;
    }

    public function getDampingLimAng():Float
	{
        return dampingLimAng;
    }

    public function getSoftnessOrthoLin():Float
	{
        return softnessOrthoLin;
    }

    public function getRestitutionOrthoLin():Float 
	{
        return restitutionOrthoLin;
    }

    public function getDampingOrthoLin():Float 
	{
        return dampingOrthoLin;
    }

    public function getSoftnessOrthoAng():Float
	{
        return softnessOrthoAng;
    }

    public function getRestitutionOrthoAng():Float
	{
        return restitutionOrthoAng;
    }

    public function getDampingOrthoAng():Float
	{
        return dampingOrthoAng;
    }

    public function setSoftnessDirLin( softnessDirLin:Float):Void
	{
        this.softnessDirLin = softnessDirLin;
    }

    public function setRestitutionDirLin( restitutionDirLin:Float):Void
	{
        this.restitutionDirLin = restitutionDirLin;
    }

    public function setDampingDirLin( dampingDirLin:Float):Void
	{
        this.dampingDirLin = dampingDirLin;
    }

    public function setSoftnessDirAng( softnessDirAng:Float):Void
	{
        this.softnessDirAng = softnessDirAng;
    }

    public function setRestitutionDirAng( restitutionDirAng:Float):Void
	{
        this.restitutionDirAng = restitutionDirAng;
    }

    public function setDampingDirAng(dampingDirAng:Float):Void
	{
        this.dampingDirAng = dampingDirAng;
    }

    public function setSoftnessLimLin( softnessLimLin:Float):Void
	 {
        this.softnessLimLin = softnessLimLin;
    }

    public function setRestitutionLimLin( restitutionLimLin:Float):Void
	 {
        this.restitutionLimLin = restitutionLimLin;
    }

    public function setDampingLimLin( dampingLimLin:Float):Void
	 {
        this.dampingLimLin = dampingLimLin;
    }

    public function setSoftnessLimAng( softnessLimAng:Float):Void
	 {
        this.softnessLimAng = softnessLimAng;
    }

    public function setRestitutionLimAng( restitutionLimAng:Float):Void
	 {
        this.restitutionLimAng = restitutionLimAng;
    }

    public function setDampingLimAng( dampingLimAng:Float):Void
	 {
        this.dampingLimAng = dampingLimAng;
    }

    public function setSoftnessOrthoLin( softnessOrthoLin:Float):Void
	 {
        this.softnessOrthoLin = softnessOrthoLin;
    }

    public function setRestitutionOrthoLin( restitutionOrthoLin:Float):Void
	 {
        this.restitutionOrthoLin = restitutionOrthoLin;
    }

    public function setDampingOrthoLin( dampingOrthoLin:Float):Void
	 {
        this.dampingOrthoLin = dampingOrthoLin;
    }

    public function setSoftnessOrthoAng( softnessOrthoAng:Float):Void
	 {
        this.softnessOrthoAng = softnessOrthoAng;
    }

    public function setRestitutionOrthoAng( restitutionOrthoAng:Float):Void
	 {
        this.restitutionOrthoAng = restitutionOrthoAng;
    }

    public function setDampingOrthoAng( dampingOrthoAng:Float):Void
	 {
        this.dampingOrthoAng = dampingOrthoAng;
    }

    public function setPoweredLinMotor( onOff:Bool):Void
	 {
        this.poweredLinMotor = onOff;
    }

    public function getPoweredLinMotor():Bool
	{
        return poweredLinMotor;
    }

    public function setTargetLinMotorVelocity(targetLinMotorVelocity:Float):Void
	{
        this.targetLinMotorVelocity = targetLinMotorVelocity;
    }

    public function getTargetLinMotorVelocity():Float
	{
        return targetLinMotorVelocity;
    }

    public function setMaxLinMotorForce(maxLinMotorForce:Float):Void
	{
        this.maxLinMotorForce = maxLinMotorForce;
    }

    public function getMaxLinMotorForce():Float
	{
        return maxLinMotorForce;
    }

    public function setPoweredAngMotor( onOff:Bool):Void
	{
        this.poweredAngMotor = onOff;
    }

    public function getPoweredAngMotor():Bool
	{
        return poweredAngMotor;
    }

    public function setTargetAngMotorVelocity( targetAngMotorVelocity:Float):Void 
	{
        this.targetAngMotorVelocity = targetAngMotorVelocity;
    }

    public function getTargetAngMotorVelocity():Float
	{
        return targetAngMotorVelocity;
    }

    public function setMaxAngMotorForce(maxAngMotorForce:Float):Void
	{
        this.maxAngMotorForce = maxAngMotorForce;
    }

    public function getMaxAngMotorForce():Float
	{
        return this.maxAngMotorForce;
    }

    public function getLinearPos():Float
	{
        return this.linPos;
    }

    // access for ODE solver

    public function getSolveLinLimit():Bool 
	{
        return solveLinLim;
    }

    public function getLinDepth():Float 
	{
        return depth.x;
    }

    public function getSolveAngLimit():Bool 
	{
        return solveAngLim;
    }

    public function getAngDepth():Float
	{
        return angDepth;
    }

    // internal

    public function buildJacobianInt(rbA:RigidBody, rbB:RigidBody, frameInA:Transform, frameInB:Transform):Void
	{
        var tmpTrans:Transform = new Transform();
        var tmpTrans1:Transform = new Transform();
        var tmpTrans2:Transform = new Transform();
        var tmp:Vector3f = new Vector3f();
        var tmp2:Vector3f = new Vector3f();

        // calculate transforms
        calculatedTransformA.mul2(rbA.getCenterOfMassTransform(tmpTrans), frameInA);
        calculatedTransformB.mul2(rbB.getCenterOfMassTransform(tmpTrans), frameInB);
        realPivotAInW.fromVector3f(calculatedTransformA.origin);
        realPivotBInW.fromVector3f(calculatedTransformB.origin);
        calculatedTransformA.basis.getColumn(0, tmp);
        sliderAxis.fromVector3f(tmp); // along X
        delta.sub2(realPivotBInW, realPivotAInW);
        projPivotInW.scaleAdd(sliderAxis.dot(delta), sliderAxis, realPivotAInW);
        relPosA.sub2(projPivotInW, rbA.getCenterOfMassPosition(tmp));
        relPosB.sub2(realPivotBInW, rbB.getCenterOfMassPosition(tmp));
        var normalWorld:Vector3f = new Vector3f();

        // linear part
        for (i in 0...3)
		{
            calculatedTransformA.basis.getColumn(i, normalWorld);

            var mat1:Matrix3f = rbA.getCenterOfMassTransform(tmpTrans1).basis;
            mat1.transpose();

            var mat2:Matrix3f = rbB.getCenterOfMassTransform(tmpTrans2).basis;
            mat2.transpose();

            jacLin[i].init(
                    mat1,
                    mat2,
                    relPosA,
                    relPosB,
                    normalWorld,
                    rbA.getInvInertiaDiagLocal(tmp),
                    rbA.getInvMass(),
                    rbB.getInvInertiaDiagLocal(tmp2),
                    rbB.getInvMass());
            jacLinDiagABInv[i] = 1 / jacLin[i].getDiagonal();
            VectorUtil.setCoord(depth, i, delta.dot(normalWorld));
        }
        testLinLimits();

        // angular part
        for (i in 0...3)
		{
            calculatedTransformA.basis.getColumn(i, normalWorld);

            var mat1:Matrix3f = rbA.getCenterOfMassTransform(tmpTrans1).basis;
            mat1.transpose();

            var mat2:Matrix3f = rbB.getCenterOfMassTransform(tmpTrans2).basis;
            mat2.transpose();

            jacAng[i].init2(
                    normalWorld,
                    mat1,
                    mat2,
                    rbA.getInvInertiaDiagLocal(tmp),
                    rbB.getInvInertiaDiagLocal(tmp2));
        }
        testAngLimits();

        var axisA:Vector3f = new Vector3f();
        calculatedTransformA.basis.getColumn(0, axisA);
        kAngle = 1 / (rbA.computeAngularImpulseDenominator(axisA) + rbB.computeAngularImpulseDenominator(axisA));
        // clear accumulator for motors
        accumulatedLinMotorImpulse = 0;
        accumulatedAngMotorImpulse = 0;
    }

    public function solveConstraintInt(rbA:RigidBody, rbB:RigidBody):Void
	{
        var tmp:Vector3f = new Vector3f();

        // linear
        var velA:Vector3f = rbA.getVelocityInLocalPoint(relPosA, new Vector3f());
        var velB:Vector3f = rbB.getVelocityInLocalPoint(relPosB, new Vector3f());
        var vel:Vector3f = new Vector3f();
        vel.sub2(velA, velB);

        var impulse_vector:Vector3f = new Vector3f();

        for (i in 0...3)
		{
            var normal:Vector3f = jacLin[i].linearJointAxis;
            var rel_vel:Float = normal.dot(vel);
            // calculate positional error
            var depth:Float = VectorUtil.getCoord(this.depth, i);
            // get parameters
            var softness:Float = (i != 0) ? softnessOrthoLin : (solveLinLim ? softnessLimLin : softnessDirLin);
            var restitution:Float = (i != 0) ? restitutionOrthoLin : (solveLinLim ? restitutionLimLin : restitutionDirLin);
            var damping:Float = (i != 0) ? dampingOrthoLin : (solveLinLim ? dampingLimLin : dampingDirLin);
            // calcutate and apply impulse
            var normalImpulse:Float = softness * (restitution * depth / timeStep - damping * rel_vel) * jacLinDiagABInv[i];
            impulse_vector.scale2(normalImpulse, normal);
            rbA.applyImpulse(impulse_vector, relPosA);
            tmp.negateBy(impulse_vector);
            rbB.applyImpulse(tmp, relPosB);

            if (poweredLinMotor && (i == 0))
			{
                // apply linear motor
                if (accumulatedLinMotorImpulse < maxLinMotorForce)
				{
                    var desiredMotorVel:Float = targetLinMotorVelocity;
                    var motor_relvel:Float = desiredMotorVel + rel_vel;
                    normalImpulse = -motor_relvel * jacLinDiagABInv[i];
                    // clamp accumulated impulse
                    var new_acc:Float = accumulatedLinMotorImpulse + Math.abs(normalImpulse);
                    if (new_acc > maxLinMotorForce)
					{
                        new_acc = maxLinMotorForce;
                    }
                    var del:Float = new_acc - accumulatedLinMotorImpulse;
                    if (normalImpulse < 0)
					{
                        normalImpulse = -del;
                    } else {
                        normalImpulse = del;
                    }
                    accumulatedLinMotorImpulse = new_acc;
                    // apply clamped impulse
                    impulse_vector.scale2(normalImpulse, normal);
                    rbA.applyImpulse(impulse_vector, relPosA);
                    tmp.negateBy(impulse_vector);
                    rbB.applyImpulse(tmp, relPosB);
                }
            }
        }

        // angular
        // get axes in world space
        var axisA:Vector3f = new Vector3f();
        calculatedTransformA.basis.getColumn(0, axisA);
        var axisB:Vector3f = new Vector3f();
        calculatedTransformB.basis.getColumn(0, axisB);

        var angVelA:Vector3f = rbA.getAngularVelocity(new Vector3f());
        var angVelB:Vector3f = rbB.getAngularVelocity(new Vector3f());

        var angVelAroundAxisA:Vector3f = new Vector3f();
        angVelAroundAxisA.scale2(axisA.dot(angVelA), axisA);
        var angVelAroundAxisB:Vector3f = new Vector3f();
        angVelAroundAxisB.scale2(axisB.dot(angVelB), axisB);

        var angAorthog:Vector3f = new Vector3f();
        angAorthog.sub2(angVelA, angVelAroundAxisA);
        var angBorthog:Vector3f = new Vector3f();
        angBorthog.sub2(angVelB, angVelAroundAxisB);
        var velrelOrthog:Vector3f = new Vector3f();
        velrelOrthog.sub2(angAorthog, angBorthog);

        // solve orthogonal angular velocity correction
        var len:Float = velrelOrthog.length();
        if (len > 0.00001)
		{
            var normal:Vector3f = new Vector3f();
            normal.normalize(velrelOrthog);
            var denom:Float = rbA.computeAngularImpulseDenominator(normal) + rbB.computeAngularImpulseDenominator(normal);
            velrelOrthog.scale((1 / denom) * dampingOrthoAng * softnessOrthoAng);
        }

        // solve angular positional correction
        var angularError:Vector3f = new Vector3f();
        angularError.cross(axisA, axisB);
        angularError.scale(1 / timeStep);
        var len2:Float = angularError.length();
        if (len2 > 0.00001)
		{
            var normal2:Vector3f = new Vector3f();
            normal2.normalize(angularError);
            var denom2:Float = rbA.computeAngularImpulseDenominator(normal2) + rbB.computeAngularImpulseDenominator(normal2);
            angularError.scale((1 / denom2) * restitutionOrthoAng * softnessOrthoAng);
        }

        // apply impulse
        tmp.negateBy(velrelOrthog);
        tmp.add(angularError);
        rbA.applyTorqueImpulse(tmp);
        tmp.sub2(velrelOrthog, angularError);
        rbB.applyTorqueImpulse(tmp);
        var impulseMag:Float;

        // solve angular limits
        if (solveAngLim) 
		{
            tmp.sub2(angVelB, angVelA);
            impulseMag = tmp.dot(axisA) * dampingLimAng + angDepth * restitutionLimAng / timeStep;
            impulseMag *= kAngle * softnessLimAng;
        } 
		else
		{
            tmp.sub2(angVelB, angVelA);
            impulseMag = tmp.dot(axisA) * dampingDirAng + angDepth * restitutionDirAng / timeStep;
            impulseMag *= kAngle * softnessDirAng;
        }
        var impulse:Vector3f = new Vector3f();
        impulse.scale2(impulseMag, axisA);
        rbA.applyTorqueImpulse(impulse);
        tmp.negateBy(impulse);
        rbB.applyTorqueImpulse(tmp);

        // apply angular motor
        if (poweredAngMotor)
		{
            if (accumulatedAngMotorImpulse < maxAngMotorForce) 
			{
                var velrel:Vector3f = new Vector3f();
                velrel.sub2(angVelAroundAxisA, angVelAroundAxisB);
                var projRelVel:Float = velrel.dot(axisA);

                var desiredMotorVel:Float = targetAngMotorVelocity;
                var motor_relvel:Float = desiredMotorVel - projRelVel;

                var angImpulse:Float = kAngle * motor_relvel;
                // clamp accumulated impulse
                var new_acc:Float = accumulatedAngMotorImpulse + Math.abs(angImpulse);
                if (new_acc > maxAngMotorForce) 
				{
                    new_acc = maxAngMotorForce;
                }
                var del:Float = new_acc - accumulatedAngMotorImpulse;
                if (angImpulse < 0) 
				{
                    angImpulse = -del;
                }
				else 
				{
                    angImpulse = del;
                }
                accumulatedAngMotorImpulse = new_acc;

                // apply clamped impulse
                var motorImp:Vector3f = new Vector3f();
                motorImp.scale2(angImpulse, axisA);
                rbA.applyTorqueImpulse(motorImp);
                tmp.negateBy(motorImp);
                rbB.applyTorqueImpulse(tmp);
            }
        }
    }

    // shared code used by ODE solver

    public function calculateTransforms():Void
	{
        var tmpTrans:Transform = new Transform();

        if (useLinearReferenceFrameA)
		{
            calculatedTransformA.mul2(rbA.getCenterOfMassTransform(tmpTrans), frameInA);
            calculatedTransformB.mul2(rbB.getCenterOfMassTransform(tmpTrans), frameInB);
        } 
		else 
		{
            calculatedTransformA.mul2(rbB.getCenterOfMassTransform(tmpTrans), frameInB);
            calculatedTransformB.mul2(rbA.getCenterOfMassTransform(tmpTrans), frameInA);
        }
        realPivotAInW.fromVector3f(calculatedTransformA.origin);
        realPivotBInW.fromVector3f(calculatedTransformB.origin);
        calculatedTransformA.basis.getColumn(0, sliderAxis); // along X
        delta.sub2(realPivotBInW, realPivotAInW);
        projPivotInW.scaleAdd(sliderAxis.dot(delta), sliderAxis, realPivotAInW);
        var normalWorld:Vector3f = new Vector3f();
        // linear part
        for (i in 0...3)
		{
            calculatedTransformA.basis.getColumn(i, normalWorld);
            VectorUtil.setCoord(depth, i, delta.dot(normalWorld));
        }
    }

    public function testLinLimits():Void
	{
        solveLinLim = false;
        linPos = depth.x;
        if (lowerLinLimit <= upperLinLimit)
		{
            if (depth.x > upperLinLimit)
			{
                depth.x -= upperLinLimit;
                solveLinLim = true;
            } 
			else if (depth.x < lowerLinLimit)
			{
                depth.x -= lowerLinLimit;
                solveLinLim = true;
            }
			else
			{
                depth.x = 0;
            }
        } 
		else
		{
            depth.x = 0;
        }
    }

    public function testAngLimits():Void
	{
        angDepth = 0;
        solveAngLim = false;
        if (lowerAngLimit <= upperAngLimit) 
		{
            var axisA0:Vector3f = new Vector3f();
            calculatedTransformA.basis.getColumn(1, axisA0);
            var axisA1:Vector3f = new Vector3f();
            calculatedTransformA.basis.getColumn(2, axisA1);
            var axisB0:Vector3f = new Vector3f();
            calculatedTransformB.basis.getColumn(1, axisB0);

            var rot:Float = Math.atan2(axisB0.dot(axisA1), axisB0.dot(axisA0));
            if (rot < lowerAngLimit)
			{
                angDepth = rot - lowerAngLimit;
                solveAngLim = true;
            } 
			else if (rot > upperAngLimit)
			{
                angDepth = rot - upperAngLimit;
                solveAngLim = true;
            }
        }
    }

    // access for PE Solver

    public function getAncorInA(out:Vector3f):Vector3f
	{
        var tmpTrans:Transform = new Transform();

        var ancorInA:Vector3f = out;
        ancorInA.scaleAdd((lowerLinLimit + upperLinLimit) * 0.5, sliderAxis, realPivotAInW);
        rbA.getCenterOfMassTransform(tmpTrans);
        tmpTrans.inverse();
        tmpTrans.transform(ancorInA);
        return ancorInA;
    }

    public function getAncorInB(out:Vector3f):Vector3f
	{
        var ancorInB:Vector3f = out;
        ancorInB.fromVector3f(frameInB.origin);
        return ancorInB;
    }

	
}