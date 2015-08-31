package com.bulletphysics.dynamics.constraintsolver;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.TransformUtil;
import org.angle3d.math.Vector3f;

/**
 * SolverBody is an internal data structure for the constraint solver. Only necessary
 * data is packed to increase cache coherence/performance.
 * @author weilichuang
 */
class SolverBody
{
    public var angularVelocity:Vector3f = new Vector3f();
    public var angularFactor:Float;
    public var invMass:Float;
    public var friction:Float;
    public var originalBody:RigidBody;
    public var linearVelocity:Vector3f = new Vector3f();
    public var centerOfMassPosition:Vector3f = new Vector3f();

    public var pushVelocity:Vector3f = new Vector3f();
    public var turnVelocity:Vector3f = new Vector3f();

	private var tmpVec:Vector3f = new Vector3f();
    public inline function getVelocityInLocalPoint(rel_pos:Vector3f, velocity:Vector3f):Void
	{
        tmpVec.crossBy(angularVelocity, rel_pos);
        velocity.addBy(linearVelocity, tmpVec);
    }

    /**
     * Optimization for the iterative solver: avoid calculating constant terms involving inertia, normal, relative position.
     */
    public inline function internalApplyImpulse(linearComponent:Vector3f, angularComponent:Vector3f, impulseMagnitude:Float):Void 
	{
        if (invMass != 0) 
		{
            linearVelocity.scaleAddBy(impulseMagnitude,  linearComponent, linearVelocity);
            angularVelocity.scaleAddBy(impulseMagnitude * angularFactor, angularComponent, angularVelocity);
        }
    }

    public inline function internalApplyPushImpulse(linearComponent:Vector3f, angularComponent:Vector3f, impulseMagnitude:Float):Void 
	{
        if (invMass != 0)
		{
            pushVelocity.scaleAddBy(impulseMagnitude, linearComponent, pushVelocity);
			turnVelocity.scaleAddBy(impulseMagnitude * angularFactor, angularComponent, turnVelocity);
        }
    }

    public inline function writebackVelocity():Void 
	{
        if (invMass != 0)
		{
            originalBody.setLinearVelocity(linearVelocity);
            originalBody.setAngularVelocity(angularVelocity);
            //m_originalBody->setCompanionId(-1);
        }
    }

    public function writebackVelocity2(timeStep:Float):Void 
	{
        if (invMass != 0)
		{
            originalBody.setLinearVelocity(linearVelocity);
            originalBody.setAngularVelocity(angularVelocity);

            // correct the position/orientation based on push/turn recovery
            var newTransform:Transform = new Transform();
            var curTrans:Transform = originalBody.getWorldTransformTo(new Transform());
            TransformUtil.integrateTransform(curTrans, pushVelocity, turnVelocity, timeStep, newTransform);
            originalBody.setWorldTransform(newTransform);

            //m_originalBody->setCompanionId(-1);
        }
    }

    public inline function readVelocity():Void 
	{
        if (invMass != 0)
		{
            originalBody.getLinearVelocity(linearVelocity);
            originalBody.getAngularVelocityTo(angularVelocity);
        }
    }
}