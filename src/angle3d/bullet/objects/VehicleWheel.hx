package angle3d.bullet.objects;
import com.bulletphysics.dynamics.RigidBody;
import com.bulletphysics.dynamics.vehicle.WheelInfo;
import angle3d.bullet.collision.PhysicsCollisionObject;
import angle3d.bullet.util.Converter;
import angle3d.math.Matrix3f;
import angle3d.math.Quaternion;
import angle3d.math.Vector3f;
import angle3d.scene.Spatial;
import angle3d.utils.Logger;

/**
 * Stores info about one wheel of a PhysicsVehicle

 */
class VehicleWheel {

	private var wheelInfo:WheelInfo;
	private var frontWheel:Bool;
	private var location:Vector3f = new Vector3f();
	private var direction:Vector3f = new Vector3f();
	private var axle:Vector3f = new Vector3f();
	private var suspensionStiffness:Float = 20.0;
	private var wheelsDampingRelaxation:Float = 2.3;
	private var wheelsDampingCompression:Float = 4.4;
	private var frictionSlip:Float = 10.5;
	private var rollInfluence:Float = 1.0;
	private var maxSuspensionTravelCm:Float = 500;
	private var maxSuspensionForce:Float = 6000;
	private var radius:Float = 0.5;
	private var restLength:Float = 1;
	private var wheelWorldLocation:Vector3f = new Vector3f();
	private var wheelWorldRotation:Quaternion = new Quaternion();
	private var wheelSpatial:Spatial;
	private var tmp_Matrix:Matrix3f = new Matrix3f();
	private var tmp_inverseWorldRotation:Quaternion = new Quaternion();
	private var applyLocal:Bool = false;

	public function new(location:Vector3f, direction:Vector3f, axle:Vector3f,
						restLength:Float, radius:Float, frontWheel:Bool, spat:Spatial = null) {
		this.location.copyFrom(location);
		this.direction.copyFrom(direction);
		this.axle.copyFrom(axle);
		this.frontWheel = frontWheel;
		this.restLength = restLength;
		this.radius = radius;
		wheelSpatial = spat;
	}

	public function updatePhysicsState():Void {
		wheelWorldLocation.copyFrom(wheelInfo.worldTransform.origin);
		tmp_Matrix.copyFrom(wheelInfo.worldTransform.basis);
		wheelWorldRotation.fromMatrix3f(tmp_Matrix);
	}

	public function applyWheelTransform(index:Int):Void {
		if (wheelSpatial == null) {
			return;
		}

		var localRotationQuat:Quaternion = wheelSpatial.getLocalRotation();
		var localLocation:Vector3f = wheelSpatial.getLocalTranslation();
		if (!applyLocal && wheelSpatial.parent != null) {
			localLocation.copyFrom(wheelWorldLocation).subtractLocal(wheelSpatial.parent.getWorldTranslation());
			localLocation.divideLocal(wheelSpatial.parent.getWorldScale());
			tmp_inverseWorldRotation.copyFrom(wheelSpatial.parent.getWorldRotation()).inverseLocal().multVecLocal(localLocation);

			localRotationQuat.copyFrom(wheelWorldRotation);
			tmp_inverseWorldRotation.copyFrom(wheelSpatial.parent.getWorldRotation()).inverseLocal().mult(localRotationQuat, localRotationQuat);

			wheelSpatial.setLocalTranslation(localLocation);
			wheelSpatial.setLocalRotation(localRotationQuat);
		} else
		{
			wheelSpatial.setLocalTranslation(wheelWorldLocation);
			wheelSpatial.setLocalRotation(wheelWorldRotation);
		}
	}

	public function getWheelInfo():WheelInfo {
		return wheelInfo;
	}

	public function setWheelInfo(wheelInfo:WheelInfo):Void {
		this.wheelInfo = wheelInfo;
		applyInfo();
	}

	public function isFrontWheel():Bool {
		return frontWheel;
	}

	public function setFrontWheel(frontWheel:Bool):Void {
		this.frontWheel = frontWheel;
		applyInfo();
	}

	public function getLocation():Vector3f {
		return location;
	}

	public function getDirection():Vector3f {
		return direction;
	}

	public function getAxle():Vector3f {
		return axle;
	}

	public function getSuspensionStiffness():Float {
		return suspensionStiffness;
	}

	/**
	 * the stiffness constant for the suspension.  10.0 - Offroad buggy, 50.0 - Sports car, 200.0 - F1 Car
	 * @param suspensionStiffness
	 */
	public function setSuspensionStiffness(suspensionStiffness:Float):Void {
		this.suspensionStiffness = suspensionStiffness;
		applyInfo();
	}

	public function getWheelsDampingRelaxation():Float {
		return wheelsDampingRelaxation;
	}

	/**
	 * the damping coefficient for when the suspension is expanding.
	 * See the comments for setWheelsDampingCompression for how to set k.
	 * @param wheelsDampingRelaxation
	 */
	public function setWheelsDampingRelaxation(wheelsDampingRelaxation:Float):Void {
		this.wheelsDampingRelaxation = wheelsDampingRelaxation;
		applyInfo();
	}

	public function getWheelsDampingCompression():Float {
		return wheelsDampingCompression;
	}

	/**
	 * the damping coefficient for when the suspension is compressed.
	 * Set to k * 2.0 * FastMath.sqrt(m_suspensionStiffness) so k is proportional to critical damping.<br>
	 * k = 0.0 undamped & bouncy, k = 1.0 critical damping<br>
	 * 0.1 to 0.3 are good values
	 * @param wheelsDampingCompression
	 */
	public function setWheelsDampingCompression(wheelsDampingCompression:Float):Void {
		this.wheelsDampingCompression = wheelsDampingCompression;
		applyInfo();
	}

	public function getFrictionSlip():Float {
		return frictionSlip;
	}

	/**
	 * the coefficient of friction between the tyre and the ground.
	 * Should be about 0.8 for realistic cars, but can increased for better handling.
	 * Set large (10000.0) for kart racers
	 * @param frictionSlip
	 */
	public function setFrictionSlip(frictionSlip:Float):Void {
		this.frictionSlip = frictionSlip;
		applyInfo();
	}

	public function getRollInfluence():Float {
		return rollInfluence;
	}

	/**
	 * reduces the rolling torque applied from the wheels that cause the vehicle to roll over.
	 * This is a bit of a hack, but it's quite effective. 0.0 = no roll, 1.0 = physical behaviour.
	 * If m_frictionSlip is too high, you'll need to reduce this to stop the vehicle rolling over.
	 * You should also try lowering the vehicle's centre of mass
	 * @param rollInfluence the rollInfluence to set
	 */
	public function setRollInfluence(rollInfluence:Float):Void {
		this.rollInfluence = rollInfluence;
		applyInfo();
	}

	public function getMaxSuspensionTravelCm():Float {
		return maxSuspensionTravelCm;
	}

	/**
	 * the maximum distance the suspension can be compressed (centimetres)
	 * @param maxSuspensionTravelCm
	 */
	public function setMaxSuspensionTravelCm(maxSuspensionTravelCm:Float):Void {
		this.maxSuspensionTravelCm = maxSuspensionTravelCm;
		applyInfo();
	}

	public function getMaxSuspensionForce():Float {
		return maxSuspensionForce;
	}

	/**
	 * The maximum suspension force, raise this above the default 6000 if your suspension cannot
	 * handle the weight of your vehcile.
	 * @param maxSuspensionForce
	 */
	public function setMaxSuspensionForce(maxSuspensionForce:Float):Void {
		this.maxSuspensionForce = maxSuspensionForce;
		applyInfo();
	}

	private function applyInfo():Void {
		if (wheelInfo == null) {
			return;
		}
		wheelInfo.suspensionStiffness = suspensionStiffness;
		wheelInfo.wheelsDampingRelaxation = wheelsDampingRelaxation;
		wheelInfo.wheelsDampingCompression = wheelsDampingCompression;
		wheelInfo.frictionSlip = frictionSlip;
		wheelInfo.rollInfluence = rollInfluence;
		wheelInfo.maxSuspensionTravelCm = maxSuspensionTravelCm;
		wheelInfo.maxSuspensionForce = maxSuspensionForce;
		wheelInfo.wheelsRadius = radius;
		wheelInfo.bIsFrontWheel = frontWheel;
		wheelInfo.suspensionRestLength1 = restLength;
	}

	public function getRadius():Float {
		return radius;
	}

	public function setRadius(radius:Float):Void {
		this.radius = radius;
		applyInfo();
	}

	public function getRestLength():Float {
		return restLength;
	}

	public function setRestLength(restLength:Float):Void {
		this.restLength = restLength;
		applyInfo();
	}

	/**
	 * returns the object this wheel is in contact with or null if no contact
	 * @return the PhysicsCollisionObject (PhysicsRigidBody, PhysicsGhostObject)
	 */
	public function getGroundObject():PhysicsCollisionObject {
		if (wheelInfo.raycastInfo.groundObject == null) {
			return null;
		} else if (Std.is(wheelInfo.raycastInfo.groundObject,RigidBody)) {
			return cast cast(wheelInfo.raycastInfo.groundObject,RigidBody).getUserPointer();
		} else
		{
			return null;
		}
	}

	/**
	 * returns the location where the wheel collides with the ground (world space)
	 */
	public function getCollisionLocation(vec:Vector3f = null):Vector3f {
		if (vec == null)
			vec = new Vector3f();
		vec.copyFrom(wheelInfo.raycastInfo.contactPointWS);
		return vec;
	}

	/**
	 * returns the normal where the wheel collides with the ground (world space)
	 */
	public function getCollisionNormal(vec:Vector3f):Vector3f {
		if (vec == null)
			vec = new Vector3f();
		vec.copyFrom(wheelInfo.raycastInfo.contactNormalWS);
		return vec;
	}

	/**
	 * returns how much the wheel skids on the ground (for skid sounds/smoke etc.)<br>
	 * 0.0 = wheels are sliding, 1.0 = wheels have traction.
	 */
	public function getSkidInfo():Float {
		return wheelInfo.skidInfo;
	}

	/**
	 * returns how many degrees the wheel has turned since the last physics
	 * step.
	 */
	public function getDeltaRotation():Float {
		return wheelInfo.deltaRotation;
	}

	/**
	 * @return the wheelSpatial
	 */
	public function getWheelSpatial():Spatial {
		return wheelSpatial;
	}

	/**
	 * @param wheelSpatial the wheelSpatial to set
	 */
	public function setWheelSpatial(wheelSpatial:Spatial):Void {
		this.wheelSpatial = wheelSpatial;
	}

	public function isApplyLocal():Bool {
		return applyLocal;
	}

	public function setApplyLocal(applyLocal:Bool):Void {
		this.applyLocal = applyLocal;
	}

}