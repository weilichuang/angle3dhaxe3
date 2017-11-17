package org.angle3d.scene.control;

import org.angle3d.math.Quaternion;
import org.angle3d.renderer.Camera;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.scene.Spatial;
import org.angle3d.math.Vector3f;

/**
 * This Control maintains a reference to a Camera,
 * which will be synched with the position (worldTranslation)
 * of the current spatial.
 */
class CameraControl extends AbstractControl {
	public var controlDir(get, set):ControlDirection;
	public var camera(get, set):Camera;

	private var mCamera:Camera;
	private var mControlDir:ControlDirection;

	/**
	 * @param camera The Camera to be synced.
	 * @param controlDir The ControlDirection .
	 */
	public function new(camera:Camera = null, controlDir:ControlDirection = null) {
		super();

		this.mCamera = camera;

		if (controlDir != null) {
			this.controlDir = controlDir;
		} else {
			this.controlDir = ControlDirection.SpatialToCamera;
		}
	}

	private function set_controlDir(dir:ControlDirection):ControlDirection {
		return this.mControlDir = dir;
	}

	private function get_controlDir():ControlDirection {
		return mControlDir;
	}

	private function set_camera(camera:Camera):Camera {
		return this.mCamera = camera;
	}

	private function get_camera():Camera {
		return mCamera;
	}

	override private function controlUpdate(tpf:Float):Void {
		var spatial:Spatial = getSpatial();
		if (spatial != null && mCamera != null) {
			switch (mControlDir) {
				case ControlDirection.SpatialToCamera:
					mCamera.location = spatial.getWorldTranslation();
					mCamera.rotation = spatial.getWorldRotation();

				case ControlDirection.CameraToSpatial:
					// set the localtransform, so that the worldtransform would be equal to the camera's transform.
					// Location:
					var vecDiff:Vector3f = mCamera.location.subtract(spatial.getWorldTranslation());
					vecDiff.addLocal(spatial.localTranslation);
					spatial.setLocalTranslation(vecDiff);

					// Rotation:
					var worldDiff:Quaternion = mCamera.rotation.subtract(spatial.getWorldRotation());
					worldDiff.addLocal(spatial.getLocalRotation());
					spatial.setLocalRotation(worldDiff);
			}
		}
	}

	override private function controlRender(rm:RenderManager, vp:ViewPort):Void {
		// nothing to do
	}

	override public function cloneForSpatial(newSpatial:Spatial):Control {
		var control:CameraControl = new CameraControl(this.mCamera, this.mControlDir);
		control.setSpatial(newSpatial);
		control.setEnabled(isEnabled());
		return control;
	}
}

