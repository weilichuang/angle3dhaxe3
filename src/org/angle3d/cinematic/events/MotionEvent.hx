package org.angle3d.cinematic.events;

import org.angle3d.app.Application;
import org.angle3d.cinematic.Cinematic;
import org.angle3d.cinematic.LoopMode;
import org.angle3d.cinematic.MotionPath;
import org.angle3d.cinematic.PlayState;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.scene.Spatial;
import org.angle3d.scene.control.Control;
import org.angle3d.utils.TempVars;

/**
 * A MotionTrack is a control over the spatial that manage the position and direction of the spatial while following a motion Path
 *
 * You must first create a MotionPath and then create a MotionTrack to associate a spatial and the path.
 *
 * @author Nehon
 */
class MotionEvent extends AbstractCinematicEvent implements Control
{
	public var currentWayPoint(get, set):Int;
	public var direction(get, set):Vector3f;
	public var directionType(get, set):Int;

	private var _spatial:Spatial;

	private var _currentWayPoint:Int;
	private var currentValue:Float;

	private var _direction:Vector3f;

	private var lookAt:Vector3f;
	private var upVector:Vector3f;
	private var rotation:Quaternion;
	private var _directionType:Int;
	private var path:MotionPath;
	private var isControl:Bool;

	/**
	 * the distance traveled by the spatial on the path
	 */
	private var traveledDistance:Float;

	/**
	 *
	 * @param	spatial
	 * @param	path
	 * @param	initialDuration 时间长度，秒为单位
	 * @param	loopMode
	 */
	public function new(spatial:Spatial, path:MotionPath, initialDuration:Float = 10, loopMode:Int = 0)
	{
		super(initialDuration, loopMode);

		_direction = new Vector3f();
		_directionType = DirectionType.None;
		isControl = true;
		currentValue = 0;
		traveledDistance = 0;

		_spatial = spatial;
		_spatial.addControl(this);
		this.path = path;
	}

	public function update(tpf:Float):Void
	{
		if (isControl)
		{
			internalUpdate(tpf);
		}
	}

	override public function internalUpdate(tpf:Float):Void
	{
		if (playState == PlayState.Playing)
		{
			time = time + (tpf * speed);

			if (loopMode == LoopMode.Loop && time < 0)
			{
				time = initialDuration;
			}

			if ((time >= initialDuration || time < 0) && loopMode == LoopMode.DontLoop)
			{
				if (time >= initialDuration)
				{
					path.triggerWayPointReach(path.numWayPoints - 1, this);
				}
				stop();
			}
			else
			{
				onUpdate(tpf);
			}
		}
	}

	override public function init(app:Application, cinematic:Cinematic):Void
	{
		super.init(app, cinematic);
		isControl = false;
	}

	override public function setTime(time:Float):Void
	{
		super.setTime(time);

		//computing traveled distance according to new time
		traveledDistance = time * (path.getLength() / initialDuration);

		var vars:TempVars = TempVars.getTempVars();
		var temp:Vector3f = vars.vect1;

		//getting waypoint index and current value from new traveled distance
		var v:Vector2f = path.getWayPointIndexForDistance(traveledDistance);

		//setting values
		_currentWayPoint = Std.int(v.x);
		setCurrentValue(v.y);

		//interpolating new position
		path.getSpline().interpolate(getCurrentValue(), _currentWayPoint, temp);
		//setting new position to the spatial
		_spatial.translation = temp;

		vars.release();
	}

	override public function onUpdate(tpf:Float):Void
	{
		traveledDistance = path.interpolatePath(time, this, tpf);

		computeTargetDirection();

		if (currentValue >= 1.0)
		{
			currentValue = 0;
			_currentWayPoint++;
			path.triggerWayPointReach(_currentWayPoint, this);
		}

		if (_currentWayPoint == path.numWayPoints - 1)
		{
			if (loopMode == LoopMode.Loop)
			{
				_currentWayPoint = 0;
			}
			else
			{
				stop();
			}
		}
	}

	/**
	 * this method is meant to be called by the motion path only
	 * @return
	 */
	public function needsDirection():Bool
	{
		return _directionType == DirectionType.Path || _directionType == DirectionType.PathAndRotation;
	}

	private function computeTargetDirection():Void
	{
		switch (_directionType)
		{
			case DirectionType.Path:
				var q:Quaternion = new Quaternion();
				q.lookAt(_direction, Vector3f.Y_AXIS);
				_spatial.setLocalRotation(q);
			case DirectionType.LookAt:
				if (lookAt != null)
				{
					_spatial.lookAt(lookAt, upVector);
				}
			case DirectionType.PathAndRotation:
				if (rotation != null)
				{
					var q2:Quaternion = new Quaternion();
					q2.lookAt(_direction, Vector3f.Y_AXIS);
					q2.multiplyLocal(rotation);
					_spatial.setLocalRotation(q2);
				}
			case DirectionType.Rotation:
				if (rotation != null)
				{
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
	public function cloneForSpatial(spatial:Spatial):Control
	{
		var control:MotionEvent = new MotionEvent(spatial, path);
		control.playState = playState;
		control._currentWayPoint = _currentWayPoint;
		control.currentValue = currentValue;
		control._direction = _direction.clone();
		control.lookAt = lookAt.clone();
		control.upVector = upVector.clone();
		control.rotation = rotation.clone();
		control.duration = duration;
		control.initialDuration = initialDuration;
		control.speed = speed;
		control.duration = duration;
		control.loopMode = loopMode;
		control._directionType = _directionType;

		return control;
	}

	override public function onStop():Void
	{
		_currentWayPoint = 0;
	}

	/**
	 * this method is meant to be called by the motion path only
	 * @return
	 */
	public function getCurrentValue():Float
	{
		return currentValue;
	}

	/**
	 * this method is meant to be called by the motion path only
	 *
	 */
	public function setCurrentValue(currentValue:Float):Void
	{
		this.currentValue = currentValue;
	}

	
	/**
	 * this method is meant to be called by the motion path only
	 * @return
	 */
	private function get_currentWayPoint():Int
	{
		return _currentWayPoint;
	}

	/**
	 * this method is meant to be called by the motion path only
	 *
	 */
	private function set_currentWayPoint(currentWayPoint:Int):Int
	{
		return _currentWayPoint = currentWayPoint;
	}

	
	/**
	 * returns the direction the spatial is moving
	 * @return
	 */
	private function get_direction():Vector3f
	{
		return _direction;
	}

	/**
	 * Sets the direction of the spatial
	 * This method is used by the motion path.
	 * @param direction
	 */
	private function set_direction(vec:Vector3f):Vector3f
	{
		return _direction.copyFrom(vec);
	}

	/**
	 * returns the direction type of the target
	 * @return the direction type
	 */
	private function get_directionType():Int
	{
		return _directionType;
	}

	/**
	 * Sets the direction type of the target
	 * On each update the direction given to the target_can have different behavior
	 * See the Direction Enum for explanations
	 * @param directionType the direction type
	 */
	private function set_directionType(value:Int):Int
	{
		return _directionType = value;
	}

	/**
	 * set_the lookAt for the target
	 * This can be used only if direction Type is Direction.LookAt
	 * @param lookAt the position to look at
	 * @param upVector the up vector
	 */
	public function setLookAt(lookAt:Vector3f, upVector:Vector3f):Void
	{
		this.lookAt = lookAt;
		this.upVector = upVector;
	}

	/**
	 * returns the rotation of the target
	 * @return the rotation quaternion
	 */
	public function getRotation():Quaternion
	{
		return rotation;
	}

	/**
	 * sets the rotation of the target
	 * This can be used only if direction Type is Direction.PathAndRotation or Direction.Rotation
	 * With PathAndRotation the target_will face the direction of the path multiplied by the given Quaternion.
	 * With Rotation the rotation of the target_will be set_with the given Quaternion.
	 * @param rotation the rotation quaternion
	 */
	public function setRotation(rotation:Quaternion):Void
	{
		this.rotation = rotation;
	}

	/**
	 * retun the motion path this control follows
	 * @return
	 */
	public function getPath():MotionPath
	{
		return path;
	}

	/**
	 * Sets the motion path to follow
	 * @param path
	 */
	public function setPath(path:MotionPath):Void
	{
		this.path = path;
	}

	
	public function setEnabled(enabled:Bool):Void
	{
		if (enabled)
		{
			play();
		}
		else
		{
			pause();
		}
	}

	public function isEnabled():Bool
	{
		return playState != PlayState.Stopped;
	}

	public function render(rm:RenderManager, vp:ViewPort):Void
	{
	}

	
	public function setSpatial(spatial:Spatial):Void
	{
		_spatial = spatial;
	}

	public function getSpatial():Spatial
	{
		return _spatial;
	}

	/**
	 * return the distance traveled by the spatial on the path
	 * @return
	 */
	public function getTraveledDistance():Float
	{
		return traveledDistance;
	}
}

