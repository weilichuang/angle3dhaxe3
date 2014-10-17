package com.bulletphysics.dynamics.constraintsolver;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.VectorUtil;
import com.bulletphysics.util.Assert;

/**
 * Generic 6 DOF constraint that allows to set spring motors to any translational and rotational DOF
 * DOF index used in enableSpring() and setStiffness() means:
 *    0 : translation X
 *    1 : translation Y
 *    2 : translation Z
 *    3 : rotation X (3rd Euler rotational around new position of X axis, range [-PI+epsilon, PI-epsilon] )
 *    4 : rotation Y (2nd Euler rotational around new position of Y axis, range [-PI/2+epsilon, PI/2-epsilon] )
 *    5 : rotation Z (1st Euler rotational around Z axis, range [-PI+epsilon, PI-epsilon] )
 *
 * @author Ported to JBullet from Bullet by gideonk as part of the QIntBio project
 */
class Generic6DofSpringConstraint extends Generic6DofConstraint
{
	private var springEnabled:Array<Bool> = [];
	private var equilibriumPoint:Array<Float> = [];
	private var springStiffness:Array<Float> = [];
	private var springDamping:Array<Float> = [];// between 0 and 1 (1 == no damping)

	public function new() 
	{
		super();
	}
	
	public function fromGeneric6DofConstraint(constraint:Generic6DofSpringConstraint):Void
	{
		init2(constraint.rbA, constraint.rbB, constraint.frameInA, constraint.frameInB, constraint.useLinearReferenceFrameA);
	}
	
	override public function init2(rbA:RigidBody, rbB:RigidBody, frameInA:Transform, frameInB:Transform, useLinearReferenceFrameA:Bool)
	{
		super.init2(rbA, rbB, frameInA, frameInB, useLinearReferenceFrameA);
		
        this.constraintType = TypedConstraintType.D6_SPRING_CONSTRAINT_TYPE;

        for (i in 0...6) 
		{
            springEnabled[i] = false;
            equilibriumPoint[i] = 0.;
            springStiffness[i] = 0.;
            springDamping[i] = 1.;
        }
    }
	
	public function enableSpring(index:Int, onOff:Bool):Void
	{
        Assert.assert((index >= 0) && (index < 6));
        springEnabled[index] = onOff;
        if (index < 3) 
		{
            linearLimits.enableMotor[index] = onOff;
        } 
		else 
		{
            angularLimits[index - 3].enableMotor = onOff;
        }
    }
    
    public function setStiffness(index:Int, stiffness:Float):Void
	{
        Assert.assert((index >= 0) && (index < 6));
        springStiffness[index] = stiffness;
    }

    public function setDamping(index:Int, damping:Float):Void
	{
        Assert.assert((index >= 0) && (index < 6));
        springDamping[index] = damping;
    }

    /**
     *  set the current constraint position/orientation as an equilibrium point for all DOF
     */
    public function setEquilibriumPoint():Void
	{ 
    	calculateTransforms();

        for (i in 0...3)
		{
            equilibriumPoint[i] = VectorUtil.getCoord(calculatedLinearDiff, i);
        }
        for (i in 0...3)
		{
            equilibriumPoint[i + 3] = VectorUtil.getCoord(calculatedAxisAngleDiff, i);
        }
    }

    /**
     * set the current constraint position/orientation as an equilibrium point for given DOF
     * @param index
     */
    public function setEquilibriumPointAt(index:Int):Void
	{ 
    	Assert.assert ((index >= 0) && (index < 6));
        calculateTransforms();
        if (index < 3) 
		{
            equilibriumPoint[index] = VectorUtil.getCoord(calculatedLinearDiff, index);
        } 
		else
		{
            equilibriumPoint[index] = VectorUtil.getCoord(calculatedAxisAngleDiff, index - 3);
        }
    }
}