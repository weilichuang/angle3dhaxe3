package org.angle3d.input;


import flash.ui.Keyboard;
import flash.Vector;
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
import org.angle3d.utils.Logger;


/**
 * A first person view camera controller.

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
	private var rotationSpeed:Float = 1.0;
	private var moveSpeed:Float = 3.0;
	private var zoomSpeed:Float = 1.0;
	
	private var motionAllowed:MotionAllowedListener = null;
	private var enabled:Bool = true;
	private var dragToRotate:Bool = true;
	private var canRotate:Bool = false;
	private var invertY:Bool  = false;
	private var inputManager:InputManager;
	
	private var _inputMapping:Vector<String>;
	private var _inputTriggers:Vector<Trigger>;

	/**
	 * Creates a new FlyByCamera to control the given Camera object.
	 * @param cam
	 */
	public function new(cam:Camera)
	{
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
     * Sets the zoom speed.
     * @param zoomSpeed 
     */
	public function setZoomSpeed(value:Float):Void
	{
		this.zoomSpeed = value;
	}

	/**
     * Gets the zoom speed.  The speed is a multiplier to increase/decrease
     * the zoom rate.
     * @return zoomSpeed
     */
	public function getZoomSpeed():Float
	{
		return zoomSpeed;
	}

	/**
	 * @param enable If false, the camera will ignore input.
	 */
	public function setEnabled(value:Bool):Void
	{
		if (enabled && !value)
		{
            //if (inputManager != null && (!dragToRotate || (dragToRotate && canRotate)))
			//{
                //inputManager.setCursorVisible(true);
            //}
        }
		this.enabled = value;
	}

	/**
	 * @return If enabled
	 * @see `FlyByCamera.setEnabled`
	 */
	public function isEnabled():Bool
	{
		return enabled;
	}

	/**
	 * @return If drag to rotate feature is enabled.
	 *
	 * @see `FlyByCamera.setDragToRotate`
	 */
	public function isDragToRotate():Bool
	{
		return dragToRotate;
	}

	/**
	 * set if drag to rotate mode is enabled.
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
		//if (inputManager != null)
		//{
            //inputManager.setCursorVisible(dragToRotate);
        //}
	}

	/**
	 * Registers the FlyByCamera to receive input events from the provided
	 * Dispatcher.
	 * @param dispacher
	 */
	public function registerWithInput(inputManager:InputManager):Void
	{
		this.inputManager = inputManager;

		_inputMapping = Vector.ofArray([CameraInput.FLYCAM_LEFT,CameraInput.FLYCAM_LEFT,
										CameraInput.FLYCAM_RIGHT,CameraInput.FLYCAM_RIGHT,
										CameraInput.FLYCAM_UP,CameraInput.FLYCAM_UP,
										CameraInput.FLYCAM_DOWN,CameraInput.FLYCAM_DOWN,

										CameraInput.FLYCAM_ZOOMIN,
										CameraInput.FLYCAM_ZOOMOUT,
										
										CameraInput.FLYCAM_ROTATEDRAG,
										
										CameraInput.FLYCAM_STRAFELEFT,
										CameraInput.FLYCAM_STRAFERIGHT,
										CameraInput.FLYCAM_FORWARD,
										CameraInput.FLYCAM_BACKWARD,

										CameraInput.FLYCAM_RISE,
										CameraInput.FLYCAM_LOWER,
										
										CameraInput.FLYCAM_INVERTY]);

		_inputTriggers = new Vector<Trigger>();
		
		// both mouse and button - rotation of cam
		_inputTriggers.push(new MouseAxisTrigger(MouseInput.AXIS_X, true));
		_inputTriggers.push(new KeyTrigger(Keyboard.LEFT));

		_inputTriggers.push(new MouseAxisTrigger(MouseInput.AXIS_X, false));
		_inputTriggers.push( new KeyTrigger(Keyboard.RIGHT));

		_inputTriggers.push(new MouseAxisTrigger(MouseInput.AXIS_Y, false));
		_inputTriggers.push( new KeyTrigger(Keyboard.UP));

		_inputTriggers.push(new MouseAxisTrigger(MouseInput.AXIS_Y, true));
		_inputTriggers.push( new KeyTrigger(Keyboard.DOWN));

		// mouse only - zoom in/out with wheel, and rotate drag
		_inputTriggers.push(new MouseAxisTrigger(MouseInput.AXIS_WHEEL, false));
		_inputTriggers.push(new MouseAxisTrigger(MouseInput.AXIS_WHEEL, true));
		_inputTriggers.push(new MouseButtonTrigger(MouseInput.BUTTON_LEFT));
		
		// keyboard only WASD for movement and QZ for rise/lower height
		_inputTriggers.push(new KeyTrigger(Keyboard.A));
		_inputTriggers.push(new KeyTrigger(Keyboard.D));
		_inputTriggers.push(new KeyTrigger(Keyboard.W));
		_inputTriggers.push(new KeyTrigger(Keyboard.S));
		_inputTriggers.push(new KeyTrigger(Keyboard.Q));
		_inputTriggers.push(new KeyTrigger(Keyboard.Z));
		_inputTriggers.push(new KeyTrigger(Keyboard.Y));
		
		for (i in 0..._inputMapping.length)
		{
			inputManager.addTrigger(_inputMapping[i], _inputTriggers[i]);
		}

		inputManager.addListener(this, _inputMapping);
		//inputManager.setCursorVisible(dragToRotate);
		
		//TODO support Joystick
	}
	
	/**
     * Unregisters the FlyByCamera from the event Dispatcher.
     */
	public function unregisterWithInput(inputManager:InputManager):Void
	{
		if (inputManager == null)
			return;
			
		for (i in 0..._inputMapping.length)
		{
			inputManager.deleteTrigger(_inputMapping[i], _inputTriggers[i]);
		}
		_inputMapping = null;
		_inputTriggers = null;

		inputManager.removeListener(this);
	}
	
	public function dispose():Void
	{
		if(inputManager != null)
			unregisterWithInput(inputManager);
		inputManager = null;
		this.cam = null;
	}

	private static var left:Vector3f = new Vector3f();
	private static var up:Vector3f = new Vector3f();
	private static var dir:Vector3f = new Vector3f();
	private static var q:Quaternion = new Quaternion();
	private static var mat:Matrix3f = new Matrix3f();
	private function rotateCamera(value:Float, axis:Vector3f):Void
	{
		if (dragToRotate && !canRotate)
		{
			return;
		}
		
		mat.fromAngleNormalAxis(rotationSpeed * value, axis);

		cam.getUp(up);
		cam.getLeft(left);
		cam.getDirection(dir);

		mat.multVec(up, up);
		mat.multVec(left, left);
		mat.multVec(dir, dir);

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

		var fovY:Float = Math.atan(h / near) / (FastMath.DEG_TO_RAD * .5);
		
		var newFovY:Float = fovY + value * 0.1 * zoomSpeed;
		if (newFovY > 0)
		{
            // Don't let the FOV go zero or negative.
            fovY = newFovY;
        }
		
		h = Math.tan(fovY * FastMath.DEG_TO_RAD * .5) * near;
		w = h * aspect;

		cam.setFrustumRect(-w, w, h, -h);
	}

	private static var vel:Vector3f = new Vector3f();
	private static var pos:Vector3f = new Vector3f();
	
	private function riseCamera(value:Float):Void
	{
		vel.setTo(0, value * moveSpeed, 0);
		pos.copyFrom(cam.location);

		if (motionAllowed != null)
			motionAllowed.checkMotionAllowed(pos, vel);
		else
			pos.addLocal(vel);

		cam.setLocation(pos);
	}

	private function moveCamera(value:Float, sideways:Bool):Void
	{
		pos.copyFrom(cam.location);

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

		cam.setLocation(pos);
	}

	public function onAnalog(name:String, value:Float, tpf:Float):Void
	{
		if (!enabled)
			return;
			
		switch (name)
		{
			case CameraInput.FLYCAM_LEFT:
				rotateCamera(-value, initialUpVec);
			case CameraInput.FLYCAM_RIGHT:
				rotateCamera(value, initialUpVec);
			case CameraInput.FLYCAM_UP:
				rotateCamera(-value * (invertY ? -1 : 1), cam.getLeft());
			case CameraInput.FLYCAM_DOWN:
				rotateCamera(value * (invertY ? -1 : 1), cam.getLeft());
			case CameraInput.FLYCAM_FORWARD:
				moveCamera(value, false);
			case CameraInput.FLYCAM_BACKWARD:
				moveCamera(-value, false);
			case CameraInput.FLYCAM_STRAFELEFT:
				moveCamera(value, true);
			case CameraInput.FLYCAM_STRAFERIGHT:
				moveCamera(-value, true);
			case CameraInput.FLYCAM_RISE:
				riseCamera(value);
			case CameraInput.FLYCAM_LOWER:
				riseCamera(-value);
			case CameraInput.FLYCAM_ZOOMIN:
				zoomCamera(value);
			case CameraInput.FLYCAM_ZOOMOUT:
				zoomCamera(-value);
		}
	}

	/**
	 * Called when an input to which this listener is registered to is invoked.
	 *
	 * @param name The name of the mapping that was invoked
	 * @param isPressed True if the action is "pressed", false otherwise
	 * @param tpf The time per frame value.
	 */
	public function onAction(name:String, isPressed:Bool, tpf:Float):Void
	{
		if (!enabled)
			return;

		if (name == CameraInput.FLYCAM_ROTATEDRAG && dragToRotate)
		{
			canRotate = isPressed;
			//inputManager.setCursorVisible(!value);
		}
		else if (name == CameraInput.FLYCAM_INVERTY)
		{
            // Toggle on the up.
            if ( !isPressed )
			{  
                invertY = !invertY;
            }
        } 
	}
}

