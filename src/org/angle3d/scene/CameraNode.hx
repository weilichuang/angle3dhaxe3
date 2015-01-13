package org.angle3d.scene;

import org.angle3d.renderer.Camera;
import org.angle3d.scene.control.CameraControl;

/**
 * CameraNode simply uses CameraControl to implement
 * linking of camera and node data.
 *
 * @author weilichuang
 */

class CameraNode extends Node
{
	public var controlDir(get, set):String;
	
	private var mCamControl:CameraControl;

	public function new(name:String, camera:Camera)
	{
		super(name);
		
		mCamControl = new CameraControl();
		addControl(mCamControl);
		if (camera != null)
		{
			mCamControl.camera = camera;
		}
	}

	public function getCameraControl():CameraControl
	{
		return mCamControl;
	}

	public function setEnabled(enabled:Bool):Void
	{
		mCamControl.setEnabled(enabled);
	}

	public function isEnabled():Bool
	{
		return mCamControl.isEnabled();
	}

	
	private function set_controlDir(controlDir:String):String
	{
		return mCamControl.controlDir = controlDir;
	}

	private function get_controlDir():String
	{
		return mCamControl.controlDir;
	}

	public function setCamera(camera:Camera):Void
	{
		mCamControl.camera = camera;
	}

	public function getCamera():Camera
	{
		return mCamControl.camera;
	}
}

