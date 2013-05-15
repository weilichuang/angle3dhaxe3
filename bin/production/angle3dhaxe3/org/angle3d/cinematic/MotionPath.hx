package org.angle3d.cinematic;

import hu.vpmedia.signals.SignalLite;
import org.angle3d.cinematic.events.MotionEvent;
import org.angle3d.math.Spline;
import org.angle3d.math.SplineType;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;
import org.angle3d.scene.WireframeGeometry;
import org.angle3d.scene.shape.WireframeCube;
import org.angle3d.scene.shape.WireframeCurve;
import org.angle3d.utils.TempVars;
import flash.Vector;

/**
 * Motion path is used to create a path between way points.
 * @author Nehon
 */
//TODO 需要调整debug部分
class MotionPath
{
	public var splineType(get, set):SplineType;
	public var numWayPoints(get, null):Int;
	public var onWayPointReach(get, null):SignalLite;
	
	private var _spline:Spline;

	private var _debugNode:Node;

	private var prevWayPoint:Int;

	/**
	 *
	 */
	private var _wayPointReach:SignalLite;

	/**
	 * Create a motion Path
	 */
	public function new()
	{
		_spline = new Spline();

		_wayPointReach = new SignalLite();
	}

	private function get_onWayPointReach():SignalLite
	{
		return _wayPointReach;
	}

	/**
	 * interpolate the path giving the time since the beginnin and the motionControl
	 * this methods sets the new localTranslation to the spatial of the motionTrack control.
	 * @param time the time since the animation started
	 * @param control the ocntrol over the moving spatial
	 */
	public function interpolatePath(time:Float, control:MotionEvent, tpf:Float):Float
	{
		var traveledDistance:Float = 0;

		var vars:TempVars = TempVars.getTempVars();
		var temp:Vector3f = vars.vect1;
		var tmpVector:Vector3f = vars.vect2;

		//computing traveled distance according to new time
		traveledDistance = time * (getLength() / control.getInitialDuration());

		//getting waypoint index and current value from new traveled distance
		var v:Vector2f = getWayPointIndexForDistance(traveledDistance);

		//setting values
		control.currentWayPoint = Std.int(v.x);
		control.setCurrentValue(v.y);

		//interpolating new position
		_spline.interpolate(control.getCurrentValue(), control.currentWayPoint, temp);

		if (control.needsDirection())
		{
			tmpVector.copyFrom(temp);
			tmpVector.subtractLocal(control.spatial.translation);
			control.direction = tmpVector;
			control.direction.normalizeLocal();
		}

		checkWayPoint(control, tpf);

		control.spatial.translation = temp;

		vars.release();

		return traveledDistance;
	}

	public function checkWayPoint(control:MotionEvent, tpf:Float):Void
	{
		//Epsilon varies with the tpf to aVoid missing a waypoint on low framerate.
		var epsilon:Float = tpf * 4;
		if (control.currentWayPoint != prevWayPoint)
		{
			if (control.getCurrentValue() >= 0 && control.getCurrentValue() < epsilon)
			{
				triggerWayPointReach(control.currentWayPoint, control);
				prevWayPoint = control.currentWayPoint;
			}
		}
	}

	private function attachDebugNode(root:Node):Void
	{
		if (_debugNode == null)
		{
			_debugNode = new Node("MotionPath_debug");

			var points:Vector<Vector3f> = _spline.getControlPoints();
			for (i in 0...points.length)
			{
				var geo:WireframeGeometry = new WireframeGeometry("sphere" + i, new WireframeCube(0.5, 0.5, 0.5));
				geo.translation = points[i];
				_debugNode.attachChild(geo);
			}

			switch (_spline.type)
			{
				case SplineType.CatmullRom:
					_debugNode.attachChild(_createCatmullRomPath());
				case SplineType.Linear:
					_debugNode.attachChild(_createLinearPath());
				default:
					_debugNode.attachChild(_createLinearPath());
			}

			root.attachChild(_debugNode);
		}
	}

	private function _createLinearPath():Geometry
	{
		var geometry:WireframeGeometry = new WireframeGeometry("LinearPath", new WireframeCurve(_spline, 0));
		geometry.materialWireframe.color = 0x0000ff;
		return geometry;
	}

	private function _createCatmullRomPath():Geometry
	{
		var geometry:WireframeGeometry = new WireframeGeometry("CatmullRomPath", new WireframeCurve(_spline, 10));
		geometry.materialWireframe.color = 0x0000ff;
		return geometry;
	}

	/**
	 * compute the index of the waypoint and the interpolation value according to a distance
	 * returns a vector 2 containing the index in the x field and the interpolation value in the y field
	 * @param distance the distance traveled on this path
	 * @return the waypoint index and the interpolation value in a vector2
	 */
	public function getWayPointIndexForDistance(distance:Float):Vector2f
	{
		var sum:Float = 0;
		distance = distance % _spline.getTotalLength();
		var list:Vector<Float> = _spline.getSegmentsLength();
		var length:Int = list.length;
		for (i in 0...length)
		{
			var len:Float = list[i];
			if (sum + len >= distance)
			{
				return new Vector2f(i, (distance - sum) / len);
			}
			sum += len;
		}
		return new Vector2f(_spline.getControlPoints().length - 1, 1.0);
	}

	/**
	 * Addsa waypoint to the path
	 * @param wayPoint a position in world space
	 */
	public function addWayPoint(wayPoint:Vector3f):Void
	{
		_spline.addControlPoint(wayPoint);
	}

	/**
	 * retruns the length of the path in world units
	 * @return the length
	 */
	public function getLength():Float
	{
		return _spline.getTotalLength();
	}

	/**
	 * returns the waypoint at the given index
	 * @param i the index
	 * @return returns the waypoint position
	 */
	public function getWayPoint(i:Int):Vector3f
	{
		return _spline.getControlPointAt(i);
	}

	/**
	 * remove the waypoint from the path
	 * @param wayPoint the waypoint to remove
	 */
	public function removeWayPoint(wayPoint:Vector3f):Void
	{
		_spline.removeControlPoint(wayPoint);
	}

	/**
	 * remove the waypoint at the given index from the path
	 * @param i the index of the waypoint to remove
	 */
	public function removeWayPointAt(i:Int):Void
	{
		_spline.removeControlPoint(getWayPoint(i));
	}

	public function clearWayPoints():Void
	{
		_spline.clearControlPoints();
	}

	
	/**
	 * return the type of spline used for the path interpolation for this path
	 * @return the path interpolation spline type
	 */
	private function get_splineType():SplineType
	{
		return _spline.type;
	}

	/**
	 * sets the type of spline used for the path interpolation for this path
	 * @param pathSplineType
	 */
	private function set_splineType(type:SplineType):SplineType
	{
		return _spline.type = type;
	}

	/**
	 * 重新生成debugNode
	 */
//		private function refreshDebugNode():Void
//		{
//			if (_debugNode != null)
//			{
//				var parent:Node = _debugNode.parent;
//				_debugNode.removeFromParent();
//				_debugNode.detachAllChildren();
//				_debugNode = null;
//				attachDebugNode(parent);
//			}
//		}

	public function enableDebugShape(node:Node):Void
	{
		attachDebugNode(node);
	}

	public function disableDebugShape():Void
	{
		if (_debugNode != null)
		{
			var parent:Node = _debugNode.parent;
			_debugNode.removeFromParent();
			_debugNode.detachAllChildren();
			_debugNode = null;
		}
	}

	/**
	 * return the number of waypoints of this path
	 * @return
	 */
	private function get_numWayPoints():Int
	{
		return _spline.getControlPoints().length;
	}

	public function triggerWayPointReach(wayPointIndex:Int, control:MotionEvent):Void
	{
		_wayPointReach.dispatch([control, wayPointIndex]);
	}

	/**
	 * Returns the curve tension
	 * @return
	 */
	public function getCurveTension():Float
	{
		return _spline.getCurveTension();
	}

	/**
	 * sets the tension of the curve (only for catmull rom) 0.0 will give a linear curve, 1.0 a round curve
	 * @param curveTension
	 */
	public function setCurveTension(curveTension:Float):Void
	{
		_spline.setCurveTension(curveTension);
	}

	/**
	 * Sets the path to be a cycle
	 * @param cycle
	 */
	public function setCycle(cycle:Bool):Void
	{
		_spline.setCycle(cycle);
	}

	/**
	 * returns true if the path is a cycle
	 * @return
	 */
	public function isCycle():Bool
	{
		return _spline.isCycle();
	}

	public function getSpline():Spline
	{
		return _spline;
	}
}

