package org.angle3d.bullet.joints;

import com.bulletphysics.dynamics.constraintsolver.Generic6DofConstraint;
import com.bulletphysics.dynamics.constraintsolver.Generic6DofSpringConstraint;
import org.angle3d.bullet.objects.PhysicsRigidBody;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Vector3f;
import org.angle3d.error.Assert;

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
 */
class SixDofSpringJoint extends SixDofJoint
{
	private var springS:Array<Bool> = [false, false, false, false, false, false];
	private var stiffnessS:Array<Float> = [-1.0, -1.0, -1.0, -1.0, -1.0, -1.0];
	private var dampingS:Array<Float> = [-1.0, -1.0, -1.0, -1.0, -1.0, -1.0];

	public function new(nodeA:PhysicsRigidBody, nodeB:PhysicsRigidBody, pivotA:Vector3f, pivotB:Vector3f, rotA:Matrix3f=null, rotB:Matrix3f=null, useLinearReferenceFrameA:Bool=true) 
	{
		super(nodeA, nodeB, pivotA, pivotB, rotA, rotB, useLinearReferenceFrameA);
		
		constraint = new Generic6DofSpringConstraint();
		cast(constraint, Generic6DofSpringConstraint).fromGeneric6DofConstraint(cast constraint);
	}
	
	public function enableSpring(index:Int, onOff:Bool):Void
	{
        Assert.assert ((index >= 0) && (index < 6));
        springS[index] = onOff;
    	cast(constraint,Generic6DofSpringConstraint).enableSpring(index, onOff);
    }
    
    public function setStiffness(index:Int, stiffness:Float):Void
	{
        Assert.assert ((index >= 0) && (index < 6));
        stiffnessS[index] = stiffness;
    	cast(constraint,Generic6DofSpringConstraint).setStiffness(index, stiffness);
    }

    public function setDamping(index:Int, damping:Float):Void
	{
        Assert.assert((index >= 0) && (index < 6));
        dampingS[index] = damping;
    	cast(constraint,Generic6DofSpringConstraint).setDamping(index, damping);
    }

    /**
     *  set the current constraint position/orientation as an equilibrium point for all DOF
     */
    public function setEquilibriumPoint():Void
	{ 
    	cast(constraint,Generic6DofSpringConstraint).setEquilibriumPoint();
    }

    /**
     * set the current constraint position/orientation as an equilibrium point for given DOF
     * @param index
     */
    public function setEquilibriumPointAt(index:Int):Void
	{ 
    	cast(constraint,Generic6DofSpringConstraint).setEquilibriumPointAt(index);
    }
	
}