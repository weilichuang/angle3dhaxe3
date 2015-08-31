package com.bulletphysics.dynamics.vehicle;
import com.bulletphysics.linearmath.Transform;
import com.vecmath.Vector3f;

/**
 * WheelInfo contains information per wheel about friction and suspension.
 * @author weilichuang
 */
class WheelInfo
{

	//protected final BulletStack stack = BulletStack.get();

    public var raycastInfo:RaycastInfo = new RaycastInfo();

    public var worldTransform:Transform = new Transform();

    public var chassisConnectionPointCS:Vector3f = new Vector3f(); // const
    public var wheelDirectionCS:Vector3f = new Vector3f(); // const
    public var wheelAxleCS:Vector3f = new Vector3f(); // const or modified by steering
    public var suspensionRestLength1:Float; // const
    public var maxSuspensionTravelCm:Float;
	public var maxSuspensionForce:Float;
    public var wheelsRadius:Float; // const
    public var suspensionStiffness:Float; // const
    public var wheelsDampingCompression:Float; // const
    public var wheelsDampingRelaxation:Float; // const
    public var frictionSlip:Float;
    public var steering:Float;
    public var rotation:Float;
    public var deltaRotation:Float;
    public var rollInfluence:Float;

    public var engineForce:Float;

    public var brake:Float;

    public var bIsFrontWheel:Bool;

    public var clientInfo:Dynamic; // can be used to store pointer to sync transforms...

    public var clippedInvContactDotSuspension:Float = 0;
    public var suspensionRelativeVelocity:Float = 0;
    // calculated by suspension
    public var wheelsSuspensionForce:Float = 0;
    public var skidInfo:Float = 0;

    public function new(ci:WheelInfoConstructionInfo)
	{
        suspensionRestLength1 = ci.suspensionRestLength;
        maxSuspensionTravelCm = ci.maxSuspensionTravelCm;
		maxSuspensionForce = ci.maxSuspensionForce;

        wheelsRadius = ci.wheelRadius;
        suspensionStiffness = ci.suspensionStiffness;
        wheelsDampingCompression = ci.wheelsDampingCompression;
        wheelsDampingRelaxation = ci.wheelsDampingRelaxation;
        chassisConnectionPointCS.copyFrom(ci.chassisConnectionCS);
        wheelDirectionCS.copyFrom(ci.wheelDirectionCS);
        wheelAxleCS.copyFrom(ci.wheelAxleCS);
        frictionSlip = ci.frictionSlip;
        steering = 0;
        engineForce = 0;
        rotation = 0;
        deltaRotation = 0;
        brake = 0;
        rollInfluence = 0.1;
        bIsFrontWheel = ci.bIsFrontWheel;
    }

    public function getSuspensionRestLength():Float
	{
        return suspensionRestLength1;
    }

    public function updateWheel(chassis:RigidBody, raycastInfo:RaycastInfo):Void
	{
        if (raycastInfo.isInContact) 
		{
            var project:Float = raycastInfo.contactNormalWS.dot(raycastInfo.wheelDirectionWS);
            var chassis_velocity_at_contactPoint:Vector3f = new Vector3f();
            var relpos:Vector3f = new Vector3f();
            relpos.sub2(raycastInfo.contactPointWS, chassis.getCenterOfMassPosition());
            chassis.getVelocityInLocalPoint(relpos, chassis_velocity_at_contactPoint);
            var projVel:Float = raycastInfo.contactNormalWS.dot(chassis_velocity_at_contactPoint);
            if (project >= -0.1)
			{
                suspensionRelativeVelocity = 0;
                clippedInvContactDotSuspension = 1 / 0.1;
            }
			else
			{
                var inv:Float = -1 / project;
                suspensionRelativeVelocity = projVel * inv;
                clippedInvContactDotSuspension = inv;
            }
        } 
		else
		{
            // Not in contact : position wheel in a nice (rest length) position
            raycastInfo.suspensionLength = getSuspensionRestLength();
            suspensionRelativeVelocity = 0;
            raycastInfo.contactNormalWS.negateBy(raycastInfo.wheelDirectionWS);
            clippedInvContactDotSuspension = 1;
        }
    }
}

class RaycastInfo
{
	// set by raycaster
	public var contactNormalWS:Vector3f = new Vector3f(); // contactnormal
	public var contactPointWS:Vector3f = new Vector3f(); // raycast hitpoint
	public var suspensionLength:Float;
	public var hardPointWS:Vector3f = new Vector3f(); // raycast starting point
	public var wheelDirectionWS:Vector3f = new Vector3f(); // direction in worldspace
	public var wheelAxleWS:Vector3f = new Vector3f(); // axle in worldspace
	public var isInContact:Bool;
	public var groundObject:Dynamic; // could be general void* ptr
	
	public function new()
	{
		
	}
}