package com.bulletphysics.dynamics.vehicle;

import com.bulletphysics.dynamics.constraintsolver.ContactConstraint;
import com.bulletphysics.dynamics.constraintsolver.TypedConstraint;
import com.bulletphysics.dynamics.constraintsolver.TypedConstraintType;
import com.bulletphysics.linearmath.MiscUtil;
import com.bulletphysics.linearmath.QuaternionUtil;
import com.bulletphysics.linearmath.Transform;
import de.polygonal.ds.error.Assert;
import com.bulletphysics.util.FloatArrayList;
import com.bulletphysics.util.ObjectArrayList;
import de.polygonal.core.math.Mathematics;
import org.angle3d.math.Matrix3f;
import com.bulletphysics.linearmath.MatrixUtil;
import com.vecmath.Quat4f;
import org.angle3d.math.Vector3f;

/**
 * Raycast vehicle, very special constraint that turn a rigidbody into a vehicle.
 * @author weilichuang
 */
class RaycastVehicle extends TypedConstraint
{
    private static var s_fixedObject:RigidBody;
	
	static function __init__():Void
	{
		s_fixedObject = new RigidBody();
		s_fixedObject.init(0, null, null);
	}
	
    private static inline var sideFrictionStiffness2:Float = 1.0;

    private var forwardWS:ObjectArrayList<Vector3f> = new ObjectArrayList<Vector3f>();
    private var axle:ObjectArrayList<Vector3f> = new ObjectArrayList<Vector3f>();
    private var forwardImpulse:FloatArrayList = new FloatArrayList();
    private var sideImpulse:FloatArrayList = new FloatArrayList();

    private var vehicleRaycaster:VehicleRaycaster;
    private var currentVehicleSpeedKmHour:Float;

    private var chassisBody:RigidBody;

    private var indexRightAxis:Int = 0;
    private var indexUpAxis:Int = 2;
    private var indexForwardAxis:Int = 1;

    public var wheelInfo:ObjectArrayList<WheelInfo> = new ObjectArrayList<WheelInfo>();

    // constructor to create a car from an existing rigidbody
    public function new(tuning:VehicleTuning, chassis:RigidBody, raycaster:VehicleRaycaster)
	{
        super(TypedConstraintType.VEHICLE_CONSTRAINT_TYPE);
        this.vehicleRaycaster = raycaster;
        this.chassisBody = chassis;
        defaultInit(tuning);
    }

    private function defaultInit(tuning:VehicleTuning):Void
	{
        currentVehicleSpeedKmHour = 0;
    }

    /**
     * Basically most of the code is general for 2 or 4 wheel vehicles, but some of it needs to be reviewed.
     */
    public function addWheel(connectionPointCS:Vector3f, wheelDirectionCS0:Vector3f, wheelAxleCS:Vector3f, suspensionRestLength:Float, wheelRadius:Float, tuning:VehicleTuning, isFrontWheel:Bool):WheelInfo
	{
        var ci:WheelInfoConstructionInfo = new WheelInfoConstructionInfo();

        ci.chassisConnectionCS.copyFrom(connectionPointCS);
        ci.wheelDirectionCS.copyFrom(wheelDirectionCS0);
        ci.wheelAxleCS.copyFrom(wheelAxleCS);
        ci.suspensionRestLength = suspensionRestLength;
        ci.wheelRadius = wheelRadius;
        ci.suspensionStiffness = tuning.suspensionStiffness;
        ci.wheelsDampingCompression = tuning.suspensionCompression;
        ci.wheelsDampingRelaxation = tuning.suspensionDamping;
        ci.frictionSlip = tuning.frictionSlip;
        ci.bIsFrontWheel = isFrontWheel;
        ci.maxSuspensionTravelCm = tuning.maxSuspensionTravelCm;

        wheelInfo.add(new WheelInfo(ci));

        var wheel:WheelInfo = wheelInfo.getQuick(getNumWheels() - 1);

        updateWheelTransformsWS(wheel, false);
        updateWheelTransform(getNumWheels() - 1, false);
        return wheel;
    }

    public function getWheelTransformWS(wheelIndex:Int, out:Transform):Transform
	{
		#if debug
        Assert.assert (wheelIndex < getNumWheels());
		#end
		
        var wheel:WheelInfo = wheelInfo.getQuick(wheelIndex);
        out.fromTransform(wheel.worldTransform);
        return out;
    }

    public function updateWheelTransform(wheelIndex:Int, interpolatedTransform:Bool = true):Void
	{
        var wheel:WheelInfo = wheelInfo.getQuick(wheelIndex);
        updateWheelTransformsWS(wheel, interpolatedTransform);
        var up:Vector3f = new Vector3f();
        up.negateBy(wheel.raycastInfo.wheelDirectionWS);
        var right:Vector3f = wheel.raycastInfo.wheelAxleWS;
		
        var fwd:Vector3f = new Vector3f();
        fwd.crossBy(up, right);
        fwd.normalizeLocal();
        // up = right.cross(fwd);
        // up.normalize();

        // rotate around steering over de wheelAxleWS
        var steering:Float = wheel.steering;

        var steeringOrn:Quat4f = new Quat4f();
        QuaternionUtil.setRotation(steeringOrn, up, steering); //wheel.m_steering);
        var steeringMat:Matrix3f = new Matrix3f();
        MatrixUtil.setRotation(steeringMat, steeringOrn);

        var rotatingOrn:Quat4f = new Quat4f();
        QuaternionUtil.setRotation(rotatingOrn, right, -wheel.rotation);
        var rotatingMat:Matrix3f = new Matrix3f();
        MatrixUtil.setRotation(rotatingMat, rotatingOrn);

        var basis2:Matrix3f = new Matrix3f();
        basis2.setRowXYZ(0, right.x, fwd.x, up.x);
        basis2.setRowXYZ(1, right.y, fwd.y, up.y);
        basis2.setRowXYZ(2, right.z, fwd.z, up.z);

        var wheelBasis:Matrix3f = wheel.worldTransform.basis;
        wheelBasis.multBy(steeringMat, rotatingMat);
        wheelBasis.multLocal(basis2);

        wheel.worldTransform.origin.scaleAddBy(wheel.raycastInfo.suspensionLength, wheel.raycastInfo.wheelDirectionWS, wheel.raycastInfo.hardPointWS);
    }

    public function resetSuspension():Void
	{
        for (i in 0...wheelInfo.size())
		{
            var wheel:WheelInfo = wheelInfo.getQuick(i);
            wheel.raycastInfo.suspensionLength = wheel.getSuspensionRestLength();
            wheel.suspensionRelativeVelocity = 0;

            wheel.raycastInfo.contactNormalWS.negateBy(wheel.raycastInfo.wheelDirectionWS);
            //wheel_info.setContactFriction(btScalar(0.0));
            wheel.clippedInvContactDotSuspension = 1;
        }
    }

    public function updateWheelTransformsWS(wheel:WheelInfo, interpolatedTransform:Bool = true):Void 
	{
        wheel.raycastInfo.isInContact = false;

        var chassisTrans:Transform = getChassisWorldTransform(new Transform());
        if (interpolatedTransform && (getRigidBody().getMotionState() != null))
		{
            getRigidBody().getMotionState().getWorldTransform(chassisTrans);
        }

        wheel.raycastInfo.hardPointWS.copyFrom(wheel.chassisConnectionPointCS);
        chassisTrans.transform(wheel.raycastInfo.hardPointWS);

        wheel.raycastInfo.wheelDirectionWS.copyFrom(wheel.wheelDirectionCS);
        chassisTrans.basis.multVecLocal(wheel.raycastInfo.wheelDirectionWS);

        wheel.raycastInfo.wheelAxleWS.copyFrom(wheel.wheelAxleCS);
        chassisTrans.basis.multVecLocal(wheel.raycastInfo.wheelAxleWS);
    }

    public function rayCast(wheel:WheelInfo):Float
	{
        updateWheelTransformsWS(wheel, false);

        var depth:Float = -1;

        var raylen:Float = wheel.getSuspensionRestLength() + wheel.wheelsRadius;

        var rayvector:Vector3f = new Vector3f();
        rayvector.scaleBy(raylen, wheel.raycastInfo.wheelDirectionWS);
        var source:Vector3f = wheel.raycastInfo.hardPointWS;
        wheel.raycastInfo.contactPointWS.addBy(source, rayvector);
        var target:Vector3f = wheel.raycastInfo.contactPointWS;

        var param:Float = 0;

        var rayResults:VehicleRaycasterResult = new VehicleRaycasterResult();

		#if debug
        Assert.assert (vehicleRaycaster != null);
		#end

        var object:Dynamic = vehicleRaycaster.castRay(source, target, rayResults);

        wheel.raycastInfo.groundObject = null;

        if (object != null)
		{
            param = rayResults.distFraction;
            depth = raylen * rayResults.distFraction;
            wheel.raycastInfo.contactNormalWS.copyFrom(rayResults.hitNormalInWorld);
            wheel.raycastInfo.isInContact = true;

            wheel.raycastInfo.groundObject = s_fixedObject; // todo for driving on dynamic/movable objects!;
            //wheel.m_raycastInfo.m_groundObject = object;

            var hitDistance:Float = param * raylen;
            wheel.raycastInfo.suspensionLength = hitDistance - wheel.wheelsRadius;
            // clamp on max suspension travel

            var minSuspensionLength:Float = wheel.getSuspensionRestLength() - wheel.maxSuspensionTravelCm * 0.01;
            var maxSuspensionLength:Float = wheel.getSuspensionRestLength() + wheel.maxSuspensionTravelCm * 0.01;
            if (wheel.raycastInfo.suspensionLength < minSuspensionLength) 
			{
                wheel.raycastInfo.suspensionLength = minSuspensionLength;
            }
            if (wheel.raycastInfo.suspensionLength > maxSuspensionLength)
			{
                wheel.raycastInfo.suspensionLength = maxSuspensionLength;
            }

            wheel.raycastInfo.contactPointWS.copyFrom(rayResults.hitPointInWorld);

            var denominator:Float = wheel.raycastInfo.contactNormalWS.dot(wheel.raycastInfo.wheelDirectionWS);

            var chassis_velocity_at_contactPoint:Vector3f = new Vector3f();
            var relpos:Vector3f = new Vector3f();
            relpos.subtractBy(wheel.raycastInfo.contactPointWS, getRigidBody().getCenterOfMassPosition());

            getRigidBody().getVelocityInLocalPoint(relpos, chassis_velocity_at_contactPoint);

            var projVel:Float = wheel.raycastInfo.contactNormalWS.dot(chassis_velocity_at_contactPoint);

            if (denominator >= -0.1)
			{
                wheel.suspensionRelativeVelocity = 0;
                wheel.clippedInvContactDotSuspension = 1 / 0.1;
            } 
			else
			{
                var inv:Float = -1 / denominator;
                wheel.suspensionRelativeVelocity = projVel * inv;
                wheel.clippedInvContactDotSuspension = inv;
            }

        } 
		else 
		{
            // put wheel info as in rest position
            wheel.raycastInfo.suspensionLength = wheel.getSuspensionRestLength();
            wheel.suspensionRelativeVelocity = 0;
            wheel.raycastInfo.contactNormalWS.negateBy(wheel.raycastInfo.wheelDirectionWS);
            wheel.clippedInvContactDotSuspension = 1;
        }

        return depth;
    }

    public function getChassisWorldTransform(out:Transform):Transform
	{
        /*
        if (getRigidBody()->getMotionState())
		{
			btTransform chassisWorldTrans;
			getRigidBody()->getMotionState()->getWorldTransform(chassisWorldTrans);
			return chassisWorldTrans;
		}
		*/

        return getRigidBody().getCenterOfMassTransformTo(out);
    }

    public function updateVehicle(step:Float):Void
	{
        for (i in 0...getNumWheels())
		{
            updateWheelTransform(i, false);
        }

        var tmp:Vector3f = new Vector3f();

        currentVehicleSpeedKmHour = 3.6 * getRigidBody().getLinearVelocity(tmp).length;

        var chassisTrans:Transform = getChassisWorldTransform(new Transform());

        var forwardW:Vector3f = new Vector3f();
        forwardW.setTo(
                chassisTrans.basis.getElement(0, indexForwardAxis),
                chassisTrans.basis.getElement(1, indexForwardAxis),
                chassisTrans.basis.getElement(2, indexForwardAxis));

        if (forwardW.dot(getRigidBody().getLinearVelocity(tmp)) < 0)
		{
            currentVehicleSpeedKmHour *= -1;
        }

        //
        // simulate suspension
        //

        for (i in 0...wheelInfo.size())
		{
            rayCast(wheelInfo.getQuick(i));
        }

        updateSuspension(step);

        for (i in 0...wheelInfo.size()) 
		{
            // apply suspension force
            var wheel:WheelInfo = wheelInfo.getQuick(i);

            var suspensionForce:Float = wheel.wheelsSuspensionForce;
            if (suspensionForce > wheel.maxSuspensionForce)
			{
                suspensionForce = wheel.maxSuspensionForce;
            }
            var impulse:Vector3f = new Vector3f();
            impulse.scaleBy(suspensionForce * step, wheel.raycastInfo.contactNormalWS);
            var relpos:Vector3f = new Vector3f();
            relpos.subtractBy(wheel.raycastInfo.contactPointWS, getRigidBody().getCenterOfMassPosition());

            getRigidBody().applyImpulse(impulse, relpos);
        }

        updateFriction(step);

        for (i in 0...wheelInfo.size())
		{
            var wheel:WheelInfo = wheelInfo.getQuick(i);
            var relpos:Vector3f = new Vector3f();
            relpos.subtractBy(wheel.raycastInfo.hardPointWS, getRigidBody().getCenterOfMassPosition());
            var vel:Vector3f = getRigidBody().getVelocityInLocalPoint(relpos, new Vector3f());

            if (wheel.raycastInfo.isInContact)
			{
                var chassisWorldTransform:Transform = getChassisWorldTransform(new Transform());

                var fwd:Vector3f = new Vector3f();
                fwd.setTo(
                        chassisWorldTransform.basis.getElement(0, indexForwardAxis),
                        chassisWorldTransform.basis.getElement(1, indexForwardAxis),
                        chassisWorldTransform.basis.getElement(2, indexForwardAxis));

                var proj:Float = fwd.dot(wheel.raycastInfo.contactNormalWS);
                tmp.scaleBy(proj, wheel.raycastInfo.contactNormalWS);
                fwd.subtractLocal(tmp);

                var proj2:Float = fwd.dot(vel);

                wheel.deltaRotation = (proj2 * step) / (wheel.wheelsRadius);
                wheel.rotation += wheel.deltaRotation;

            }
			else 
			{
                wheel.rotation += wheel.deltaRotation;
            }

            wheel.deltaRotation *= 0.99; // damping of rotation when not in contact
        }
    }

    public function setSteeringValue(steering:Float, wheel:Int):Void
	{
        #if debug
        Assert.assert ((wheel >= 0) && (wheel < getNumWheels()));
		#end

        var wheel_info:WheelInfo = getWheelInfo(wheel);
        wheel_info.steering = steering;
    }

    public function getSteeringValue(wheel:Int):Float
	{
        return getWheelInfo(wheel).steering;
    }

    public function applyEngineForce(force:Float, wheel:Int):Void
	{
		#if debug
        Assert.assert (wheel >= 0 && wheel < getNumWheels());
		#end
		
        var wheel_info:WheelInfo = getWheelInfo(wheel);
        wheel_info.engineForce = force;
    }

    public function getWheelInfo(index:Int):WheelInfo
	{
		#if debug
        Assert.assert ((index >= 0) && (index < getNumWheels()));
		#end

        return wheelInfo.getQuick(index);
    }

    public function setBrake(brake:Float, wheelIndex:Int):Void
	{
		#if debug
        Assert.assert ((wheelIndex >= 0) && (wheelIndex < getNumWheels()));
		#end
		
        getWheelInfo(wheelIndex).brake = brake;
    }

    public function updateSuspension(deltaTime:Float):Void
	{
        var chassisMass:Float = 1 / chassisBody.getInvMass();

        for (w_it in 0...getNumWheels())
		{
            var wheel_info:WheelInfo = wheelInfo.getQuick(w_it);

            if (wheel_info.raycastInfo.isInContact)
			{
                var force:Float;
                //	Spring
                {
                    var susp_length:Float = wheel_info.getSuspensionRestLength();
                    var current_length:Float = wheel_info.raycastInfo.suspensionLength;

                    var length_diff:Float = (susp_length - current_length);

                    force = wheel_info.suspensionStiffness * length_diff * wheel_info.clippedInvContactDotSuspension;
                }

                // Damper
                {
                    var projected_rel_vel:Float = wheel_info.suspensionRelativeVelocity;
                    {
                        var susp_damping:Float;
                        if (projected_rel_vel < 0)
						{
                            susp_damping = wheel_info.wheelsDampingCompression;
                        } 
						else
						{
                            susp_damping = wheel_info.wheelsDampingRelaxation;
                        }
                        force -= susp_damping * projected_rel_vel;
                    }
                }

                // RESULT
                wheel_info.wheelsSuspensionForce = force * chassisMass;
                if (wheel_info.wheelsSuspensionForce < 0)
				{
                    wheel_info.wheelsSuspensionForce = 0;
                }
            } 
			else
			{
                wheel_info.wheelsSuspensionForce = 0;
            }
        }
    }

    private function calcRollingFriction(contactPoint:WheelContactPoint):Float
	{
        var tmp:Vector3f = new Vector3f();

        var j1:Float = 0;

        var contactPosWorld:Vector3f = contactPoint.frictionPositionWorld;

        var rel_pos1:Vector3f = new Vector3f();
        rel_pos1.subtractBy(contactPosWorld, contactPoint.body0.getCenterOfMassPosition());
        var rel_pos2:Vector3f = new Vector3f();
        rel_pos2.subtractBy(contactPosWorld, contactPoint.body1.getCenterOfMassPosition());

        var maxImpulse:Float = contactPoint.maxImpulse;

        var vel1:Vector3f = contactPoint.body0.getVelocityInLocalPoint(rel_pos1, new Vector3f());
        var vel2:Vector3f = contactPoint.body1.getVelocityInLocalPoint(rel_pos2, new Vector3f());
        var vel:Vector3f = new Vector3f();
        vel.subtractBy(vel1, vel2);

        var vrel:Float = contactPoint.frictionDirectionWorld.dot(vel);

        // calculate j that moves us to zero relative velocity
        j1 = -vrel * contactPoint.jacDiagABInv;
        j1 = Math.min(j1, maxImpulse);
        j1 = Math.max(j1, -maxImpulse);

        return j1;
    }

    public function updateFriction(timeStep:Float):Void
	{
        // calculate the impulse, so that the wheels don't move sidewards
        var numWheel:Int = getNumWheels();
        if (numWheel == 0)
		{
            return;
        }

        forwardWS.resize(numWheel, Vector3f);
        axle.resize(numWheel, Vector3f);
        MiscUtil.resizeFloatArrayList(forwardImpulse, numWheel, 0);
        MiscUtil.resizeFloatArrayList(sideImpulse, numWheel, 0);

        var tmp:Vector3f = new Vector3f();

        // collapse all those loops into one!
        for (i in 0...numWheel) 
		{
            sideImpulse.set(i, 0);
            forwardImpulse.set(i, 0);
        }

        {
            var wheelTrans:Transform = new Transform();
            for (i in 0...numWheel)
			{

                var wheel_info:WheelInfo = wheelInfo.getQuick(i);

                var groundObject:RigidBody = cast wheel_info.raycastInfo.groundObject;

                if (groundObject != null)
				{
                    getWheelTransformWS(i, wheelTrans);

                    var wheelBasis0:Matrix3f = wheelTrans.basis.clone();
                    axle.getQuick(i).setTo(
                            wheelBasis0.getElement(0, indexRightAxis),
                            wheelBasis0.getElement(1, indexRightAxis),
                            wheelBasis0.getElement(2, indexRightAxis));

                    var surfNormalWS:Vector3f = wheel_info.raycastInfo.contactNormalWS;
                    var proj:Float = axle.getQuick(i).dot(surfNormalWS);
                    tmp.scaleBy(proj, surfNormalWS);
                    axle.getQuick(i).subtractLocal(tmp);
                    axle.getQuick(i).normalizeLocal();

                    forwardWS.getQuick(i).crossBy(surfNormalWS, axle.getQuick(i));
                    forwardWS.getQuick(i).normalizeLocal();

                    var floatPtr:Array<Float> = [];
                    ContactConstraint.resolveSingleBilateral(chassisBody, wheel_info.raycastInfo.contactPointWS,
                            groundObject, wheel_info.raycastInfo.contactPointWS,
                            0, axle.getQuick(i), floatPtr, timeStep);
                    sideImpulse.set(i, floatPtr[0]);

                    sideImpulse.set(i, sideImpulse.get(i) * sideFrictionStiffness2);
                }
            }
        }

        var sideFactor:Float = 1;
        var fwdFactor:Float = 0.5;

        var sliding:Bool = false;
        {
            for (wheel in 0...numWheel) 
			{
                var wheel_info:WheelInfo = wheelInfo.getQuick(wheel);
                var groundObject:RigidBody = cast wheel_info.raycastInfo.groundObject;

                var rollingFriction:Float = 0;

                if (groundObject != null)
				{
                    if (wheel_info.engineForce != 0)
					{
                        rollingFriction = wheel_info.engineForce * timeStep;
                    } 
					else
					{
                        var defaultRollingFrictionImpulse:Float = 0;
                        var maxImpulse:Float = wheel_info.brake != 0 ? wheel_info.brake : defaultRollingFrictionImpulse;
                        var contactPt:WheelContactPoint = new WheelContactPoint(chassisBody, groundObject, wheel_info.raycastInfo.contactPointWS, forwardWS.getQuick(wheel), maxImpulse);
                        rollingFriction = calcRollingFriction(contactPt);
                    }
                }

                // switch between active rolling (throttle), braking and non-active rolling friction (no throttle/break)

                forwardImpulse.set(wheel, 0);
                wheelInfo.getQuick(wheel).skidInfo = 1;

                if (groundObject != null)
				{
                    wheelInfo.getQuick(wheel).skidInfo = 1;

                    var maximp:Float = wheel_info.wheelsSuspensionForce * timeStep * wheel_info.frictionSlip;
                    var maximpSide:Float = maximp;

                    var maximpSquared:Float = maximp * maximpSide;

                    forwardImpulse.set(wheel, rollingFriction); //wheelInfo.m_engineForce* timeStep;

                    var x:Float = (forwardImpulse.get(wheel)) * fwdFactor;
                    var y:Float = (sideImpulse.get(wheel)) * sideFactor;

                    var impulseSquared:Float = (x * x + y * y);

                    if (impulseSquared > maximpSquared)
					{
                        sliding = true;

                        var factor:Float = maximp / Math.sqrt(impulseSquared);

                        wheelInfo.getQuick(wheel).skidInfo *= factor;
                    }
                }

            }
        }

        if (sliding)
		{
            for (wheel in 0...numWheel) 
			{
                if (sideImpulse.get(wheel) != 0)
				{
                    if (wheelInfo.getQuick(wheel).skidInfo < 1)
					{
                        forwardImpulse.set(wheel, forwardImpulse.get(wheel) * wheelInfo.getQuick(wheel).skidInfo);
                        sideImpulse.set(wheel, sideImpulse.get(wheel) * wheelInfo.getQuick(wheel).skidInfo);
                    }
                }
            }
        }

        // apply the impulses
        {
            for (wheel in 0...numWheel)
			{
                var wheel_info:WheelInfo = wheelInfo.getQuick(wheel);

                var rel_pos:Vector3f = new Vector3f();
                rel_pos.subtractBy(wheel_info.raycastInfo.contactPointWS, chassisBody.getCenterOfMassPosition());

                if (forwardImpulse.get(wheel) != 0)
				{
                    tmp.scaleBy(forwardImpulse.get(wheel), forwardWS.getQuick(wheel));
                    chassisBody.applyImpulse(tmp, rel_pos);
                }
                if (sideImpulse.get(wheel) != 0)
				{
                    var groundObject:RigidBody = cast wheelInfo.getQuick(wheel).raycastInfo.groundObject;

                    var rel_pos2:Vector3f = new Vector3f();
                    rel_pos2.subtractBy(wheel_info.raycastInfo.contactPointWS, groundObject.getCenterOfMassPosition());

                    var sideImp:Vector3f = new Vector3f();
                    sideImp.scaleBy(sideImpulse.get(wheel), axle.getQuick(wheel));

                    rel_pos.z *= wheel_info.rollInfluence;
                    chassisBody.applyImpulse(sideImp, rel_pos);

                    // apply friction impulse on the ground
                    tmp.negateBy(sideImp);
                    groundObject.applyImpulse(tmp, rel_pos2);
                }
            }
        }
    }
	
	override public function buildJacobian():Void
	{
		
	}
	
	override public function solveConstraint(timeStep:Float):Void
	{
		
	}

    public inline function getNumWheels():Int
	{
        return wheelInfo.size();
    }

    //public function setPitchControl(pitch:Float):Void
	//{
        //this.pitchControl = pitch;
    //}

    public function getRigidBody():RigidBody
	{
        return chassisBody;
    }

    public function getRightAxis():Int 
	{
        return indexRightAxis;
    }

    public function getUpAxis():Int 
	{
        return indexUpAxis;
    }

    public function getForwardAxis():Int
	{
        return indexForwardAxis;
    }

    /**
     * Worldspace forward vector.
     */
    public function getForwardVector(out:Vector3f):Vector3f
	{
        var chassisTrans:Transform = getChassisWorldTransform(new Transform());

        out.setTo(
                chassisTrans.basis.getElement(0, indexForwardAxis),
                chassisTrans.basis.getElement(1, indexForwardAxis),
                chassisTrans.basis.getElement(2, indexForwardAxis));

        return out;
    }

    /**
     * Velocity of vehicle (positive if velocity vector has same direction as foward vector).
     */
    public function getCurrentSpeedKmHour():Float
	{
        return currentVehicleSpeedKmHour;
    }

    public function setCoordinateSystem( rightIndex:Int, upIndex:Int, forwardIndex:Int):Void 
	{
        this.indexRightAxis = rightIndex;
        this.indexUpAxis = upIndex;
        this.indexForwardAxis = forwardIndex;
    }
}

class WheelContactPoint 
{
	public var body0:RigidBody;
	public var body1:RigidBody;
	public var frictionPositionWorld:Vector3f = new Vector3f();
	public var frictionDirectionWorld:Vector3f = new Vector3f();
	public var jacDiagABInv:Float;
	public var maxImpulse:Float;

	public function new(body0:RigidBody, body1:RigidBody, frictionPosWorld:Vector3f, frictionDirectionWorld:Vector3f, maxImpulse:Float)
	{
		this.body0 = body0;
		this.body1 = body1;
		this.frictionPositionWorld.copyFrom(frictionPosWorld);
		this.frictionDirectionWorld.copyFrom(frictionDirectionWorld);
		this.maxImpulse = maxImpulse;

		var denom0:Float = body0.computeImpulseDenominator(frictionPosWorld, frictionDirectionWorld);
		var denom1:Float = body1.computeImpulseDenominator(frictionPosWorld, frictionDirectionWorld);
		var relaxation:Float = 1;
		jacDiagABInv = relaxation / (denom0 + denom1);
	}
}