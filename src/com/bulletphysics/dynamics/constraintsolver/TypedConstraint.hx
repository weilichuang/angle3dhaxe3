package com.bulletphysics.dynamics.constraintsolver;
import com.vecmath.Vector3f;

/**
 * TypedConstraint is the base class for Bullet constraints and vehicles.
 * @author weilichuang
 */
class TypedConstraint
{
    private static var s_fixed:RigidBody;

    private static function getFixed():RigidBody
	{
        if (s_fixed == null) 
		{
            s_fixed = new RigidBody(0, null, null);
        }
        return s_fixed;
    }

    private var userConstraintType:Int = -1;
    private var userConstraintId:Int = -1;

    private var constraintType:TypedConstraintType;

    private var rbA:RigidBody;
    private var rbB:RigidBody;
    private var appliedImpulse:Float = 0;

    public function new(type:TypedConstraintType)
	{
        this.constraintType = type;
    }
	
	public function init(type:TypedConstraintType, rbA:RigidBody = null, rbB:RigidBody = null)
	{
        this.constraintType = type;
        this.rbA = rbA != null ? rbA : getFixed();
        this.rbB = rbB != null ? rbB : getFixed();
        getFixed().setMassProps(0, new Vector3f(0, 0, 0));
    }

    public function buildJacobian():Void
	{
		
	}

    public function solveConstraint(timeStep:Float):Void
	{
		
	}

    public function getRigidBodyA():RigidBody
	{
        return rbA;
    }

    public function getRigidBodyB():RigidBody
	{
        return rbB;
    }

    public function getUserConstraintType():Int
	{
        return userConstraintType;
    }

    public function setUserConstraintType(userConstraintType:Int):Void 
	{
        this.userConstraintType = userConstraintType;
    }

    public function getUserConstraintId():Int 
	{
        return userConstraintId;
    }

    public function getUid():Int 
	{
        return userConstraintId;
    }

    public function setUserConstraintId(userConstraintId:Int):Void
	{
        this.userConstraintId = userConstraintId;
    }

    public function getAppliedImpulse():Float
	{
        return appliedImpulse;
    }

    public function getConstraintType():TypedConstraintType
	{
        return constraintType;
    }
	
}