package com.bulletphysics.dynamics.constraintsolver;
import com.bulletphysics.linearmath.LinearMathUtil;
import flash.Vector;
import com.vecmath.Vector3f;

/**
 * ...
 * @author weilichuang
 */
class TranslationalLimitMotor
{
    public var lowerLimit:Vector3f = new Vector3f(); //!< the constraint lower limits
    public var upperLimit:Vector3f = new Vector3f(); //!< the constraint upper limits
    public var accumulatedImpulse:Vector3f = new Vector3f();

    public var limitSoftness:Float; //!< Softness for linear limit
    public var damping:Float; //!< Damping for linear limit
    public var restitution:Float; //! Bounce parameter for linear limit
	
	// added for 6dofSpring
	public var enableMotor:Vector<Bool>   = new Vector<Bool>(3);
	public var targetVelocity:Vector3f    = new Vector3f();   //!< target motor velocity
	public var maxMotorForce:Vector3f     = new Vector3f();   //!< max force on motor
	public var maxLimitForce:Vector3f     = new Vector3f();   //!< max force on limit
	public var currentLimitError:Vector3f = new Vector3f();   //!  How much is violated this limit
	public var currentLinearDiff:Vector3f = new Vector3f();   //!  Current relative offset of constraint frames
	public var currentLimit:Vector<Int>   = new Vector<Int>(3);       //!< 0=free, 1=at lower limit, 2=at upper limit

    public function new() 
	{
        lowerLimit.setTo(0, 0, 0);
        upperLimit.setTo(0, 0, 0);
        accumulatedImpulse.setTo(0, 0, 0);

        limitSoftness = 0.7;
        damping = 1.0;
        restitution = 0.5;
		
		targetVelocity.setTo(0, 0, 0);
		maxMotorForce.setTo(0.1, 0.1, 0.1);
		maxLimitForce.setTo(300.0, 300.0, 300.0);

		for (i in 0...3)
		{
			enableMotor[i] = false;
		}
    }

    public function fromTranslationalLimitMotor(other:TranslationalLimitMotor):Void
	{
        lowerLimit.fromVector3f(other.lowerLimit);
        upperLimit.fromVector3f(other.upperLimit);
        accumulatedImpulse.fromVector3f(other.accumulatedImpulse);

        limitSoftness = other.limitSoftness;
        damping = other.damping;
        restitution = other.restitution;
    }

    /**
     * Test limit.<p>
     * - free means upper &lt; lower,<br>
     * - locked means upper == lower<br>
     * - limited means upper &gt; lower<br>
     * - limitIndex: first 3 are linear, next 3 are angular
     */
    public function isLimited(limitIndex:Int):Bool
	{
        return (LinearMathUtil.getCoord(upperLimit, limitIndex) >= LinearMathUtil.getCoord(lowerLimit, limitIndex));
    }
	
	/**
	 * Need apply correction?
	 */
	public function needApplyForces(idx:Int):Bool
	{
		if (currentLimit[idx] == 0 && enableMotor[idx] == false)
		{
			return false;
		} 
		return true;
	}
	
	public function testLimitValue(limitIndex:Int, test_value:Float):Int
	{
		var loLimit:Float = LinearMathUtil.getCoord(lowerLimit, limitIndex);
		var hiLimit:Float = LinearMathUtil.getCoord(upperLimit, limitIndex);
		if(loLimit > hiLimit)
		{
			currentLimit[limitIndex] = 0;//Free from violation
			LinearMathUtil.setCoord(currentLimitError, limitIndex, 0.);
			return 0;
		}

		if (test_value < loLimit)
		{
			currentLimit[limitIndex] = 2;//low limit violation
			LinearMathUtil.setCoord(currentLimitError, limitIndex, test_value - loLimit);
			return 2;
		}
		else if (test_value > hiLimit)
		{
			currentLimit[limitIndex] = 1;//High limit violation
			LinearMathUtil.setCoord(currentLimitError, limitIndex, test_value - hiLimit);
			return 1;
		}

		currentLimit[limitIndex] = 0;//Free from violation
		LinearMathUtil.setCoord(currentLimitError, limitIndex, 0.);
		return 0;
	}

    public function solveLinearAxis(timeStep:Float, jacDiagABInv:Float, 
									body1:RigidBody, pointInA:Vector3f, 
									body2:RigidBody, pointInB:Vector3f, 
									limit_index:Int, axis_normal_on_a:Vector3f, anchorPos:Vector3f):Float
	{
        var tmp:Vector3f = new Vector3f();
		
        // find relative velocity
        var rel_pos1:Vector3f = new Vector3f();
        //rel_pos1.sub(pointInA, body1.getCenterOfMassPosition());
        rel_pos1.sub2(anchorPos, body1.getCenterOfMassPosition());

        var rel_pos2:Vector3f = new Vector3f();
        //rel_pos2.sub(pointInB, body2.getCenterOfMassPosition());
        rel_pos2.sub2(anchorPos, body2.getCenterOfMassPosition());

        var vel1:Vector3f = body1.getVelocityInLocalPoint(rel_pos1, new Vector3f());
        var vel2:Vector3f = body2.getVelocityInLocalPoint(rel_pos2, new Vector3f());
        var vel:Vector3f = new Vector3f();
        vel.sub2(vel1, vel2);

        var rel_vel:Float = axis_normal_on_a.dot(vel);

        // apply displacement correction
		var target_velocity:Float   = LinearMathUtil.getCoord(this.targetVelocity, limit_index);
		var maxMotorForce:Float     = LinearMathUtil.getCoord(this.maxMotorForce, limit_index);

		var limErr:Float = LinearMathUtil.getCoord(currentLimitError, limit_index);
		if (currentLimit[limit_index] != 0)
		{
			target_velocity = restitution * limErr / (timeStep);
			maxMotorForce = LinearMathUtil.getCoord(maxLimitForce, limit_index);
		}
		maxMotorForce *= timeStep;


                // correction velocity
		var motor_relvel:Float = limitSoftness * (target_velocity - damping * rel_vel);
		if (motor_relvel < BulletGlobals.FLT_EPSILON && motor_relvel > -BulletGlobals.FLT_EPSILON)
		{
			return 0.0; // no need for applying force
		}
                
                // correction impulse
		var unclippedMotorImpulse:Float = motor_relvel * jacDiagABInv;

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

		var normalImpulse:Float = clippedMotorImpulse;

		// sort with accumulated impulses
		var lo:Float = -1e30;
		var hi:Float = 1e30;

                
		var oldNormalImpulse:Float = LinearMathUtil.getCoord(accumulatedImpulse, limit_index);
		var sum:Float = oldNormalImpulse + normalImpulse;
		LinearMathUtil.setCoord(accumulatedImpulse, limit_index, sum > hi ? 0 : sum < lo ? 0 : sum);
		normalImpulse = LinearMathUtil.getCoord(accumulatedImpulse, limit_index) - oldNormalImpulse;

		var impulse_vector:Vector3f = new Vector3f();
		impulse_vector.scale2(normalImpulse, axis_normal_on_a);
		body1.applyImpulse(impulse_vector, rel_pos1);

		tmp.negateBy(impulse_vector);
		body2.applyImpulse(tmp, rel_pos2);
		return normalImpulse;
    }
	
}