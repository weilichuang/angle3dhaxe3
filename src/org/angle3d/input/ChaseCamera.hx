package org.angle3d.input;

import flash.Vector;
import org.angle3d.input.controls.ActionListener;
import org.angle3d.input.controls.AnalogListener;
import org.angle3d.input.controls.MouseAxisTrigger;
import org.angle3d.input.controls.MouseButtonTrigger;
import org.angle3d.input.controls.Trigger;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.Camera3D;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.scene.Spatial;
import org.angle3d.scene.control.Control;


/**
 * A camera that follows a spatial and can turn around it by dragging the mouse
 * @author nehon
 */
class ChaseCamera implements ActionListener implements AnalogListener implements Control
{
	private var target:Spatial;
	private var minVerticalRotation:Float;
	private var maxVerticalRotation:Float;
	private var minDistance:Float;
	private var maxDistance:Float;
	private var distance:Float;
	private var zoomSpeed:Float;
	private var rotationSpeed:Float;
	private var rotation:Float;
	private var trailingRotationInertia:Float;
	private var zoomSensitivity:Float;
	private var rotationSensitivity:Float;
	private var chasingSensitivity:Float;
	private var trailingSensitivity:Float;
	private var vRotation:Float;
	private var smoothMotion:Bool;
	private var trailingEnabled:Bool;
	private var rotationLerpFactor:Float;
	private var trailingLerpFactor:Float;
	private var rotating:Bool;
	private var vRotating:Bool;
	private var targetRotation:Float;
	private var inputManager:InputManager;
	private var initialUpVec:Vector3f;
	private var targetVRotation:Float;
	private var vRotationLerpFactor:Float;
	private var targetDistance:Float;
	private var distanceLerpFactor:Float;
	private var zooming:Bool;
	private var trailing:Bool;
	private var chasing:Bool;
	private var veryCloseRotation:Bool;
	private var canRotate:Bool;
	private var offsetDistance:Float;
	private var prevPos:Vector3f;
	private var targetMoves:Bool;
	private var _enabled:Bool;
	private var cam:Camera3D;
	private var targetDir:Vector3f;
	private var previousTargetRotation:Float;
	private var pos:Vector3f;
	private var targetLocation:Vector3f;
	private var dragToRotate:Bool;
	private var lookAtOffset:Vector3f;
	private var leftClickRotate:Bool;
	private var rightClickRotate:Bool;
	private var temp:Vector3f;
	private var invertYaxis:Bool;
	private var invertXaxis:Bool;
	private var hideCursorOnRotate:Bool;

	private static inline var ChaseCamDown:String = "ChaseCamDown";
	private static inline var ChaseCamUp:String = "ChaseCamUp";
	private static inline var ChaseCamZoomIn:String = "ChaseCamZoomIn";
	private static inline var ChaseCamZoomOut:String = "ChaseCamZoomOut";
	private static inline var ChaseCamMoveLeft:String = "ChaseCamMoveLeft";
	private static inline var ChaseCamMoveRight:String = "ChaseCamMoveRight";
	private static inline var ChaseCamToggleRotate:String = "ChaseCamToggleRotate";

	/**
	 * Constructs the chase camera, and registers inputs
	 * @param cam the application camera
	 * @param target_the spatial to follow
	 * @param inputManager the inputManager of the application to register inputs
	 */
	public function new(cam:Camera3D, target:Spatial, inputManager:InputManager)
	{
		_init();

		this.cam = cam;
		initialUpVec = cam.getUp().clone();

		this.target = target;
		this.target.addControl(this);

		registerWithInput(inputManager);
	}

	private function _init():Void
	{
		minVerticalRotation = 0.00;
		maxVerticalRotation = Math.PI / 2;

		minDistance = 1.0;
		maxDistance = 40.0;
		distance = 20;

		zoomSpeed = 2;
		rotationSpeed = 1.0;

		rotation = 0;
		trailingRotationInertia = 0.05;

		zoomSensitivity = 5;
		rotationSensitivity = 5;
		chasingSensitivity = 5;
		trailingSensitivity = 0.5;
		vRotation = Math.PI / 6;
		smoothMotion = false;
		trailingEnabled = true;

		rotationLerpFactor = 0;
		trailingLerpFactor = 0;

		rotating = false;
		vRotating = false;
		targetRotation = rotation;

		targetVRotation = vRotation;
		vRotationLerpFactor = 0;
		targetDistance = distance;
		distanceLerpFactor = 0;

		zooming = false;
		trailing = false;
		chasing = false;

		offsetDistance = 0.002;

		targetMoves = false;
		_enabled = true;

		cam = null;

		targetDir = new Vector3f();
		pos = new Vector3f();
		targetLocation = new Vector3f(0, 0, 0);
		dragToRotate = false;
		lookAtOffset = new Vector3f(0, 0, 0);
		leftClickRotate = true;
		rightClickRotate = true;
		temp = new Vector3f(0, 0, 0);

		invertYaxis = false;
		invertXaxis = false;

		hideCursorOnRotate = true;
	}

	private var zoomin:Bool;

	public function onAnalog(name:String, value:Float, tpf:Float):Void
	{
		switch (name)
		{
			case ChaseCamMoveLeft:
				rotateCamera(-value);
			case ChaseCamMoveRight:
				rotateCamera(value);
			case ChaseCamUp:
				vRotateCamera(value);
			case ChaseCamDown:
				vRotateCamera(-value);
			case ChaseCamZoomIn:
				zoomCamera(-value);
				if (zoomin == false)
				{
					distanceLerpFactor = 0;
				}
				zoomin = true;
			case ChaseCamZoomOut:
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
			if (name == ChaseCamToggleRotate && _enabled)
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

		var inputs:Array<String> = [ChaseCamToggleRotate,
			ChaseCamDown,
			ChaseCamUp,
			ChaseCamMoveLeft,
			ChaseCamMoveRight,
			ChaseCamZoomIn,
			ChaseCamZoomOut];

		inputManager.addSingleMapping(ChaseCamDown, new MouseAxisTrigger(MouseInput.AXIS_Y, !invertYaxis));
		inputManager.addSingleMapping(ChaseCamUp, new MouseAxisTrigger(MouseInput.AXIS_Y, invertYaxis));

		inputManager.addSingleMapping(ChaseCamZoomIn, new MouseAxisTrigger(MouseInput.AXIS_WHEEL, false));
		inputManager.addSingleMapping(ChaseCamZoomOut, new MouseAxisTrigger(MouseInput.AXIS_WHEEL, true));

		inputManager.addSingleMapping(ChaseCamMoveLeft, new MouseAxisTrigger(MouseInput.AXIS_X, !invertXaxis));
		inputManager.addSingleMapping(ChaseCamMoveRight, new MouseAxisTrigger(MouseInput.AXIS_X, invertXaxis));

		inputManager.addSingleMapping(ChaseCamToggleRotate, new MouseButtonTrigger(MouseInput.BUTTON_LEFT));
		inputManager.addSingleMapping(ChaseCamToggleRotate, new MouseButtonTrigger(MouseInput.BUTTON_RIGHT));

		inputManager.addListener(this, inputs);
	}

	/**
	 * Sets custom triggers for toggleing the rotation of the cam
	 * deafult are
	 * new MouseButtonTrigger(MouseInput.BUTTON_LEFT)  left mouse button
	 * new MouseButtonTrigger(MouseInput.BUTTON_RIGHT)  right mouse button
	 * @param triggers
	 */
	public function setToggleRotationTrigger(triggers:Array<Trigger>):Void
	{
		inputManager.deleteMapping(ChaseCamToggleRotate);
		inputManager.addMapping(ChaseCamToggleRotate, triggers);
		var inputs:Array<String> = [ChaseCamToggleRotate];
		inputManager.addListener(this, inputs);
	}

	/**
	 * Sets custom triggers for zomming in the cam
	 * default is
	 * new MouseAxisTrigger(MouseInput.AXIS_WHEEL, true)  mouse wheel up
	 * @param triggers
	 */
	public function setZoomInTrigger(triggers:Array<Trigger>):Void
	{
		inputManager.deleteMapping(ChaseCamZoomIn);
		inputManager.addMapping(ChaseCamZoomIn, triggers);
		var inputs:Array<String> = [ChaseCamZoomIn];
		inputManager.addListener(this, inputs);
	}

	/**
	 * Sets custom triggers for zomming out the cam
	 * default is
	 * new MouseAxisTrigger(MouseInput.AXIS_WHEEL, false)  mouse wheel down
	 * @param triggers
	 */
	public function setZoomOutTrigger(triggers:Array<Trigger>):Void
	{
		inputManager.deleteMapping(ChaseCamZoomOut);
		inputManager.addMapping(ChaseCamZoomOut, triggers);

		var inputs:Array<String> = [ChaseCamZoomOut];
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
		targetDistance += value * zoomSpeed;
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
			else if (targetVRotation < -FastMath.DEGTORAD() * 90)
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

				//Low pass filtering on the target_postition to aVoid shaking when physics are enabled.
				if (offsetDistance < dist)
				{
					//target_moves, start chasing.
					chasing = true;
					//target_moves, start trailing if it has to.
					if (trailingEnabled)
					{
						trailing = true;
					}
					//target_moves...
					targetMoves = true;
				}
				else
				{
					//if target_was moving, we compute a slight offsetin rotation to aVoid a rought stop of the cam
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
					//Target_stops
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
						var b:Vector3f = Vector3f.X_AXIS;
						//2d is good enough
						a.y = 0;
						//computation of the rotation angle between the x axis and the trail
						if (targetDir.z > 0)
						{
							targetRotation = FastMath.TWO_PI() - Math.acos(a.dot(b));
						}
						else
						{
							targetRotation = Math.acos(a.dot(b));
						}

						if (targetRotation - rotation > Math.PI || targetRotation - rotation < -Math.PI)
						{
							targetRotation -= FastMath.TWO_PI();
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
					rotation = FastMath.lerp(rotation, targetRotation, trailingLerpFactor);

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
					distance = FastMath.lerp(distance, targetDistance, distanceLerpFactor);
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
					distance = FastMath.lerp(distance, targetDistance, distanceLerpFactor);
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
					rotation = FastMath.lerp(rotation, targetRotation, rotationLerpFactor);
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
					vRotation = FastMath.lerp(vRotation, targetVRotation, vRotationLerpFactor);
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

	public var enabled(get, set):Bool;
	/**
	 * Return the enabled/disabled state of the camera
	 * @return true if the camera is enabled
	 */
	private function get_enabled():Bool
	{
		return _enabled;
	}

	/**
	 * Enable or disable the camera
	 * @param enabled true to enable
	 */
	private function set_enabled(value:Bool):Bool
	{
		_enabled = value;
		if (!_enabled)
		{
			canRotate = false; // reset_this flag in-case it was on before
		}
		return _enabled;
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

	public var spatial(get, set):Spatial;
	/**
	 * Sets the spacial for the camera control, should only be used internally
	 * @param spatial
	 */
	private function set_spatial(value:Spatial):Spatial
	{
		this.target = value;
		if (spatial != null)
		{
			computePosition();
			prevPos = target.getWorldTranslation().clone();
			cam.location = pos;
		}
		return spatial;
	}

	private function get_spatial():Spatial
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
	 * Sets the chasing sensitivity, the lower the value the slower the camera will follow the target_when it moves
	 * default is 5
	 * Only has an effect if smoothMotion is set_to true and trailing is enabled
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
	 * Only has an effect if smoothMotion is set_to true
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
	 * Only has an effect if smoothMotion is set_to true
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
	 * Only has an effect if smoothMotion is set_to true and trailing is enabled
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
	 * Only has an effect if smoothMotion is set_to true and trailing is enabled
	 * Sets the trailing sensitivity, the lower the value, the slower the camera will go in the target_trail when it moves.
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
	 * @see FlyByCamera#setDragToRotate(Bool)
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
		inputManager.setCursorVisible(dragToRotate);
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

		inputManager.deleteMapping(ChaseCamDown);
		inputManager.deleteMapping(ChaseCamUp);

		inputManager.addSingleMapping(ChaseCamDown, new MouseAxisTrigger(MouseInput.AXIS_Y, !invertYaxis));
		inputManager.addSingleMapping(ChaseCamUp, new MouseAxisTrigger(MouseInput.AXIS_Y, invertYaxis));

		var inputs:Array<String> = [ChaseCamDown, ChaseCamUp];
		inputManager.addListener(this, inputs);
	}

	/**
	 * invert the Horizontal axis movement of the mouse
	 * @param invertYaxis
	 */
	public function setInvertHorizontalAxis(invertXaxis:Bool):Void
	{
		this.invertXaxis = invertXaxis;
		inputManager.deleteMapping(ChaseCamMoveLeft);
		inputManager.deleteMapping(ChaseCamMoveRight);

		inputManager.addSingleMapping(ChaseCamMoveLeft, new MouseAxisTrigger(MouseInput.AXIS_X, !invertXaxis));
		inputManager.addSingleMapping(ChaseCamMoveRight, new MouseAxisTrigger(MouseInput.AXIS_X, invertXaxis));

		var inputs:Array<String> = [ChaseCamMoveLeft, ChaseCamMoveRight];
		inputManager.addListener(this, inputs);
	}

	public function clone():Control
	{
		//todo
		return null;
	}
}

