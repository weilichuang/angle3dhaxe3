package angle3d.bullet.control;
import angle3d.bullet.objects.VehicleWheel;
import angle3d.math.Quaternion;
import angle3d.math.Vector3f;
import angle3d.renderer.ViewPort;
import angle3d.renderer.RenderManager;
import angle3d.scene.Node;
import angle3d.scene.Spatial;
import angle3d.scene.control.Control;

import angle3d.bullet.collision.shapes.CollisionShape;
import angle3d.bullet.objects.PhysicsVehicle;
import angle3d.bullet.PhysicsSpace;

class VehicleControl extends PhysicsVehicle implements PhysicsControl {
	private var spatial:Spatial;
	private var enabled:Bool = true;
	private var space:PhysicsSpace = null;
	private var added:Bool = false;

	public function new(shape:CollisionShape, mass:Float = 1.0) {
		super(shape, mass);

	}

	public function dispose():Void {
		spatial = null;
		space = null;
	}

	public function isApplyPhysicsLocal():Bool {
		return motionState.isApplyPhysicsLocal();
	}

	/**
	 * When set to true, the physics coordinates will be applied to the local
	 * translation of the Spatial
	 *
	 * @param applyPhysicsLocal
	 */
	public function setApplyPhysicsLocal(applyPhysicsLocal:Bool):Void {
		motionState.setApplyPhysicsLocal(applyPhysicsLocal);
		for (i in 0...wheels.length) {
			wheels[i].setApplyLocal(applyPhysicsLocal);
		}
	}

	private function getSpatialTranslation():Vector3f {
		if (motionState.isApplyPhysicsLocal()) {
			return spatial.getLocalTranslation();
		}
		return spatial.getWorldTranslation();
	}

	private function getSpatialRotation():Quaternion {
		if (motionState.isApplyPhysicsLocal()) {
			return spatial.getLocalRotation();
		}
		return spatial.getWorldRotation();
	}

	/* INTERFACE angle3d.bullet.control.PhysicsControl */

	public function setPhysicsSpace(space:PhysicsSpace):Void {
		createVehicle(space);
		if (space == null) {
			if (this.space != null) {
				this.space.removeCollisionObject(this);
				added = false;
			}
		} else
		{
			if (this.space == space)
				return;
			space.addCollisionObject(this);
			added = true;
		}
		this.space = space;
	}

	public function getPhysicsSpace():PhysicsSpace {
		return space;
	}

	public function cloneForSpatial(spatial:Spatial):Control {
		var control:VehicleControl = new VehicleControl(collisionShape, mass);
		control.setAngularFactor(getAngularFactor());
		control.setAngularSleepingThreshold(getAngularSleepingThreshold());
		control.setAngularVelocity(getAngularVelocity());
		control.setCcdMotionThreshold(getCcdMotionThreshold());
		control.setCcdSweptSphereRadius(getCcdSweptSphereRadius());
		control.setCollideWithGroups(getCollideWithGroups());
		control.setCollisionGroup(getCollisionGroup());
		control.setDamping(getLinearDamping(), getAngularDamping());
		control.setFriction(getFriction());
		control.setGravity(getGravity());
		control.setKinematic(isKinematic());
		control.setLinearSleepingThreshold(getLinearSleepingThreshold());
		control.setLinearVelocity(getLinearVelocity());
		control.setPhysicsLocation(getPhysicsLocation());
		control.setPhysicsRotation(getPhysicsRotationMatrix());
		control.setRestitution(getRestitution());

		control.setFrictionSlip(getFrictionSlip());
		control.setMaxSuspensionTravelCm(getMaxSuspensionTravelCm());
		control.setSuspensionStiffness(getSuspensionStiffness());
		control.setSuspensionCompression(tuning.suspensionCompression);
		control.setSuspensionDamping(tuning.suspensionDamping);
		control.setMaxSuspensionForce(getMaxSuspensionForce());

		for (i in 0...wheels.length) {
			var wheel:VehicleWheel = wheels[i];
			var newWheel:VehicleWheel = control.addWheel(wheel.getLocation(), wheel.getDirection(), wheel.getAxle(), wheel.getRestLength(), wheel.getRadius(), wheel.isFrontWheel());
			newWheel.setFrictionSlip(wheel.getFrictionSlip());
			newWheel.setMaxSuspensionTravelCm(wheel.getMaxSuspensionTravelCm());
			newWheel.setSuspensionStiffness(wheel.getSuspensionStiffness());
			newWheel.setWheelsDampingCompression(wheel.getWheelsDampingCompression());
			newWheel.setWheelsDampingRelaxation(wheel.getWheelsDampingRelaxation());
			newWheel.setMaxSuspensionForce(wheel.getMaxSuspensionForce());

			//TODO: bad way finding children!
			if (Std.is(spatial, Node)) {
				var node:Node = cast spatial;
				var wheelSpat:Spatial = node.getChildByName(wheel.getWheelSpatial().name);
				if (wheelSpat != null) {
					newWheel.setWheelSpatial(wheelSpat);
				}
			}
		}
		control.setApplyPhysicsLocal(isApplyPhysicsLocal());
		return control;
	}

	public function setSpatial(spatial:Spatial):Void {
		this.spatial = spatial;
		setUserObject(spatial);
		if (spatial == null) {
			return;
		}
		setPhysicsLocation(getSpatialTranslation());
		setPhysicsRotationWithQuaternion(getSpatialRotation());
	}

	public function setEnabled(enabled:Bool):Void {
		this.enabled = enabled;
		if (space != null) {
			if (enabled && !added) {
				if (spatial != null) {
					setPhysicsLocation(getSpatialTranslation());
					setPhysicsRotationWithQuaternion(getSpatialRotation());
				}
				space.addCollisionObject(this);
				added = true;
			} else if (!enabled && added) {
				space.removeCollisionObject(this);
				added = false;
			}
		}
	}

	public function isEnabled():Bool {
		return this.enabled;
	}

	public function update(tpf:Float):Void {
		if (enabled && spatial != null) {
			if (getMotionState().applyTransform(spatial)) {
				spatial.getWorldTransform();
				applyWheelTransforms();
			}
		} else if (enabled) {
			applyWheelTransforms();
		}
	}

	public function render(rm:RenderManager, vp:ViewPort):Void {

	}

}