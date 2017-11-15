package org.angle3d.cinematic.events;

import org.angle3d.animation.AnimationUtils;
import org.angle3d.app.LegacyApplication;
import org.angle3d.cinematic.Cinematic;
import org.angle3d.cinematic.LoopMode;
import org.angle3d.cinematic.MotionPath;
import org.angle3d.cinematic.PlayState;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.scene.control.Control;
import org.angle3d.scene.Spatial;
import org.angle3d.utils.TempVars;

/**
 * A MotionEvent is a control over the spatial that manage the position and direction of the spatial while following a motion Path
 *
 * You must first create a MotionPath and then create a MotionEvent to associate a spatial and the path.
 *
 */
class MotionEvent extends AbstractCinematicEvent implements Control {
	public var currentWayPoint(get, set):Int;
	public var directionType(get, set):DirectionType;

	private var _spatial:Spatial;

	private var _currentWayPoint:Int;
	private var currentValue:Float;

	private var direction:Vector3f;

	private var lookAt:Vector3f;
	private var upVector:Vector3f;
	private var rotation:Quaternion;
	private var _directionType:DirectionType;
	private var path:MotionPath;
	private var isControl:Bool = true;

	/**
	 * the distance traveled by the spatial on the path
	 */
	private var traveledDistance:Float = 0;

	/**
	 *
	 * @param	spatial
	 * @param	path
	 * @param	initialDuration 时间长度，秒为单位
	 * @param	loopMode
	 */
	public function new(spatial:Spatial, path:MotionPath, initialDuration:Float = 10, loopMode:LoopMode = LoopMode.Loop) {
		super(initialDuration, loopMode);

		direction = new Vector3f();
		upVector = new Vector3f(0, 1, 0);
		_directionType = DirectionType.None;
		currentValue = 0;

		_spatial = spatial;
		_spatial.addControl(this);
		this.path = path;
	}

	public function update(tpf:Float):Void {
		if (isControl) {
			internalUpdate(tpf);
		}
	}

	override public function internalUpdate(tpf:Float):Void {
		if (playState == PlayState.Playing) {
			time += tpf * speed;

			if (loopMode == LoopMode.Loop && time < 0) {
				time = initialDuration;
			}

			if ((time >= initialDuration || time < 0) && loopMode == LoopMode.DontLoop) {
				if (time >= initialDuration) {
					path.triggerWayPointReach(path.numWayPoints - 1, this);
				}
				stop();
			} else {
				time = AnimationUtils.clampWrapTime(time, initialDuration, loopMode);
				if (time < 0) {
					speed = -speed;
					time = -time;
				}
				onUpdate(tpf);
			}
		}
	}

	override public function initEvent(app:LegacyApplication, cinematic:Cinematic):Void {
		super.initEvent(app, cinematic);
		isControl = false;
	}

	override public function setTime(time:Float):Void {
		super.setTime(time);
		onUpdate(0);
	}

	override public function onUpdate(tpf:Float):Void {
		traveledDistance = path.interpolatePath(time, this, tpf);
		computeTargetDirection();
	}

	/**
	 * this method is meant to be called by the motion path only
	 * @return
	 */
	public function needsDirection():Bool {
		return _directionType == DirectionType.Path || _directionType == DirectionType.PathAndRotation;
	}

	private static var tmpQuat:Quaternion = new Quaternion();
	private function computeTargetDirection():Void {
		switch (_directionType) {
			case DirectionType.Path:
				tmpQuat.lookAt(direction, upVector);
				_spatial.setLocalRotation(tmpQuat);
			case DirectionType.LookAt:
				if (lookAt != null) {
					_spatial.lookAt(lookAt, upVector);
				}
			case DirectionType.PathAndRotation:
				if (rotation != null) {
					tmpQuat.lookAt(direction, upVector);
					tmpQuat.multLocal(rotation);
					_spatial.setLocalRotation(tmpQuat);
				}
			case DirectionType.Rotation:
				if (rotation != null) {
					_spatial.setLocalRotation(rotation);
				}
			case DirectionType.None:
				//do nothing
		}
	}

	/**
	 * Clone this control for the given spatial
	 * @param spatial
	 * @return
	 */
	public function cloneForSpatial(spatial:Spatial):Control {
		var control:MotionEvent = new MotionEvent(spatial, path);
		control.playState = playState;
		control.currentWayPoint = currentWayPoint;
		control.currentValue = currentValue;
		control.direction = direction.clone();
		control.lookAt = lookAt.clone();
		control.upVector = upVector.clone();
		control.rotation = rotation.clone();
		control.initialDuration = initialDuration;
		control.speed = speed;
		control.loopMode = loopMode;
		control.directionType = directionType;

		return control;
	}

	override public function onPlay():Void {
		traveledDistance = 0;
	}

	override public function onStop():Void {
		_currentWayPoint = 0;
	}

	override public function onPause():Void {

	}

	/**
	 * this method is meant to be called by the motion path only
	 * @return
	 */
	public inline function getCurrentValue():Float {
		return currentValue;
	}

	/**
	 * this method is meant to be called by the motion path only
	 *
	 */
	public function setCurrentValue(currentValue:Float):Void {
		this.currentValue = currentValue;
	}

	/**
	 * this method is meant to be called by the motion path only
	 * @return
	 */
	private function get_currentWayPoint():Int {
		return _currentWayPoint;
	}

	/**
	 * this method is meant to be called by the motion path only
	 *
	 */
	private function set_currentWayPoint(currentWayPoint:Int):Int {
		return _currentWayPoint = currentWayPoint;
	}

	/**
	 * returns the direction the spatial is moving
	 * @return
	 */
	public function getDirection():Vector3f {
		return direction;
	}

	/**
	 * Sets the direction of the spatial
	 * This method is used by the motion path.
	 * @param direction
	 */
	public function setDirection(direction:Vector3f):Void {
		setDirectionWithUp(direction, Vector3f.UNIT_Y);
	}

	public inline function setDirectionWithUp(direction:Vector3f, upVector:Vector3f):Void {
		this.direction.copyFrom(direction);
		this.direction.normalizeLocal();
		this.upVector.copyFrom(upVector);
	}

	/**
	 * returns the direction type of the target
	 * @return the direction type
	 */
	private function get_directionType():DirectionType {
		return _directionType;
	}

	/**
	 * Sets the direction type of the target
	 * On each update the direction given to the target_can have different behavior
	 * See the Direction Enum for explanations
	 * @param directionType the direction type
	 */
	private function set_directionType(value:DirectionType):DirectionType {
		return _directionType = value;
	}

	/**
	 * set_the lookAt for the target
	 * This can be used only if direction Type is Direction.LookAt
	 * @param lookAt the position to look at
	 * @param upVector the up vector
	 */
	public function setLookAt(lookAt:Vector3f, upVector:Vector3f):Void {
		this.lookAt = lookAt;
		this.upVector = upVector;
	}

	/**
	 * returns the rotation of the target
	 * @return the rotation quaternion
	 */
	public function getRotation():Quaternion {
		return rotation;
	}

	/**
	 * sets the rotation of the target
	 * This can be used only if direction Type is Direction.PathAndRotation or Direction.Rotation
	 * With PathAndRotation the target_will face the direction of the path multiplied by the given Quaternion.
	 * With Rotation the rotation of the target_will be set_with the given Quaternion.
	 * @param rotation the rotation quaternion
	 */
	public function setRotation(rotation:Quaternion):Void {
		this.rotation = rotation;
	}

	/**
	 * retun the motion path this control follows
	 * @return
	 */
	public function getPath():MotionPath {
		return path;
	}

	/**
	 * Sets the motion path to follow
	 * @param path
	 */
	public function setPath(path:MotionPath):Void {
		this.path = path;
	}

	public function setEnabled(enabled:Bool):Void {
		if (enabled) {
			play();
		} else
		{
			pause();
		}
	}

	public function isEnabled():Bool {
		return playState == PlayState.Playing;
	}

	public function render(rm:RenderManager, vp:ViewPort):Void {
	}

	public function setSpatial(spatial:Spatial):Void {
		_spatial = spatial;
	}

	public function getSpatial():Spatial {
		return _spatial;
	}

	/**
	 * return the distance traveled by the spatial on the path
	 * @return
	 */
	public function getTraveledDistance():Float {
		return traveledDistance;
	}
}

