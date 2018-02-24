package angle3d.scene;

import angle3d.renderer.Camera;
import angle3d.scene.control.CameraControl;
import angle3d.scene.control.ControlDirection;

/**
 * `CameraNode` simply uses `CameraControl` to implement
 * linking of camera and node data.
 */
class CameraNode extends Node {
	public var controlDir(get, set):ControlDirection;

	private var mCamControl:CameraControl;

	public function new(name:String, camera:Camera) {
		super(name);

		mCamControl = new CameraControl();
		addControl(mCamControl);
		if (camera != null) {
			mCamControl.camera = camera;
		}
	}

	public function getCameraControl():CameraControl {
		return mCamControl;
	}

	public function setEnabled(enabled:Bool):Void {
		mCamControl.setEnabled(enabled);
	}

	public function isEnabled():Bool {
		return mCamControl.isEnabled();
	}

	private function set_controlDir(controlDir:ControlDirection):ControlDirection {
		return mCamControl.controlDir = controlDir;
	}

	private function get_controlDir():ControlDirection {
		return mCamControl.controlDir;
	}

	public function setCamera(camera:Camera):Void {
		mCamControl.camera = camera;
	}

	public function getCamera():Camera {
		return mCamControl.camera;
	}
}

