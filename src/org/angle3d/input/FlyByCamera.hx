package org.angle3d.input;


import flash.ui.Keyboard;
import org.angle3d.collision.MotionAllowedListener;
import org.angle3d.input.controls.ActionListener;
import org.angle3d.input.controls.AnalogListener;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.input.controls.MouseAxisTrigger;
import org.angle3d.input.controls.MouseButtonTrigger;
import org.angle3d.input.controls.Trigger;
import org.angle3d.math.FastMath;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.Camera;


/**
 * A first person view camera controller.
 * After creation, you must register the camera controller with the
 * dispatcher using #registerWithDispatcher().
 *
 * Controls:
 *  - Move the mouse to rotate the camera
 *  - Mouse wheel for zooming in or out
 *  - WASD keys for moving forward/backward and strafing
 *  - QZ keys raise or lower the camera
 */
class FlyByCamera implements AnalogListener implements ActionListener
{
	private var cam:Camera;
	private var initialUpVec:Vector3f;
	private var rotationSpeed:Float;
	private var moveSpeed:Float;
	private var motionAllowed:MotionAllowedListener;
	private var enabled:Bool;
	private var dragToRotate:Bool = true;
	private var canRotate:Bool;
	private var inputManager:InputManager;

	/**
	 * Creates a new FlyByCamera to control the given Camera object.
	 * @param cam
	 */
	public function new(cam:Camera)
	{
		rotationSpeed = 1.0;
		moveSpeed = 3.0;
		motionAllowed = null;
		enabled = true;
		dragToRotate = false;
		canRotate = false;

		this.cam = cam;
		initialUpVec = cam.getUp().clone();
	}

	/**
	 * Sets the up vector that should be used for the camera.
	 * @param upVec
	 */
	public function setUpVector(upVec:Vector3f):Void
	{
		initialUpVec.copyFrom(upVec);
	}

	public function setMotionAllowedListener(listener:MotionAllowedListener):Void
	{
		this.motionAllowed = listener;
	}

	/**
	 * Sets the move speed. The speed is given in world units per second.
	 * @param moveSpeed
	 */
	public function setMoveSpeed(moveSpeed:Float):Void
	{
		this.moveSpeed = moveSpeed;
	}

	/**
	 * Sets the rotation speed.
	 * @param rotationSpeed
	 */
	public function setRotationSpeed(rotationSpeed:Float):Void
	{
		this.rotationSpeed = rotationSpeed;
	}

	/**
	 * @param enable If false, the camera will ignore input.
	 */
	public function setEnabled(value:Bool):Void
	{
		this.enabled = value;
	}

	/**
	 * @return If enabled
	 * @see FlyByCamera#setEnabled(Bool)
	 */
	public function isEnabled():Bool
	{
		return enabled;
	}

	/**
	 * @return If drag to rotate feature is enabled.
	 *
	 * @see FlyByCamera#setDragToRotate(Bool)
	 */
	public function isDragToRotate():Bool
	{
		return dragToRotate;
	}

	/**
	 * set_if drag to rotate mode is enabled.
	 *
	 * When true, the user must hold the mouse button
	 * and drag over the screen to rotate the camera, and the cursor is
	 * visible until dragged. Otherwise, the cursor is invisible at all times
	 * and holding the mouse button is not needed to rotate the camera.
	 * This feature is disabled by default.
	 *
	 * @param dragToRotate True if drag to rotate mode is enabled.
	 */
	public function setDragToRotate(dragToRotate:Bool):Void
	{
		this.dragToRotate = dragToRotate;
		inputManager.setCursorVisible(dragToRotate);
	}

	/**
	 * Registers the FlyByCamera to receive input events from the provided
	 * Dispatcher.
	 * @param dispacher
	 */
	public function registerWithInput(inputManager:InputManager):Void
	{
		this.inputManager = inputManager;

		var mappings:Array<String> = ["FLYCAM_Left", "FLYCAM_Right", "FLYCAM_Up", "FLYCAM_Down",

			"FLYCAM_StrafeLeft", "FLYCAM_StrafeRight", "FLYCAM_Forward", "FLYCAM_Backward",

			"FLYCAM_ZoomIn", "FLYCAM_ZoomOut", "FLYCAM_RotateDrag",

			"FLYCAM_Rise", "FLYCAM_Lower"];

		// both mouse and button - rotation of cam
		inputManager.addMapping("FLYCAM_Left", [new MouseAxisTrigger(MouseInput.AXIS_X, true), new KeyTrigger(Keyboard.LEFT)]);

		inputManager.addMapping("FLYCAM_Right", [new MouseAxisTrigger(MouseInput.AXIS_X, false), new KeyTrigger(Keyboard.RIGHT)]);

		inputManager.addMapping("FLYCAM_Up", [new MouseAxisTrigger(MouseInput.AXIS_Y, false), new KeyTrigger(Keyboard.UP)]);

		inputManager.addMapping("FLYCAM_Down", [new MouseAxisTrigger(MouseInput.AXIS_Y, true), new KeyTrigger(Keyboard.DOWN)]);

		// mouse only - zoom in/out with wheel, and rotate drag
		inputManager.addSingleMapping("FLYCAM_ZoomIn", new MouseAxisTrigger(MouseInput.AXIS_WHEEL, false));
		inputManager.addSingleMapping("FLYCAM_ZoomOut", new MouseAxisTrigger(MouseInput.AXIS_WHEEL, true));
		inputManager.addSingleMapping("FLYCAM_RotateDrag", new MouseButtonTrigger(MouseInput.BUTTON_LEFT));

		// keyboard only WASD for movement and WZ for rise/lower height
		inputManager.addSingleMapping("FLYCAM_StrafeLeft", new KeyTrigger(Keyboard.A));
		inputManager.addSingleMapping("FLYCAM_StrafeRight", new KeyTrigger(Keyboard.D));
		inputManager.addSingleMapping("FLYCAM_Forward", new KeyTrigger(Keyboard.W));
		inputManager.addSingleMapping("FLYCAM_Backward", new KeyTrigger(Keyboard.S));
		inputManager.addSingleMapping("FLYCAM_Rise", new KeyTrigger(Keyboard.Q));
		inputManager.addSingleMapping("FLYCAM_Lower", new KeyTrigger(Keyboard.Z));

		inputManager.addListener(this, mappings);
		inputManager.setCursorVisible(dragToRotate);
	}

	private function rotateCamera(value:Float, axis:Vector3f):Void
	{
		//Lib.trace("rotateCamera:" + value);
		if (dragToRotate && !canRotate)
		{
			return;
		}

		var mat:Matrix3f = new Matrix3f();
		mat.fromAngleNormalAxis(rotationSpeed * value, axis);

		var up:Vector3f = cam.getUp();
		var left:Vector3f = cam.getLeft();
		var dir:Vector3f = cam.getDirection();

		mat.multVec(up, up);
		mat.multVec(left, left);
		mat.multVec(dir, dir);

		var q:Quaternion = new Quaternion();
		q.fromAxes(left, up, dir);
		q.normalizeLocal();

		cam.setAxesFromQuat(q);

	}

	private function zoomCamera(value:Float):Void
	{
		// derive fovY value
		var h:Float = cam.frustumTop;
		var w:Float = cam.frustumRight;
		var aspect:Float = w / h;

		var near:Float = cam.frustumNear;

		var fovY:Float = Math.atan(h / near) / (FastMath.DEGTORAD() * .5);
		fovY += value; //* 0.1f;

		fovY = FastMath.clamp(fovY, 45, 135);

		h = Math.tan(fovY * FastMath.DEGTORAD() * .5) * near;
		w = h * aspect;

		cam.setFrustumRect(-w, w, -h, h);
	}

	private function riseCamera(value:Float):Void
	{
		var vel:Vector3f = new Vector3f(0, value * moveSpeed, 0);
		var pos:Vector3f = cam.location.clone();

		if (motionAllowed != null)
			motionAllowed.checkMotionAllowed(pos, vel);
		else
			pos.addLocal(vel);

		cam.location = pos;
	}

	private function moveCamera(value:Float, sideways:Bool):Void
	{
		var vel:Vector3f = new Vector3f();
		var pos:Vector3f = cam.location.clone();

		if (sideways)
		{
			cam.getLeft(vel);
		}
		else
		{
			cam.getDirection(vel);
		}

		vel.scaleLocal(value * moveSpeed);

		if (motionAllowed != null)
			motionAllowed.checkMotionAllowed(pos, vel);
		else
			pos.addLocal(vel);

		cam.location = pos;
	}

	public function onAnalog(name:String, value:Float, tpf:Float):Void
	{
		if (!enabled)
			return;

		switch (name)
		{
			case "FLYCAM_Left":
				rotateCamera(-value, initialUpVec);
			case "FLYCAM_Right":
				rotateCamera(value, initialUpVec);
			case "FLYCAM_Up":
				rotateCamera(-value, cam.getLeft());
			case "FLYCAM_Down":
				rotateCamera(value, cam.getLeft());
			case "FLYCAM_Forward":
				moveCamera(value, false);
			case "FLYCAM_Backward":
				moveCamera(-value, false);
			case "FLYCAM_StrafeLeft":
				moveCamera(value, true);
			case "FLYCAM_StrafeRight":
				moveCamera(-value, true);
			case "FLYCAM_Rise":
				riseCamera(value);
			case "FLYCAM_Lower":
				riseCamera(-value);
			case "FLYCAM_ZoomIn":
				zoomCamera(value);
			case "FLYCAM_ZoomOut":
				zoomCamera(value);
		}
	}

	public function onAction(name:String, value:Bool, tpf:Float):Void
	{
		if (!enabled)
			return;

		if (name == "FLYCAM_RotateDrag" && dragToRotate)
		{
			canRotate = value;
				//inputManager.setCursorVisible(!value);
		}
	}
}

