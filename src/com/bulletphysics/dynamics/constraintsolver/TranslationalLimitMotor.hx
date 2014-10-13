package com.bulletphysics.dynamics.constraintsolver;
import com.bulletphysics.linearmath.VectorUtil;
import vecmath.Vector3f;

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

    public function new() 
	{
        lowerLimit.setTo(0, 0, 0);
        upperLimit.setTo(0, 0, 0);
        accumulatedImpulse.setTo(0, 0, 0);

        limitSoftness = 0.7;
        damping = 1.0;
        restitution = 0.5;
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
        return (VectorUtil.getCoord(upperLimit, limitIndex) >= VectorUtil.getCoord(lowerLimit, limitIndex));
    }

    public function solveLinearAxis(timeStep:Float, jacDiagABInv:Float, 
									body1:RigidBody, pointInA:Vector3f, 
									body2:RigidBody, pointInB:Vector3f, 
									limit_index:Int, axis_normal_on_a:Vector3f, anchorPos:Vector3f):Float
	{
        var tmp:Vector3f = new Vector3f();
        var tmpVec:Vector3f = new Vector3f();

        // find relative velocity
        var rel_pos1:Vector3f = new Vector3f();
        //rel_pos1.sub(pointInA, body1.getCenterOfMassPosition(tmpVec));
        rel_pos1.sub(anchorPos, body1.getCenterOfMassPosition(tmpVec));

        var rel_pos2:Vector3f = new Vector3f();
        //rel_pos2.sub(pointInB, body2.getCenterOfMassPosition(tmpVec));
        rel_pos2.sub(anchorPos, body2.getCenterOfMassPosition(tmpVec));

        var vel1:Vector3f = body1.getVelocityInLocalPoint(rel_pos1, new Vector3f());
        var vel2:Vector3f = body2.getVelocityInLocalPoint(rel_pos2, new Vector3f());
        var vel:Vector3f = new Vector3f();
        vel.sub(vel1, vel2);

        var rel_vel:Float = axis_normal_on_a.dot(vel);

        // apply displacement correction

        // positional error (zeroth order error)
        tmp.sub(pointInA, pointInB);
        var depth:Float = -(tmp).dot(axis_normal_on_a);
        var lo:Float = -1e30;
        var hi:Float = 1e30;

        var minLimit:Float = VectorUtil.getCoord(lowerLimit, limit_index);
        var maxLimit:Float = VectorUtil.getCoord(upperLimit, limit_index);

        // handle the limits
        if (minLimit < maxLimit)
		{
            {
                if (depth > maxLimit) 
				{
                    depth -= maxLimit;
                    lo = 0;

                } 
				else 
				{
                    if (depth < minLimit) 
					{
                        depth -= minLimit;
                        hi = 0;
                    } 
					else
					{
                        return 0.0;
                    }
                }
            }
        }

        var normalImpulse:Float = limitSoftness * (restitution * depth / timeStep - damping * rel_vel) * jacDiagABInv;

        var oldNormalImpulse:Float = VectorUtil.getCoord(accumulatedImpulse, limit_index);
        var sum:Float = oldNormalImpulse + normalImpulse;
        VectorUtil.setCoord(accumulatedImpulse, limit_index, sum > hi ? 0 : sum < lo ? 0 : sum);
        normalImpulse = VectorUtil.getCoord(accumulatedImpulse, limit_index) - oldNormalImpulse;

        var impulse_vector:Vector3f = new Vector3f();
        impulse_vector.scale(normalImpulse, axis_normal_on_a);
        body1.applyImpulse(impulse_vector, rel_pos1);

        tmp.negate(impulse_vector);
        body2.applyImpulse(tmp, rel_pos2);
        return normalImpulse;
    }
	
}