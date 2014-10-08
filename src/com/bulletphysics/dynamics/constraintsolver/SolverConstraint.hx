package com.bulletphysics.dynamics.constraintsolver;
import com.vecmath.Vector3f;

/**
 * 1D constraint along a normal axis between bodyA and bodyB. It can be combined
 * to solve contact and friction constraints.
 * @author weilichuang
 */
class SolverConstraint
{

	public var relpos1CrossNormal:Vector3f = new Vector3f();
    public var contactNormal:Vector3f = new Vector3f();

    public var relpos2CrossNormal:Vector3f = new Vector3f();
    public var angularComponentA:Vector3f = new Vector3f();

    public var angularComponentB:Vector3f = new Vector3f();

    public var appliedPushImpulse:Float;

    public var appliedImpulse:Float;
    public var solverBodyIdA:Int;
    public var solverBodyIdB:Int;

    public var friction:Float;
    public var restitution:Float;
    public var jacDiagABInv:Float;
    public var penetration:Float;

    public var constraintType:SolverConstraintType;
    public var frictionIndex:Int;
    public var originalContactPoint:Dynamic;
	
}