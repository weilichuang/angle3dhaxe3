package org.angle3d.bullet.joints;

import com.bulletphysics.dynamics.constraintsolver.SliderConstraint;
import com.bulletphysics.linearmath.Transform;
import org.angle3d.bullet.objects.PhysicsRigidBody;
import org.angle3d.bullet.util.Converter;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Vector3f;

/**
 * <i>From bullet manual:</i><br>
 * The slider constraint allows the body to rotate around one axis and translate along this axis.

 */
class SliderJoint extends PhysicsJoint 
{
    private var rotA:Matrix3f = new Matrix3f();
	private var rotB:Matrix3f = new Matrix3f();
    private var useLinearReferenceFrameA:Bool;


    /**
     * @param pivotA local translation of the joint connection point in node A
     * @param pivotB local translation of the joint connection point in node B
     */
	public function new(nodeA:PhysicsRigidBody, nodeB:PhysicsRigidBody, pivotA:Vector3f, pivotB:Vector3f,
						rotA:Matrix3f = null, rotB:Matrix3f = null, useLinearReferenceFrameA:Bool = true )
    {
        super(nodeA, nodeB, pivotA, pivotB);
		if (rotA != null)
			this.rotA.copyFrom(rotA);
        if (rotB != null)
			this.rotB.copyFrom(rotB);
        this.useLinearReferenceFrameA = useLinearReferenceFrameA;
        createJoint();
    }

    public function getLowerLinLimit():Float
	{
        return cast(constraint,SliderConstraint).getLowerLinLimit();
    }

    public function setLowerLinLimit(lowerLinLimit:Float):Void 
	{
        cast(constraint,SliderConstraint).setLowerLinLimit(lowerLinLimit);
    }

    public function getUpperLinLimit():Float
	{
        return cast(constraint,SliderConstraint).getUpperLinLimit();
    }

    public function setUpperLinLimit(upperLinLimit:Float):Void 
	{
        cast(constraint,SliderConstraint).setUpperLinLimit(upperLinLimit);
    }

    public function getLowerAngLimit():Float 
	{
        return cast(constraint,SliderConstraint).getLowerAngLimit();
    }

    public function setLowerAngLimit(lowerAngLimit:Float):Void 
	{
        cast(constraint,SliderConstraint).setLowerAngLimit(lowerAngLimit);
    }

    public function getUpperAngLimit():Float {
        return cast(constraint,SliderConstraint).getUpperAngLimit();
    }

    public function setUpperAngLimit(upperAngLimit:Float):Void 
	{
        cast(constraint,SliderConstraint).setUpperAngLimit(upperAngLimit);
    }

    public function getSoftnessDirLin():Float
	{
        return cast(constraint,SliderConstraint).getSoftnessDirLin();
    }

    public function setSoftnessDirLin(softnessDirLin:Float):Void 
	{
        cast(constraint,SliderConstraint).setSoftnessDirLin(softnessDirLin);
    }

    public function getRestitutionDirLin():Float 
	{
        return cast(constraint,SliderConstraint).getRestitutionDirLin();
    }

    public function setRestitutionDirLin(restitutionDirLin:Float):Void 
	{
        cast(constraint,SliderConstraint).setRestitutionDirLin(restitutionDirLin);
    }

    public function getDampingDirLin():Float
	{
        return cast(constraint,SliderConstraint).getDampingDirLin();
    }

    public function setDampingDirLin(dampingDirLin:Float):Void 
	{
        cast(constraint,SliderConstraint).setDampingDirLin(dampingDirLin);
    }

    public function getSoftnessDirAng():Float 
	{
        return cast(constraint,SliderConstraint).getSoftnessDirAng();
    }

    public function setSoftnessDirAng(softnessDirAng:Float):Void
	{
        cast(constraint,SliderConstraint).setSoftnessDirAng(softnessDirAng);
    }

    public function getRestitutionDirAng():Float 
	{
        return cast(constraint,SliderConstraint).getRestitutionDirAng();
    }

    public function setRestitutionDirAng(restitutionDirAng:Float):Void 
	{
        cast(constraint,SliderConstraint).setRestitutionDirAng(restitutionDirAng);
    }

    public function getDampingDirAng():Float 
	{
        return cast(constraint,SliderConstraint).getDampingDirAng();
    }

    public function setDampingDirAng(dampingDirAng:Float):Void 
	{
        cast(constraint,SliderConstraint).setDampingDirAng(dampingDirAng);
    }

    public function getSoftnessLimLin():Float 
	{
        return cast(constraint,SliderConstraint).getSoftnessLimLin();
    }

    public function setSoftnessLimLin(softnessLimLin:Float):Void 
	{
        cast(constraint,SliderConstraint).setSoftnessLimLin(softnessLimLin);
    }

    public function getRestitutionLimLin():Float 
	{
        return cast(constraint,SliderConstraint).getRestitutionLimLin();
    }

    public function setRestitutionLimLin(restitutionLimLin:Float):Void
	{
        cast(constraint,SliderConstraint).setRestitutionLimLin(restitutionLimLin);
    }

    public function getDampingLimLin():Float 
	{
        return cast(constraint,SliderConstraint).getDampingLimLin();
    }

    public function setDampingLimLin(dampingLimLin:Float):Void
	{
        cast(constraint,SliderConstraint).setDampingLimLin(dampingLimLin);
    }

    public function getSoftnessLimAng():Float
	{
        return cast(constraint,SliderConstraint).getSoftnessLimAng();
    }

    public function setSoftnessLimAng(softnessLimAng:Float):Void 
	{
        cast(constraint,SliderConstraint).setSoftnessLimAng(softnessLimAng);
    }

    public function getRestitutionLimAng():Float
	{
        return cast(constraint,SliderConstraint).getRestitutionLimAng();
    }

    public function setRestitutionLimAng(restitutionLimAng:Float):Void
	{
        cast(constraint,SliderConstraint).setRestitutionLimAng(restitutionLimAng);
    }

    public function getDampingLimAng():Float
	{
        return cast(constraint,SliderConstraint).getDampingLimAng();
    }

    public function setDampingLimAng(dampingLimAng:Float):Void 
	{
        cast(constraint,SliderConstraint).setDampingLimAng(dampingLimAng);
    }

    public function getSoftnessOrthoLin():Float 
	{
        return cast(constraint,SliderConstraint).getSoftnessOrthoLin();
    }

    public function setSoftnessOrthoLin(softnessOrthoLin:Float):Void 
	{
        cast(constraint,SliderConstraint).setSoftnessOrthoLin(softnessOrthoLin);
    }

    public function getRestitutionOrthoLin():Float 
	{
        return cast(constraint,SliderConstraint).getRestitutionOrthoLin();
    }

    public function setRestitutionOrthoLin(restitutionOrthoLin:Float):Void
	{
        cast(constraint,SliderConstraint).setRestitutionOrthoLin(restitutionOrthoLin);
    }

    public function getDampingOrthoLin():Float 
	{
        return cast(constraint,SliderConstraint).getDampingOrthoLin();
    }

    public function setDampingOrthoLin(dampingOrthoLin:Float):Void
	{
        cast(constraint,SliderConstraint).setDampingOrthoLin(dampingOrthoLin);
    }

    public function getSoftnessOrthoAng():Float 
	{
        return cast(constraint,SliderConstraint).getSoftnessOrthoAng();
    }

    public function setSoftnessOrthoAng(softnessOrthoAng:Float):Void
	{
        cast(constraint,SliderConstraint).setSoftnessOrthoAng(softnessOrthoAng);
    }

    public function getRestitutionOrthoAng():Float 
	{
        return cast(constraint,SliderConstraint).getRestitutionOrthoAng();
    }

    public function setRestitutionOrthoAng(restitutionOrthoAng:Float):Void
	{
        cast(constraint,SliderConstraint).setRestitutionOrthoAng(restitutionOrthoAng);
    }

    public function getDampingOrthoAng():Float
	{
        return cast(constraint,SliderConstraint).getDampingOrthoAng();
    }

    public function setDampingOrthoAng(dampingOrthoAng:Float):Void
	{
        cast(constraint,SliderConstraint).setDampingOrthoAng(dampingOrthoAng);
    }

    public function isPoweredLinMotor():Bool 
	{
        return cast(constraint,SliderConstraint).getPoweredLinMotor();
    }

    public function setPoweredLinMotor(poweredLinMotor:Bool):Void 
	{
        cast(constraint,SliderConstraint).setPoweredLinMotor(poweredLinMotor);
    }

    public function getTargetLinMotorVelocity():Float
	{
        return cast(constraint,SliderConstraint).getTargetLinMotorVelocity();
    }

    public function setTargetLinMotorVelocity(targetLinMotorVelocity:Float):Void
	{
        cast(constraint,SliderConstraint).setTargetLinMotorVelocity(targetLinMotorVelocity);
    }

    public function getMaxLinMotorForce():Float 
	{
        return cast(constraint,SliderConstraint).getMaxLinMotorForce();
    }

    public function setMaxLinMotorForce(maxLinMotorForce:Float):Void
	{
        cast(constraint,SliderConstraint).setMaxLinMotorForce(maxLinMotorForce);
    }

    public function isPoweredAngMotor():Bool
	{
        return cast(constraint,SliderConstraint).getPoweredAngMotor();
    }

    public function setPoweredAngMotor(poweredAngMotor:Bool):Void 
	{
        cast(constraint,SliderConstraint).setPoweredAngMotor(poweredAngMotor);
    }

    public function getTargetAngMotorVelocity():Float 
	{
        return cast(constraint,SliderConstraint).getTargetAngMotorVelocity();
    }

    public function setTargetAngMotorVelocity(targetAngMotorVelocity:Float):Void
	{
        cast(constraint,SliderConstraint).setTargetAngMotorVelocity(targetAngMotorVelocity);
    }

    public function getMaxAngMotorForce():Float
	{
        return cast(constraint,SliderConstraint).getMaxAngMotorForce();
    }

    public function setMaxAngMotorForce(maxAngMotorForce:Float):Void
	{
        cast(constraint,SliderConstraint).setMaxAngMotorForce(maxAngMotorForce);
    }
	
    private function createJoint():Void
	{
        var transA:Transform = new Transform();
		transA.fromMatrix3f(rotA);
        transA.origin.copyFrom(pivotA);
        transA.basis.copyFrom(rotA);

        var transB:Transform = new Transform();
		transB.fromMatrix3f(rotB);
        transB.origin.copyFrom(pivotB);
        transB.basis.copyFrom(rotB);

        constraint = new SliderConstraint();
		cast(constraint,SliderConstraint).init2(nodeA.getObjectId(), nodeB.getObjectId(), transA, transB, useLinearReferenceFrameA);
    }
}
