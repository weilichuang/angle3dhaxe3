package com.bulletphysics.dynamics.constraintsolver;
import angle3d.math.Vector3f;

/**
 * Stores some extra information to each contact point. It is not in the contact
 * point, because that want to keep the collision detection independent from the
 * constraint solver.
 
 */
class ConstraintPersistentData
{

	/**
     * total applied impulse during most recent frame
     */
    public var appliedImpulse:Float = 0;
    public var prevAppliedImpulse:Float = 0;
    public var accumulatedTangentImpulse0:Float = 0;
    public var accumulatedTangentImpulse1:Float = 0;

    public var jacDiagABInv:Float = 0;
    public var jacDiagABInvTangent0:Float;
    public var jacDiagABInvTangent1:Float;
    public var persistentLifeTime:Int = 0;
    public var restitution:Float = 0;
    public var friction:Float = 0;
    public var penetration:Float = 0;
    public var frictionWorldTangential0:Vector3f = new Vector3f();
    public var frictionWorldTangential1:Vector3f = new Vector3f();

    public var frictionAngularComponent0A:Vector3f = new Vector3f();
    public var frictionAngularComponent0B:Vector3f = new Vector3f();
    public var frictionAngularComponent1A:Vector3f = new Vector3f();
    public var frictionAngularComponent1B:Vector3f = new Vector3f();

    //some data doesn't need to be persistent over frames: todo: clean/reuse this
    public var angularComponentA:Vector3f = new Vector3f();
    public var angularComponentB:Vector3f = new Vector3f();

    public var contactSolverFunc:ContactSolverFunc = null;
    public var frictionSolverFunc:ContactSolverFunc = null;
	
	public function new()
	{
		
	}

    public function reset():Void
	{
        appliedImpulse = 0;
        prevAppliedImpulse = 0;
        accumulatedTangentImpulse0 = 0;
        accumulatedTangentImpulse1 = 0;

        jacDiagABInv = 0;
        jacDiagABInvTangent0 = 0;
        jacDiagABInvTangent1 = 0;
        persistentLifeTime = 0;
        restitution = 0;
        friction = 0;
        penetration = 0;
        frictionWorldTangential0.setTo(0, 0, 0);
        frictionWorldTangential1.setTo(0, 0, 0);

        frictionAngularComponent0A.setTo(0, 0, 0);
        frictionAngularComponent0B.setTo(0, 0, 0);
        frictionAngularComponent1A.setTo(0, 0, 0);
        frictionAngularComponent1B.setTo(0, 0, 0);

        angularComponentA.setTo(0, 0, 0);
        angularComponentB.setTo(0, 0, 0);

        contactSolverFunc = null;
        frictionSolverFunc = null;
    }
	
}