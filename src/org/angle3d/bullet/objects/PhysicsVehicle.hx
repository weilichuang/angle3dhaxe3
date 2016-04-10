package org.angle3d.bullet.objects;

import com.bulletphysics.collision.dispatch.CollisionObject;
import com.bulletphysics.dynamics.vehicle.DefaultVehicleRaycaster;
import com.bulletphysics.dynamics.vehicle.RaycastVehicle;
import com.bulletphysics.dynamics.vehicle.VehicleRaycaster;
import com.bulletphysics.dynamics.vehicle.VehicleTuning;
import com.bulletphysics.dynamics.vehicle.WheelInfo;
import org.angle3d.bullet.collision.shapes.CollisionShape;
import org.angle3d.bullet.util.Converter;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Spatial;

/**
 * ...
 
 */
class PhysicsVehicle extends PhysicsRigidBody
{
	private var vehicle:RaycastVehicle;
    private var tuning:VehicleTuning;
    private var rayCaster:VehicleRaycaster;
    private var wheels:Array<VehicleWheel> = new Array<VehicleWheel>();
    private var physicsSpace:PhysicsSpace;

	public function new(shape:CollisionShape, mass:Float = 1.0) 
	{
		super(shape, mass);
		
	}

    /**
     * used internally
     */
    public function updateWheels():Void
	{
        if (vehicle != null)
		{
            for (i in 0...wheels.length)
			{
                vehicle.updateWheelTransform(i, true);
                wheels[i].updatePhysicsState();
            }
        }
    }

    /**
     * used internally
     */
    public function applyWheelTransforms():Void
	{
        if (wheels != null) 
		{
            for (i in 0...wheels.length)
			{
                wheels[i].applyWheelTransform(i);
            }
        }
    }

    override private function postRebuild():Void
	{
        super.postRebuild();
        if (tuning == null) 
		{
            tuning = new VehicleTuning();
        }
        rBody.setActivationState(CollisionObject.DISABLE_DEACTIVATION);
        motionState.setVehicle(this);
        if (physicsSpace != null) 
		{
            createVehicle(physicsSpace);
        }
    }

    /**
     * Used internally, creates the actual vehicle constraint when vehicle is added to phyicsspace
     */
    public function createVehicle(space:PhysicsSpace):Void
	{
        physicsSpace = space;
        if (space == null)
		{
            return;
        }
        rayCaster = new DefaultVehicleRaycaster(space.getDynamicsWorld());
        vehicle = new RaycastVehicle(tuning, rBody, rayCaster);
        vehicle.setCoordinateSystem(0, 1, 2);
        for (wheel in wheels)
		{
            wheel.setWheelInfo(vehicle.addWheel(wheel.getLocation(), wheel.getDirection(), wheel.getAxle(),
                    wheel.getRestLength(), wheel.getRadius(), tuning, wheel.isFrontWheel()));
        }
    }

    /**
     * Add a wheel to this vehicle
     * @param spat the wheel Geometry
     * @param connectionPoint The starting point of the ray, where the suspension connects to the chassis (chassis space)
     * @param direction the direction of the wheel (should be -Y / 0,-1,0 for a normal car)
     * @param axle The axis of the wheel, pointing right in vehicle direction (should be -X / -1,0,0 for a normal car)
     * @param suspensionRestLength The current length of the suspension (metres)
     * @param wheelRadius the wheel radius
     * @param isFrontWheel sets if this wheel is a front wheel (steering)
     * @return the PhysicsVehicleWheel object to get/set infos on the wheel
     */
    public function addWheel(connectionPoint:Vector3f, 
							direction:Vector3f, 
							axle:Vector3f, 
							suspensionRestLength:Float,
							wheelRadius:Float,
							isFrontWheel:Bool, 
							spat:Spatial = null):VehicleWheel
	{
        var wheel:VehicleWheel = null;
        if (spat == null)
		{
            wheel = new VehicleWheel(connectionPoint, direction, axle, suspensionRestLength, wheelRadius, isFrontWheel);
        } 
		else 
		{
            wheel = new VehicleWheel(connectionPoint, direction, axle, suspensionRestLength, wheelRadius, isFrontWheel,spat);
        }
		
        if (vehicle != null)
		{
            var info:WheelInfo = vehicle.addWheel(connectionPoint, direction, axle,
                    suspensionRestLength, wheelRadius, tuning, isFrontWheel);
            wheel.setWheelInfo(info);
        }
        wheel.setFrictionSlip(tuning.frictionSlip);
        wheel.setMaxSuspensionTravelCm(tuning.maxSuspensionTravelCm);
        wheel.setSuspensionStiffness(tuning.suspensionStiffness);
        wheel.setWheelsDampingCompression(tuning.suspensionCompression);
        wheel.setWheelsDampingRelaxation(tuning.suspensionDamping);
        wheel.setMaxSuspensionForce(tuning.maxSuspensionForce);
        wheels.push(wheel);
        return wheel;
    }

    /**
     * This rebuilds the vehicle as there is no way in bullet to remove a wheel.
     * @param wheel
     */
    public function removeWheel(wheel:Int):Void
	{
        wheels.splice(wheel, 1);
        rebuildRigidBody();
    }

    /**
     * You can get access to the single wheels via this method.
     * @param wheel the wheel index
     * @return the WheelInfo of the selected wheel
     */
    public function getWheel(wheel:Int):VehicleWheel 
	{
        return wheels[wheel];
    }

    public function getNumWheels():Int 
	{
        return wheels.length;
    }

    /**
     * @return the frictionSlip
     */
    public function getFrictionSlip():Float
	{
        return tuning.frictionSlip;
    }

    /**
     * Use before adding wheels, this is the default used when adding wheels.
     * After adding the wheel, use direct wheel access.<br>
     * The coefficient of friction between the tyre and the ground.
     * Should be about 0.8 for realistic cars, but can increased for better handling.
     * Set large (10000.0) for kart racers
     * @param frictionSlip the frictionSlip to set
     */
    public function setFrictionSlip(frictionSlip:Float):Void
	{
        tuning.frictionSlip = frictionSlip;
    }

    /**
     * The coefficient of friction between the tyre and the ground.
     * Should be about 0.8 for realistic cars, but can increased for better handling.
     * Set large (10000.0) for kart racers
     * @param wheel
     * @param frictionSlip
     */
    public function setFrictionSlipAt(wheel:Int, frictionSlip:Float):Void
	{
        wheels[wheel].setFrictionSlip(frictionSlip);
    }

    /**
     * Reduces the rolling torque applied from the wheels that cause the vehicle to roll over.
     * This is a bit of a hack, but it's quite effective. 0.0 = no roll, 1.0 = physical behaviour.
     * If m_frictionSlip is too high, you'll need to reduce this to stop the vehicle rolling over.
     * You should also try lowering the vehicle's centre of mass
     */
    public function setRollInfluence(wheel:Int, rollInfluence:Float):Void
	{
        wheels[wheel].setRollInfluence(rollInfluence);
    }

    /**
     * @return the maxSuspensionTravelCm
     */
    public function getMaxSuspensionTravelCm():Float 
	{
        return tuning.maxSuspensionTravelCm;
    }

    /**
     * Use before adding wheels, this is the default used when adding wheels.
     * After adding the wheel, use direct wheel access.<br>
     * The maximum distance the suspension can be compressed (centimetres)
     * @param maxSuspensionTravelCm the maxSuspensionTravelCm to set
     */
    public function setMaxSuspensionTravelCm(maxSuspensionTravelCm:Float):Void
	{
        tuning.maxSuspensionTravelCm = maxSuspensionTravelCm;
    }

    /**
     * The maximum distance the suspension can be compressed (centimetres)
     * @param wheel
     * @param maxSuspensionTravelCm
     */
    public function setMaxSuspensionTravelCmAt(wheel:Int, maxSuspensionTravelCm:Float):Void
	{
        wheels[wheel].setMaxSuspensionTravelCm(maxSuspensionTravelCm);
    }

    public function getMaxSuspensionForce():Float 
	{
        return tuning.maxSuspensionForce;
    }

    /**
     * This vaue caps the maximum suspension force, raise this above the default 6000 if your suspension cannot
     * handle the weight of your vehcile.
     * @param maxSuspensionForce
     */
    public function setMaxSuspensionForce(maxSuspensionForce:Float):Void
	{
        tuning.maxSuspensionForce = maxSuspensionForce;
    }

    /**
     * This vaue caps the maximum suspension force, raise this above the default 6000 if your suspension cannot
     * handle the weight of your vehcile.
     * @param wheel
     * @param maxSuspensionForce
     */
    public function setMaxSuspensionForceAt(wheel:Int, maxSuspensionForce:Float):Void
	{
        wheels[wheel].setMaxSuspensionForce(maxSuspensionForce);
    }

    /**
     * @return the suspensionCompression
     */
    public function getSuspensionCompression():Float
	{
        return tuning.suspensionCompression;
    }

    /**
     * Use before adding wheels, this is the default used when adding wheels.
     * After adding the wheel, use direct wheel access.<br>
     * The damping coefficient for when the suspension is compressed.
     * Set to k * 2.0 * FastMath.sqrt(m_suspensionStiffness) so k is proportional to critical damping.<br>
     * k = 0.0 undamped & bouncy, k = 1.0 critical damping<br>
     * 0.1 to 0.3 are good values
     * @param suspensionCompression the suspensionCompression to set
     */
    public function setSuspensionCompression(suspensionCompression:Float):Void
	{
        tuning.suspensionCompression = suspensionCompression;
    }

    /**
     * The damping coefficient for when the suspension is compressed.
     * Set to k * 2.0 * FastMath.sqrt(m_suspensionStiffness) so k is proportional to critical damping.<br>
     * k = 0.0 undamped & bouncy, k = 1.0 critical damping<br>
     * 0.1 to 0.3 are good values
     * @param wheel
     * @param suspensionCompression
     */
    public function setSuspensionCompressionAt(wheel:Int, suspensionCompression:Float):Void
	{
        wheels[wheel].setWheelsDampingCompression(suspensionCompression);
    }

    /**
     * @return the suspensionDamping
     */
    public function getSuspensionDamping():Float 
	{
        return tuning.suspensionDamping;
    }

    /**
     * Use before adding wheels, this is the default used when adding wheels.
     * After adding the wheel, use direct wheel access.<br>
     * The damping coefficient for when the suspension is expanding.
     * See the comments for setSuspensionCompression for how to set k.
     * @param suspensionDamping the suspensionDamping to set
     */
    public function setSuspensionDamping(suspensionDamping:Float):Void
	{
        tuning.suspensionDamping = suspensionDamping;
    }

    /**
     * The damping coefficient for when the suspension is expanding.
     * See the comments for setSuspensionCompression for how to set k.
     * @param wheel
     * @param suspensionDamping
     */
    public function setSuspensionDampingAt(wheel:Int, suspensionDamping:Float):Void
	{
        wheels[wheel].setWheelsDampingRelaxation(suspensionDamping);
    }

    /**
     * @return the suspensionStiffness
     */
    public function getSuspensionStiffness():Float
	{
        return tuning.suspensionStiffness;
    }

    /**
     * Use before adding wheels, this is the default used when adding wheels.
     * After adding the wheel, use direct wheel access.<br>
     * The stiffness constant for the suspension.  10.0 - Offroad buggy, 50.0 - Sports car, 200.0 - F1 Car
     * @param suspensionStiffness 
     */
    public function setSuspensionStiffness(suspensionStiffness:Float):Void
	{
        tuning.suspensionStiffness = suspensionStiffness;
    }

    /**
     * The stiffness constant for the suspension.  10.0 - Offroad buggy, 50.0 - Sports car, 200.0 - F1 Car
     * @param wheel
     * @param suspensionStiffness
     */
    public function setSuspensionStiffnessAt(wheel:Int, suspensionStiffness:Float):Void
	{
        wheels[wheel].setSuspensionStiffness(suspensionStiffness);
    }

    /**
     * Reset the suspension
     */
    public function resetSuspension():Void
	{
        vehicle.resetSuspension();
    }

    /**
     * Apply the given engine force to all wheels, works continuously
     * @param force the force
     */
    public function accelerate(force:Float):Void
	{
        for (i in 0...wheels.length)
		{
            vehicle.applyEngineForce(force, i);
        }
    }

    /**
     * Apply the given engine force, works continuously
     * @param wheel the wheel to apply the force on
     * @param force the force
     */
    public function accelerateAt(wheel:Int, force:Float):Void
	{
        vehicle.applyEngineForce(force, wheel);
    }

    /**
     * Set the given steering value to all front wheels (0 = forward)
     * @param value the steering angle of the front wheels (Pi = 360deg)
     */
    public function steer(value:Float):Void
	{
        for (i in 0...wheels.length)
		{
            if (getWheel(i).isFrontWheel())
			{
                vehicle.setSteeringValue(value, i);
            }
        }
    }

    /**
     * Set the given steering value to the given wheel (0 = forward)
     * @param wheel the wheel to set the steering on
     * @param value the steering angle of the front wheels (Pi = 360deg)
     */
    public function steerAt(wheel:Int, value:Float):Void
	{
        vehicle.setSteeringValue(value, wheel);
    }

    /**
     * Apply the given brake force to all wheels, works continuously
     * @param force the force
     */
    public function brake(force:Float):Void
	{
        for (i in 0...wheels.length)
		{
            vehicle.setBrake(force, i);
        }
    }

    /**
     * Apply the given brake force, works continuously
     * @param wheel the wheel to apply the force on
     * @param force the force
     */
    public function brakeAt(wheel:Int, force:Float):Void
	{
        vehicle.setBrake(force, wheel);
    }

    /**
     * Get the current speed of the vehicle in km/h
     * @return
     */
    public function getCurrentVehicleSpeedKmHour():Float
	{
        return vehicle.getCurrentSpeedKmHour();
    }

    /**
     * Get the current forward vector of the vehicle in world coordinates
     * @param vector The object to write the forward vector values to.
     * Passing null will cause a new {Vector3f) to be created.
     * @return The forward vector
     */
    public function getForwardVector(vector:Vector3f):Vector3f 
	{
        if (vector == null)
		{
            vector = new Vector3f();
        }
        vehicle.getForwardVector(vector);
        return vector;
    }

    /**
     * used internally
     */
    public function getVehicleId():RaycastVehicle
	{
        return vehicle;
    }
}