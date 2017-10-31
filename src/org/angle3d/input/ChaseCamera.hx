package org.angle3d.input;


import org.angle3d.input.controls.ActionListener;
import org.angle3d.input.controls.AnalogListener;
import org.angle3d.input.controls.MouseAxisTrigger;
import org.angle3d.input.controls.MouseButtonTrigger;
import org.angle3d.input.controls.Trigger;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.Camera;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.scene.Spatial;
import org.angle3d.scene.control.Control;


/**
 * A camera that follows a spatial and can turn around it by dragging the mouse
 */
class ChaseCamera implements ActionListener implements AnalogListener implements Control
{
	private var target:Spatial;
	private var minVerticalRotation:Float = 0.0;
	private var maxVerticalRotation:Float = Math.PI / 2;
	private var minDistance:Float = 1.0;
	private var maxDistance:Float = 40.0;
	private var distance:Float = 20;
	private var rotationSpeed:Float = 1.0;
	private var rotation:Float = 0;
	private var trailingRotationInertia:Float = 0.05;
	private var zoomSensitivity:Float = 2;
	private var rotationSensitivity:Float = 5;
	private var chasingSensitivity:Float = 5;
	private var trailingSensitivity:Float = 0.5;
	private var vRotation:Float = Math.PI / 6;
	private var smoothMotion:Bool = false;
	private var trailingEnabled:Bool = true;
	private var rotationLerpFactor:Float = 0;
	private var trailingLerpFactor:Float = 0;
	private var rotating:Bool = false;
	private var vRotating:Bool = false;
	private var targetRotation:Float = 0;
	private var inputManager:InputManager;
	private var initialUpVec:Vector3f;
	private var targetVRotation:Float = Math.PI / 6;
	private var vRotationLerpFactor:Float = 0;
	private var targetDistance:Float = 20;
	private var distanceLerpFactor:Float = 0;
	private var zooming:Bool = false;
	private var trailing:Bool = false;
	private var chasing:Bool = false;
	private var veryCloseRotation:Bool = true;
	private var canRotate:Bool;
	private var offsetDistance:Float = 0.002;
	private var prevPos:Vector3f;
	private var targetMoves:Bool = false;
	private var _enabled:Bool = true;
	private var cam:Camera = null;
	private var targetDir:Vector3f;
	private var previousTargetRotation:Float;
	private var pos:Vector3f;
	private var targetLocation:Vector3f;
	private var dragToRotate:Bool = true;
	private var lookAtOffset:Vector3f;
	private var leftClickRotate:Bool = true;
	private var rightClickRotate:Bool = true;
	private var temp:Vector3f;
	private var invertYaxis:Bool = false;
	private var invertXaxis:Bool = false;
	private var hideCursorOnRotate:Bool = false;
	private var zoomin:Bool;
	private var _triggers:Array<Trigger>;
	private var _inputs:Array<String>;

	/**
	 * Constructs the chase camera, and registers inputs
	 * @param cam the application camera
	 * @param target the spatial to follow
	 * @param inputManager the inputManager of the application to register inputs
	 */
	public function new(cam:Camera, target:Spatial, inputManager:InputManager)
	{
		targetDir = new Vector3f();
		pos = new Vector3f();
		targetLocation = new Vector3f(0, 0, 0);
		lookAtOffset = new Vector3f(0, 0, 0);
		temp = new Vector3f(0, 0, 0);

		this.cam = cam;
		initialUpVec = cam.getUp().clone();

		this.target = target;
		this.target.addControl(this);

		registerWithInput(inputManager);
	}
	
	public function dispose():Void
	{
		if (target != null)
		{
			target.removeControl(this);
			target = null;
		}
		if(inputManager != null)
			unregisterWithInput(inputManager);
		inputManager = null;
		this.cam = null;
	}

	public function onAnalog(name:String, value:Float, tpf:Float):Void
	{
		switch (name)
		{
			case CameraInput.CHASECAM_MOVELEFT:
				rotateCamera(-value);
			case CameraInput.CHASECAM_MOVERIGHT:
				rotateCamera(value);
			case CameraInput.CHASECAM_UP:
				vRotateCamera(value);
			case CameraInput.CHASECAM_DOWN:
				vRotateCamera(-value);
			case CameraInput.CHASECAM_ZOOMIN:
				zoomCamera(-value);
				if (zoomin == false)
				{
					distanceLerpFactor = 0;
				}
				zoomin = true;
			case CameraInput.CHASECAM_ZOOMOUT:
				zoomCamera(value);
				if (zoomin)
				{
					distanceLerpFactor = 0;
				}
				zoomin = false;
		}
	}

	public function onAction(name:String, keyPressed:Bool, tpf:Float):Void
	{
		if (dragToRotate)
		{
			if (name == CameraInput.CHASECAM_TOGGLEROTATE && _enabled)
			{
				if (keyPressed)
				{
					canRotate = true;
					if (hideCursorOnRotate)
						inputManager.setCursorVisible(false);
				}
				else
				{
					canRotate = false;
					if (hideCursorOnRotate)
						inputManager.setCursorVisible(true);
				}
			}
		}
	}

	/**
	 * Registers the FlyByCamera to receive input events from the provided
	 * Dispatcher.
	 * @param dispacher
	 */
	public function registerWithInput(inputManager:InputManager):Void
	{
		this.inputManager = inputManager;

		_inputs = Vector.ofArray([
			CameraInput.CHASECAM_DOWN,
			CameraInput.CHASECAM_UP,
			CameraInput.CHASECAM_ZOOMIN,
			CameraInput.CHASECAM_ZOOMOUT,
			CameraInput.CHASECAM_MOVELEFT,
			CameraInput.CHASECAM_MOVERIGHT,
			CameraInput.CHASECAM_TOGGLEROTATE,
			CameraInput.CHASECAM_TOGGLEROTATE]);
			
		_triggers = new Array<Trigger>();
		_triggers.push(new MouseAxisTrigger(MouseInput.AXIS_Y, !invertYaxis));
		_triggers.push(new MouseAxisTrigger(MouseInput.AXIS_Y, invertYaxis));
		_triggers.push(new MouseAxisTrigger(MouseInput.AXIS_WHEEL, false));
		_triggers.push(new MouseAxisTrigger(MouseInput.AXIS_WHEEL, true));
		_triggers.push(new MouseAxisTrigger(MouseInput.AXIS_X, !invertXaxis));
		_triggers.push(new MouseAxisTrigger(MouseInput.AXIS_X, invertXaxis));
		_triggers.push(new MouseButtonTrigger(MouseInput.BUTTON_LEFT));
		_triggers.push(new MouseButtonTrigger(MouseInput.BUTTON_RIGHT));
		
		for (i in 0..._inputs.length)
		{
			inputManager.addTrigger(_inputs[i], _triggers[i]);
		}

		inputManager.addListener(this, _inputs);
	}

	public function unregisterWithInput(inputManager:InputManager):Void
	{
		for (i in 0..._inputs.length)
		{
			inputManager.deleteTrigger(_inputs[i], _triggers[i]);
		}
		_inputs = null;
		_triggers = null;

		inputManager.removeListener(this);
	}
	
	/**
	 * Sets custom triggers for toggleing the rotation of the cam
	 * deafult are
	 * `new MouseButtonTrigger(MouseInput.BUTTON_LEFT)`  left mouse button
	 * `new MouseButtonTrigger(MouseInput.BUTTON_RIGHT)`  right mouse button
	 * @param triggers
	 */
	public function setToggleRotationTrigger(triggers:Array<Trigger>):Void
	{
		inputManager.deleteMapping(CameraInput.CHASECAM_TOGGLEROTATE);
		inputManager.addMapping(CameraInput.CHASECAM_TOGGLEROTATE, triggers);
		var inputs:Array<String> = Vector.ofArray([CameraInput.CHASECAM_TOGGLEROTATE]);
		inputManager.addListener(this, inputs);
	}

	/**
	 * Sets custom triggers for zomming in the cam
	 * default is
	 * `new MouseAxisTrigger(MouseInput.AXIS_WHEEL, true)`  mouse wheel up
	 * @param triggers
	 */
	public function setZoomInTrigger(triggers:Array<Trigger>):Void
	{
		inputManager.deleteMapping(CameraInput.CHASECAM_ZOOMIN);
		inputManager.addMapping(CameraInput.CHASECAM_ZOOMIN, triggers);
		var inputs:Array<String> = Vector.ofArray([CameraInput.CHASECAM_ZOOMIN]);
		inputManager.addListener(this, inputs);
	}

	/**
	 * Sets custom triggers for zomming out the cam
	 * default is
	 * `new MouseAxisTrigger(MouseInput.AXIS_WHEEL, false)`  mouse wheel down
	 * @param triggers
	 */
	public function setZoomOutTrigger(triggers:Array<Trigger>):Void
	{
		inputManager.deleteMapping(CameraInput.CHASECAM_ZOOMOUT);
		inputManager.addMapping(CameraInput.CHASECAM_ZOOMOUT, triggers);

		var inputs:Array<String> = Vector.ofArray([CameraInput.CHASECAM_ZOOMOUT]);
		inputManager.addListener(this, inputs);
	}

	private function computePosition():Void
	{
		var hDistance:Float = (distance) * Math.sin((Math.PI / 2) - vRotation);
		pos.setTo(hDistance * Math.cos(rotation), (distance) * Math.sin(vRotation), hDistance * Math.sin(rotation));
		pos.addLocal(target.getWorldTranslation());
	}

	//rotate the camera around the target_on the horizontal plane
	private function rotateCamera(value:Float):Void
	{
		if (!canRotate || !_enabled)
		{
			return;
		}

		rotating = true;
		targetRotation += value * rotationSpeed;
	}

	//move the camera toward or away the target
	private function zoomCamera(value:Float):Void
	{
		if (!_enabled)
		{
			return;
		}

		zooming = true;
		targetDistance += value * zoomSensitivity;
		targetDistance = FastMath.clamp(targetDistance, minDistance, maxDistance);

		if (veryCloseRotation)
		{
			if ((targetVRotation < minVerticalRotation) && (targetDistance > (minDistance + 1.0)))
			{
				targetVRotation = minVerticalRotation;
			}
		}
	}

	//rotate the camera around the target_on the vertical plane
	private function vRotateCamera(value:Float):Void
	{
		if (!canRotate || !_enabled)
		{
			return;
		}

		vRotating = true;
		var lastGoodRot:Float = targetVRotation;
		targetVRotation += value * rotationSpeed;
		if (targetVRotation > maxVerticalRotation)
		{
			targetVRotation = lastGoodRot;
		}

		if (veryCloseRotation)
		{
			if ((targetVRotation < minVerticalRotation) && (targetDistance > (minDistance + 1.0)))
			{
				targetVRotation = minVerticalRotation;
			}
			else if (targetVRotation < -FastMath.DEG_TO_RAD * 90)
			{
				targetVRotation = lastGoodRot;
			}
		}
		else
		{
			if ((targetVRotation < minVerticalRotation))
			{
				targetVRotation = lastGoodRot;
			}
		}
	}

	/**
	 * Updates the camera, should only be called internally
	 */
	private function updateCamera(tpf:Float):Void
	{
		if (_enabled)
		{
			targetLocation.copyFrom(target.getWorldTranslation());
			targetLocation.addLocal(lookAtOffset);
			if (smoothMotion)
			{
				//computation of target_direction
				targetDir.copyFrom(targetLocation);
				targetDir.subtractLocal(prevPos);

				var dist:Float = targetDir.length;

				//Low pass filtering on the target postition to aVoid shaking when physics are enabled.
				if (offsetDistance < dist)
				{
					//target moves, start chasing.
					chasing = true;
					//target moves, start trailing if it has to.
					if (trailingEnabled)
					{
						trailing = true;
					}
					//target moves...
					targetMoves = true;
				}
				else
				{
					//if target was moving, we compute a slight offsetin rotation to aVoid a rought stop of the cam
					//We do not if the player is rotationg the cam
					if (targetMoves && !canRotate)
					{
						if (targetRotation - rotation > trailingRotationInertia)
						{
							targetRotation = rotation + trailingRotationInertia;
						}
						else if (targetRotation - rotation < -trailingRotationInertia)
						{
							targetRotation = rotation - trailingRotationInertia;
						}
					}
					//Target stops
					targetMoves = false;
				}

				//the user is rotating the cam by dragging the mouse
				if (canRotate)
				{
					//reseting the trailing lerp factor
					trailingLerpFactor = 0;
					//stop trailing user has the control                  
					trailing = false;
				}

				if (trailingEnabled && trailing)
				{
					if (targetMoves)
					{
						//computation if the inverted direction of the target
						var a:Vector3f = targetDir.negate();
						a.normalizeLocal();
						//the x unit vector
						var b:Vector3f = Vector3f.UNIT_X;
						//2d is good enough
						a.y = 0;
						//computation of the rotation angle between the x axis and the trail
						if (targetDir.z > 0)
						{
							targetRotation = FastMath.TWO_PI - Math.acos(a.dot(b));
						}
						else
						{
							targetRotation = Math.acos(a.dot(b));
						}

						if (targetRotation - rotation > Math.PI || targetRotation - rotation < -Math.PI)
						{
							targetRotation -= FastMath.TWO_PI;
						}

						//if there is an important change in the direction while trailing reset_of the lerp factor to aVoid jumpy movements
						if (targetRotation != previousTargetRotation && FastMath.abs(targetRotation - previousTargetRotation) > Math.PI / 8)
						{
							trailingLerpFactor = 0;
						}
						previousTargetRotation = targetRotation;
					}
					//computing lerp factor
					trailingLerpFactor = Math.min(trailingLerpFactor + tpf * tpf * trailingSensitivity, 1);
					//computing rotation by linear interpolation
					rotation = FastMath.interpolateLinearFloat(rotation, targetRotation, trailingLerpFactor);

					//if the rotation is near the target_rotation we're good, that's over
					if (FastMath.nearEqual(targetRotation, rotation, 0.01))
					{
						trailing = false;
						trailingLerpFactor = 0;
					}
				}

				//linear interpolation of the distance while chasing
				if (chasing)
				{
					temp.copyFrom(targetLocation);
					temp.subtractLocal(cam.location);
					distance = temp.length;
					distanceLerpFactor = Math.min(distanceLerpFactor + (tpf * tpf * chasingSensitivity * 0.05), 1);
					distance = FastMath.interpolateLinearFloat(distance, targetDistance, distanceLerpFactor);
					if (FastMath.nearEqual(targetDistance, distance, 0.01))
					{
						distanceLerpFactor = 0;
						chasing = false;
					}
				}

				//linear interpolation of the distance while zooming
				if (zooming)
				{
					distanceLerpFactor = Math.min(distanceLerpFactor + (tpf * tpf * zoomSensitivity), 1);
					distance = FastMath.interpolateLinearFloat(distance, targetDistance, distanceLerpFactor);
					if (FastMath.nearEqual(targetDistance, distance, 0.1))
					{
						zooming = false;
						distanceLerpFactor = 0;
					}
				}

				//linear interpolation of the rotation while rotating horizontally
				if (rotating)
				{
					rotationLerpFactor = Math.min(rotationLerpFactor + tpf * tpf * rotationSensitivity, 1);
					rotation = FastMath.interpolateLinearFloat(rotation, targetRotation, rotationLerpFactor);
					if (FastMath.nearEqual(targetRotation, rotation, 0.01))
					{
						rotating = false;
						rotationLerpFactor = 0;
					}
				}

				//linear interpolation of the rotation while rotating vertically
				if (vRotating)
				{
					vRotationLerpFactor = Math.min(vRotationLerpFactor + tpf * tpf * rotationSensitivity, 1);
					vRotation = FastMath.interpolateLinearFloat(vRotation, targetVRotation, vRotationLerpFactor);
					if (FastMath.nearEqual(targetVRotation, vRotation, 0.01))
					{
						vRotating = false;
						vRotationLerpFactor = 0;
					}
				}
				//computing the position
				computePosition();
				//setting the position at last
				pos.addLocal(lookAtOffset);
				cam.location = pos;
			}
			else
			{
				//easy no smooth motion
				vRotation = targetVRotation;
				rotation = targetRotation;
				distance = targetDistance;
				computePosition();
				pos.addLocal(lookAtOffset);
				cam.location = pos;
			}


			//keeping track on the previous position of the target
			prevPos.copyFrom(targetLocation);

			//the cam looks at the target_           
			cam.lookAt(targetLocation, initialUpVec);
		}
	}

	/**
	 * Return the enabled/disabled state of the camera
	 * @return true if the camera is enabled
	 */
	public function isEnabled():Bool
	{
		return _enabled;
	}

	/**
	 * Enable or disable the camera
	 * @param enabled true to enable
	 */
	public function setEnabled(value:Bool):Void
	{
		_enabled = value;
		if (!_enabled)
		{
			canRotate = false; // reset_this flag in-case it was on before
		}
	}

	/**
	 * Returns the max zoom distance of the camera (default is 40)
	 * @return maxDistance
	 */
	public function getMaxDistance():Float
	{
		return maxDistance;
	}

	/**
	 * Sets the max zoom distance of the camera (default is 40)
	 * @param maxDistance
	 */
	public function setMaxDistance(maxDistance:Float):Void
	{
		this.maxDistance = maxDistance;
		if (maxDistance < distance)
		{
			zoomCamera(maxDistance - distance);
		}
	}

	/**
	 * Returns the min zoom distance of the camera (default is 1)
	 * @return minDistance
	 */
	public function getMinDistance():Float
	{
		return minDistance;
	}

	/**
	 * Sets the min zoom distance of the camera (default is 1)
	 * @return minDistance
	 */
	public function setMinDistance(minDistance:Float):Void
	{
		this.minDistance = minDistance;
		if (minDistance > distance)
		{
			zoomCamera(distance - minDistance);
		}
	}

	/**
	 * clone this camera for a spatial
	 * @param spatial
	 * @return
	 */
	public function cloneForSpatial(spatial:Spatial):Control
	{
		var cc:ChaseCamera = new ChaseCamera(cam, spatial, inputManager);
		cc.setMaxDistance(getMaxDistance());
		cc.setMinDistance(getMinDistance());
		return cc;
	}
	
	/**
	 * Sets the spacial for the camera control, should only be used internally
	 * @param spatial
	 */
	public function setSpatial(value:Spatial):Void
	{
		this.target = value;
		if (target != null)
		{
			computePosition();
			prevPos = target.getWorldTranslation().clone();
			cam.location = pos;
		}
	}

	public function getSpatial():Spatial
	{
		return this.target;
	}

	/**
	 * update the camera control, should only be used internally
	 * @param tpf
	 */
	public function update(tpf:Float):Void
	{
		updateCamera(tpf);
	}

	/**
	 * renders the camera control, should only be used internally
	 * @param rm
	 * @param vp
	 */
	public function render(rm:RenderManager, vp:ViewPort):Void
	{
		//nothing to render
	}

	/**
	 * returns the maximal vertical rotation angle of the camera around the target
	 * @return
	 */
	public function getMaxVerticalRotation():Float
	{
		return maxVerticalRotation;
	}

	/**
	 * sets the maximal vertical rotation angle of the camera around the target_default is Pi/2;
	 * @param maxVerticalRotation
	 */
	public function setMaxVerticalRotation(maxVerticalRotation:Float):Void
	{
		this.maxVerticalRotation = maxVerticalRotation;
	}

	/**
	 * returns the minimal vertical rotation angle of the camera around the target
	 * @return
	 */
	public function getMinVerticalRotation():Float
	{
		return minVerticalRotation;
	}

	/**
	 * sets the minimal vertical rotation angle of the camera around the target_default is 0;
	 * @param minHeight
	 */
	public function setMinVerticalRotation(minHeight:Float):Void
	{
		this.minVerticalRotation = minHeight;
	}

	/**
	 * returns true is smmoth motion is enabled for this chase camera
	 * @return
	 */
	public function isSmoothMotion():Bool
	{
		return smoothMotion;
	}

	/**
	 * Enables smooth motion for this chase camera
	 * @param smoothMotion
	 */
	public function setSmoothMotion(smoothMotion:Bool):Void
	{
		this.smoothMotion = smoothMotion;
	}

	/**
	 * returns the chasing sensitivity
	 * @return
	 */
	public function getChasingSensitivity():Float
	{
		return chasingSensitivity;
	}

	/**
	 *
	 * Sets the chasing sensitivity, the lower the value the slower the camera will follow the target when it moves
	 * default is 5
	 * Only has an effect if smoothMotion is set to true and trailing is enabled
	 * @param chasingSensitivity
	 */
	public function setChasingSensitivity(chasingSensitivity:Float):Void
	{
		this.chasingSensitivity = chasingSensitivity;
	}

	/**
	 * Returns the rotation sensitivity
	 * @return
	 */
	public function getRotationSensitivity():Float
	{
		return rotationSensitivity;
	}

	/**
	 * Sets the rotation sensitivity, the lower the value the slower the camera will rotates around the target_when draging with the mouse
	 * default is 5, values over 5 should have no effect.
	 * If you want a significant slow down try values below 1.
	 * Only has an effect if smoothMotion is set to true
	 * @param rotationSensitivity
	 */
	public function setRotationSensitivity(rotationSensitivity:Float):Void
	{
		this.rotationSensitivity = rotationSensitivity;
	}

	/**
	 * returns true if the trailing is enabled
	 * @return
	 */
	public function isTrailingEnabled():Bool
	{
		return trailingEnabled;
	}

	/**
	 * Enable the camera trailing : The camera smoothly go in the targets trail when it moves.
	 * Only has an effect if smoothMotion is set to true
	 * @param trailingEnabled
	 */
	public function setTrailingEnabled(trailingEnabled:Bool):Void
	{
		this.trailingEnabled = trailingEnabled;
	}

	/**
	 *
	 * returns the trailing rotation inertia
	 * @return
	 */
	public function getTrailingRotationInertia():Float
	{
		return trailingRotationInertia;
	}

	/**
	 * Sets the trailing rotation inertia : default is 0.1. This prevent the camera to roughtly stop when the target_stops moving
	 * before the camera reached the trail position.
	 * Only has an effect if smoothMotion is set to true and trailing is enabled
	 * @param trailingRotationInertia
	 */
	public function setTrailingRotationInertia(trailingRotationInertia:Float):Void
	{
		this.trailingRotationInertia = trailingRotationInertia;
	}

	/**
	 * returns the trailing sensitivity
	 * @return
	 */
	public function getTrailingSensitivity():Float
	{
		return trailingSensitivity;
	}

	/**
	 * Only has an effect if smoothMotion is set to true and trailing is enabled
	 * Sets the trailing sensitivity, the lower the value, the slower the camera will go in the target trail when it moves.
	 * default is 0.5;
	 * @param trailingSensitivity
	 */
	public function setTrailingSensitivity(trailingSensitivity:Float):Void
	{
		this.trailingSensitivity = trailingSensitivity;
	}

	/**
	 * returns the zoom sensitivity
	 * @return
	 */
	public function getZoomSensitivity():Float
	{
		return zoomSensitivity;
	}

	/**
	 * Sets the zoom sensitivity, the lower the value, the slower the camera will zoom in and out.
	 * default is 5.
	 * @param zoomSensitivity
	 */
	public function setZoomSensitivity(zoomSensitivity:Float):Void
	{
		this.zoomSensitivity = zoomSensitivity;
	}


	/**
	 * Returns the rotation speed when the mouse is moved.
	 *
	 * @return the rotation speed when the mouse is moved.
	 */
	public function getRotationSpeed():Float
	{
		return rotationSpeed;
	}

	/**
	 * Sets the rotate amount when user moves his mouse, the lower the value,
	 * the slower the camera will rotate. default is 1.
	 *
	 * @param rotationSpeed Rotation speed on mouse movement, default is 1.
	 */
	public function setRotationSpeed(rotationSpeed:Float):Void
	{
		this.rotationSpeed = rotationSpeed;
	}

	/**
	 * Sets the default distance at start of applicaiton
	 * @param defaultDistance
	 */
	public function setDefaultDistance(defaultDistance:Float):Void
	{
		distance = defaultDistance;
		targetDistance = distance;
	}

	/**
	 * sets the default horizontal rotation of the camera at start of the application
	 * @param angle
	 */
	public function setDefaultHorizontalRotation(angle:Float):Void
	{
		rotation = angle;
		targetRotation = angle;
	}

	/**
	 * sets the default vertical rotation of the camera at start of the application
	 * @param angle
	 */
	public function setDefaultVerticalRotation(angle:Float):Void
	{
		vRotation = angle;
		targetVRotation = angle;
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
	 * @param dragToRotate When true, the user must hold the mouse button
	 * and drag over the screen to rotate the camera, and the cursor is
	 * visible until dragged. Otherwise, the cursor is invisible at all times
	 * and holding the mouse button is not needed to rotate the camera.
	 * This feature is disabled by default.
	 */
	public function setDragToRotate(dragToRotate:Bool):Void
	{
		this.dragToRotate = dragToRotate;
		this.canRotate = !dragToRotate;
		//inputManager.setCursorVisible(dragToRotate);
	}

	/**
	 * return the current distance from the camera to the target
	 * @return
	 */
	public function getDistanceToTarget():Float
	{
		return distance;
	}

	/**
	 * returns the current horizontal rotation around the target_in radians
	 * @return
	 */
	public function getHorizontalRotation():Float
	{
		return rotation;
	}

	/**
	 * returns the current vertical rotation around the target_in radians.
	 * @return
	 */
	public function getVerticalRotation():Float
	{
		return vRotation;
	}

	/**
	 * returns the offsetfrom the target's position where the camera looks at
	 * @return
	 */
	public function getLookAtOffset():Vector3f
	{
		return lookAtOffset;
	}

	/**
	 * Sets the offsetfrom the target's position where the camera looks at
	 * @param lookAtOffset
	 */
	public function setLookAtOffset(lookAtOffset:Vector3f):Void
	{
		this.lookAtOffset = lookAtOffset;
	}

	/**
	 * Sets the up vector of the camera used for the lookAt on the target
	 * @param up
	 */
	public function setUpVector(up:Vector3f):Void
	{
		initialUpVec = up;
	}

	/**
	 * Returns the up vector of the camera used for the lookAt on the target
	 * @return
	 */
	public function getUpVector():Vector3f
	{
		return initialUpVec;
	}

	/**
	 * invert the vertical axis movement of the mouse
	 * @param invertYaxis
	 */
	public function setInvertVerticalAxis(invertYaxis:Bool):Void
	{
		this.invertYaxis = invertYaxis;

		inputManager.deleteMapping(CameraInput.CHASECAM_DOWN);
		inputManager.deleteMapping(CameraInput.CHASECAM_UP);

		inputManager.addTrigger(CameraInput.CHASECAM_DOWN, new MouseAxisTrigger(MouseInput.AXIS_Y, !invertYaxis));
		inputManager.addTrigger(CameraInput.CHASECAM_UP, new MouseAxisTrigger(MouseInput.AXIS_Y, invertYaxis));

		var inputs:Array<String> = Vector.ofArray([CameraInput.CHASECAM_DOWN, CameraInput.CHASECAM_UP]);
		inputManager.addListener(this, inputs);
	}

	/**
	 * invert the Horizontal axis movement of the mouse
	 * @param invertYaxis
	 */
	public function setInvertHorizontalAxis(invertXaxis:Bool):Void
	{
		this.invertXaxis = invertXaxis;
		inputManager.deleteMapping(CameraInput.CHASECAM_MOVELEFT);
		inputManager.deleteMapping(CameraInput.CHASECAM_MOVERIGHT);

		inputManager.addTrigger(CameraInput.CHASECAM_MOVELEFT, new MouseAxisTrigger(MouseInput.AXIS_X, !invertXaxis));
		inputManager.addTrigger(CameraInput.CHASECAM_MOVERIGHT, new MouseAxisTrigger(MouseInput.AXIS_X, invertXaxis));

		var inputs:Array<String> = Vector.ofArray([CameraInput.CHASECAM_MOVELEFT, CameraInput.CHASECAM_MOVERIGHT]);
		inputManager.addListener(this, inputs);
	}

	public function clone():Control
	{
		//todo
		return null;
	}
}

