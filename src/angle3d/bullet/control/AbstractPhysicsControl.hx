package angle3d.bullet.control;
import angle3d.math.Quaternion;
import angle3d.math.Vector3f;
import angle3d.renderer.ViewPort;
import angle3d.renderer.RenderManager;
import angle3d.scene.Spatial;
import angle3d.scene.control.Control;
import angle3d.bullet.PhysicsSpace;

/**
 * ...

 */
class AbstractPhysicsControl implements PhysicsControl {
	private var tmp_inverseWorldRotation:Quaternion = new Quaternion();
	private var spatial:Spatial;
	private var enabled:Bool = true;
	private var added:Bool = false;
	private var space:PhysicsSpace = null;
	private var applyLocal:Bool = false;

	public function new() {

	}

	public function dispose():Void {
		spatial = null;
		space = null;
	}

	/**
	 * Called when the control is added to a new spatial, create any
	 * spatial-dependent data here.
	 *
	 * @param spat The new spatial, guaranteed not to be null
	 */
	private function createSpatialData(spat:Spatial):Void {

	}

	/**
	 * Called when the control is removed from a spatial, remove any
	 * spatial-dependent data here.
	 *
	 * @param spat The old spatial, guaranteed not to be null
	 */
	private function removeSpatialData(spat:Spatial):Void {

	}

	/**
	 * Called when the physics object is supposed to move to the spatial
	 * position.
	 *
	 * @param vec
	 */
	private function setPhysicsLocation(vec:Vector3f):Void {

	}

	/**
	 * Called when the physics object is supposed to move to the spatial
	 * rotation.
	 *
	 * @param quat
	 */
	private function setPhysicsRotation(quat:Quaternion):Void {

	}

	/**
	 * Called when the physics object is supposed to add all objects it needs to
	 * manage to the physics space.
	 *
	 * @param space
	 */
	private function addPhysics(space:PhysicsSpace):Void {

	}

	/**
	 * Called when the physics object is supposed to remove all objects added to
	 * the physics space.
	 *
	 * @param space
	 */
	private function removePhysics(space:PhysicsSpace):Void {

	}

	public function isApplyPhysicsLocal():Bool {
		return applyLocal;
	}

	/**
	 * When set to true, the physics coordinates will be applied to the local
	 * translation of the Spatial
	 *
	 * @param applyPhysicsLocal
	 */
	public function setApplyPhysicsLocal(applyPhysicsLocal:Bool):Void {
		applyLocal = applyPhysicsLocal;
	}

	private function getSpatialTranslation():Vector3f {
		if (applyLocal) {
			return spatial.getLocalTranslation();
		}
		return spatial.getWorldTranslation();
	}

	private function getSpatialRotation():Quaternion {
		if (applyLocal) {
			return spatial.getLocalRotation();
		}
		return spatial.getWorldRotation();
	}

	/**
	 * Applies a physics transform to the spatial
	 *
	 * @param worldLocation
	 * @param worldRotation
	 */
	private function applyPhysicsTransform(worldLocation:Vector3f, worldRotation:Quaternion):Void {
		if (enabled && spatial != null) {
			var localLocation:Vector3f = spatial.getLocalTranslation();
			var localRotationQuat:Quaternion = spatial.getLocalRotation();
			if (!applyLocal && spatial.parent != null) {
				localLocation.copyFrom(worldLocation).subtractLocal(spatial.parent.getWorldTranslation());
				localLocation.divideLocal(spatial.parent.getWorldScale());
				tmp_inverseWorldRotation.copyFrom(spatial.parent.getWorldRotation()).inverseLocal().multVecLocal(localLocation);
				localRotationQuat.copyFrom(worldRotation);
				tmp_inverseWorldRotation.copyFrom(spatial.parent.getWorldRotation()).inverseLocal().mult(localRotationQuat, localRotationQuat);

				spatial.setLocalTranslation(localLocation);
				spatial.setLocalRotation(localRotationQuat);
			} else {
				spatial.setLocalTranslation(worldLocation);
				spatial.setLocalRotation(worldRotation);
			}
		}

	}

	/* INTERFACE angle3d.bullet.control.PhysicsControl */

	public function setPhysicsSpace(space:PhysicsSpace):Void {
		if (space == null) {
			if (this.space != null) {
				removePhysics(this.space);
				added = false;
			}
		} else
		{
			if (this.space == space) {
				return;
			} else if (this.space != null) {
				removePhysics(this.space);
			}
			addPhysics(space);
			added = true;
		}
		this.space = space;
	}

	public function getPhysicsSpace():PhysicsSpace {
		return space;
	}

	public function cloneForSpatial(spatial:Spatial):Control {
		return null;
	}

	public function setSpatial(spatial:Spatial):Void {
		if (this.spatial != null && this.spatial != spatial) {
			removeSpatialData(this.spatial);
		} else if (this.spatial == spatial) {
			return;
		}
		this.spatial = spatial;
		if (spatial == null) {
			return;
		}
		createSpatialData(this.spatial);
		setPhysicsLocation(getSpatialTranslation());
		setPhysicsRotation(getSpatialRotation());
	}

	public function isEnabled():Bool {
		return enabled;
	}

	public function setEnabled(enabled:Bool):Void {
		this.enabled = enabled;
		if (space != null) {
			if (enabled && !added) {
				if (spatial != null) {
					setPhysicsLocation(getSpatialTranslation());
					setPhysicsRotation(getSpatialRotation());
				}
				addPhysics(space);
				added = true;
			} else if (!enabled && added) {
				removePhysics(space);
				added = false;
			}
		}
	}

	public function update(tpf:Float):Void {

	}

	public function render(rm:RenderManager, vp:ViewPort):Void {

	}

}