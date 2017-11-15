package org.angle3d.bullet.debug;

import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.control.AbstractControl;
import org.angle3d.scene.Spatial;

/**
 * ...

 */
class AbstractPhysicsDebugControl extends AbstractControl {
	private var tmp_inverseWorldRotation:Quaternion = new Quaternion();
	private var debugAppState:BulletDebugAppState;

	public function new(debugAppState:BulletDebugAppState) {
		super();
		this.debugAppState = debugAppState;
	}

	private function applyPhysicsTransform(worldLocation:Vector3f, worldRotation:Quaternion, spatial:Spatial = null):Void {
		if (spatial != null) {
			var localLocation:Vector3f = spatial.getLocalTranslation();
			var localRotationQuat:Quaternion = spatial.getLocalRotation();
			if (spatial.parent != null) {
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

}