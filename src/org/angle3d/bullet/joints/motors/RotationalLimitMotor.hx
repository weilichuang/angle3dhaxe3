package org.angle3d.bullet.joints.motors;

/**
 * ...
 
 */
class RotationalLimitMotor
{
	private var motor:com.bulletphysics.dynamics.constraintsolver.RotationalLimitMotor;

    public function new(motor:com.bulletphysics.dynamics.constraintsolver.RotationalLimitMotor)
	{
        this.motor = motor;
    }

    public function getMotor():com.bulletphysics.dynamics.constraintsolver.RotationalLimitMotor
	{
        return motor;
    }

    public function getLoLimit():Float
	{
        return motor.loLimit;
    }

    public function setLoLimit(loLimit:Float):Void 
	{
        motor.loLimit = loLimit;
    }

    public function getHiLimit():Float 
	{
        return motor.hiLimit;
    }

    public function setHiLimit(hiLimit:Float):Void
	{
        motor.hiLimit = hiLimit;
    }

    public function getTargetVelocity():Float
	{
        return motor.targetVelocity;
    }

    public function setTargetVelocity(targetVelocity:Float):Void 
	{
        motor.targetVelocity = targetVelocity;
    }

    public function getMaxMotorForce():Float 
	{
        return motor.maxMotorForce;
    }

    public function setMaxMotorForce(maxMotorForce:Float):Void 
	{
        motor.maxMotorForce = maxMotorForce;
    }

    public function getMaxLimitForce():Float 
	{
        return motor.maxLimitForce;
    }

    public function setMaxLimitForce(maxLimitForce:Float):Void 
	{
        motor.maxLimitForce = maxLimitForce;
    }

    public function getDamping():Float 
	{
        return motor.damping;
    }

    public function setDamping(damping:Float):Void 
	{
        motor.damping = damping;
    }

    public function getLimitSoftness():Float
	{
        return motor.limitSoftness;
    }

    public function setLimitSoftness(limitSoftness:Float):Void
	{
        motor.limitSoftness = limitSoftness;
    }

    public function getERP():Float 
	{
        return motor.ERP;
    }

    public function setERP(ERP:Float):Void
	{
        motor.ERP = ERP;
    }

    public function getBounce():Float
	{
        return motor.bounce;
    }

    public function setBounce(bounce:Float):Void 
	{
        motor.bounce = bounce;
    }

    public function isEnableMotor():Bool 
	{
        return motor.enableMotor;
    }

    public function setEnableMotor(enableMotor:Bool):Void
	{
        motor.enableMotor = enableMotor;
    }
	
}