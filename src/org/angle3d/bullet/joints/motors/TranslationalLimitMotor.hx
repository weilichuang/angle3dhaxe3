package org.angle3d.bullet.joints.motors;
import org.angle3d.bullet.util.Converter;
import org.angle3d.math.Vector3f;

/**
 * ...
 
 */
class TranslationalLimitMotor
{
	private var motor:com.bulletphysics.dynamics.constraintsolver.TranslationalLimitMotor;

    public function new(motor:com.bulletphysics.dynamics.constraintsolver.TranslationalLimitMotor)
	{
        this.motor = motor;
    }

    public function getMotor():com.bulletphysics.dynamics.constraintsolver.TranslationalLimitMotor
	{
        return motor;
    }

    public function getLowerLimit():Vector3f
	{
        return motor.lowerLimit;
    }

    public function setLowerLimit(lowerLimit:Vector3f):Void 
	{
        motor.lowerLimit.copyFrom(lowerLimit);
    }

    public function getUpperLimit():Vector3f 
	{
        return motor.upperLimit;
    }

    public function setUpperLimit(upperLimit:Vector3f):Void 
	{
		motor.upperLimit.copyFrom(upperLimit);
    }

    public function getAccumulatedImpulse():Vector3f 
	{
        return motor.accumulatedImpulse;
    }

    public function setAccumulatedImpulse(accumulatedImpulse:Vector3f):Void 
	{
        motor.accumulatedImpulse.copyFrom(accumulatedImpulse);
    }

    public function getLimitSoftness():Float 
	{
        return motor.limitSoftness;
    }

    public function setLimitSoftness(limitSoftness:Float):Void
	{
        motor.limitSoftness = limitSoftness;
    }

    public function getDamping():Float
	{
        return motor.damping;
    }

    public function setDamping(damping:Float):Void 
	{
        motor.damping = damping;
    }

    public function getRestitution():Float
	{
        return motor.restitution;
    }

    public function setRestitution(restitution:Float):Void 
	{
        motor.restitution = restitution;
    }
	
}