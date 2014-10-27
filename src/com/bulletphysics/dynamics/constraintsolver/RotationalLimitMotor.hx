package com.bulletphysics.dynamics.constraintsolver;
import vecmath.Vector3f;

/**
 * Rotation limit structure for generic joints.
 * @author weilichuang
 */
class RotationalLimitMotor
{

	//protected final BulletStack stack = BulletStack.get();

    public var loLimit:Float; //!< joint limit
    public var hiLimit:Float; //!< joint limit
    public var targetVelocity:Float; //!< target motor velocity
    public var maxMotorForce:Float; //!< max force on motor
    public var maxLimitForce:Float; //!< max force on limit
    public var damping:Float; //!< Damping.
    public var limitSoftness:Float; //! Relaxation factor
    public var ERP:Float; //!< Error tolerance factor when joint is at limit
    public var bounce:Float; //!< restitution factor
    public var enableMotor:Bool;

    public var currentLimitError:Float;//!  How much is violated this limit
    public var currentLimit:Int;//!< 0=free, 1=at lo limit, 2=at hi limit
    public var accumulatedImpulse:Float;

    public function new()
	{
		accumulatedImpulse = 0.;
		bounce = 0.0;
		damping = 1.0;
		targetVelocity = 0;
		maxMotorForce = 0.1;
		maxLimitForce = 300.0;
		loLimit = -BulletGlobals.SIMD_INFINITY;
		hiLimit = BulletGlobals.SIMD_INFINITY;
		ERP = 0.5;
		limitSoftness = 0.5;
		currentLimit = 0;
		currentLimitError = 0;
		enableMotor = false;
    }

    public function fromRotationalLimitMotor(limot:RotationalLimitMotor):Void
	{
        targetVelocity = limot.targetVelocity;
        maxMotorForce = limot.maxMotorForce;
        limitSoftness = limot.limitSoftness;
        loLimit = limot.loLimit;
        hiLimit = limot.hiLimit;
        ERP = limot.ERP;
        bounce = limot.bounce;
        currentLimit = limot.currentLimit;
        currentLimitError = limot.currentLimitError;
        enableMotor = limot.enableMotor;
    }

    /**
     * Is limited?
     */
    public function isLimited():Bool
	{
        if (loLimit >= hiLimit) 
			return false;
        return true;
    }

    /**
     * Need apply correction?
     */
    public function needApplyTorques():Bool
	{
        if (currentLimit == 0 && enableMotor == false) 
			return false;
        return true;
    }

    /**
     * Calculates error. Calculates currentLimit and currentLimitError.
     */
    public function testLimitValue(test_value:Float):Float
	{
        if (loLimit > hiLimit) 
		{
            currentLimit = 0; // Free from violation
            return 0;
        }

        if (test_value < loLimit)
		{
            currentLimit = 1; // low limit violation
            currentLimitError = test_value - loLimit;
            return 1;
        }
		else if (test_value > hiLimit)
		{
            currentLimit = 2; // High limit violation
            currentLimitError = test_value - hiLimit;
            return 2;
        }

        currentLimit = 0; // Free from violation
        return 0;
    }

    /**
     * Apply the correction impulses for two bodies.
     */
    public function solveAngularLimits(timeStep:Float, axis:Vector3f, jacDiagABInv:Float, body0:RigidBody, body1:RigidBody):Float
	{
        if (needApplyTorques() == false)
		{
            return 0.0;
        }

        var target_velocity:Float = this.targetVelocity;
        var maxMotorForce:Float = this.maxMotorForce;

        // current error correction
        if (currentLimit != 0)
		{
            target_velocity = -ERP * currentLimitError / (timeStep);
            maxMotorForce = maxLimitForce;
        }

        maxMotorForce *= timeStep;

        // current velocity difference
        var vel_diff:Vector3f = body0.getAngularVelocityTo(new Vector3f());
        if (body1 != null)
		{
            vel_diff.sub(body1.getAngularVelocity());
        }

        var rel_vel:Float = axis.dot(vel_diff);

        // correction velocity
        var motor_relvel:Float = limitSoftness * (target_velocity - damping * rel_vel);

        if (motor_relvel < BulletGlobals.FLT_EPSILON && motor_relvel > -BulletGlobals.FLT_EPSILON) 
		{
            return 0.0; // no need for applying force
        }

        // correction impulse
        var unclippedMotorImpulse:Float = (1 + bounce) * motor_relvel * jacDiagABInv;

        // clip correction impulse
        var clippedMotorImpulse:Float;

        // todo: should clip against accumulated impulse
        if (unclippedMotorImpulse > 0.0)
		{
            clippedMotorImpulse = unclippedMotorImpulse > maxMotorForce ? maxMotorForce : unclippedMotorImpulse;
        } 
		else
		{
            clippedMotorImpulse = unclippedMotorImpulse < -maxMotorForce ? -maxMotorForce : unclippedMotorImpulse;
        }

        // sort with accumulated impulses
        var lo:Float = -1e30;
        var hi:Float = 1e30;

        var oldaccumImpulse:Float = accumulatedImpulse;
        var sum:Float = oldaccumImpulse + clippedMotorImpulse;
        accumulatedImpulse = sum > hi ? 0 : sum < lo ? 0 : sum;

        clippedMotorImpulse = accumulatedImpulse - oldaccumImpulse;

        var motorImp:Vector3f = new Vector3f();
        motorImp.scale2(clippedMotorImpulse, axis);

        body0.applyTorqueImpulse(motorImp);
        if (body1 != null)
		{
            motorImp.negate();
            body1.applyTorqueImpulse(motorImp);
        }

        return clippedMotorImpulse;
    }
}