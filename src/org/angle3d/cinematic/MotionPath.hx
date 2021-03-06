package org.angle3d.cinematic;

import flash.Vector;
import org.angle3d.signal.Signal.Signal2;
import org.angle3d.cinematic.events.MotionEvent;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.Spline;
import org.angle3d.math.SplineType;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.WireframeCube;
import org.angle3d.scene.shape.WireframeCurve;
import org.angle3d.scene.WireframeGeometry;
import org.angle3d.utils.TempVars;

/**
 * Motion path is used to create a path between way points.
 */
class MotionPath
{
	/**
	 * the type of spline used for the path interpolation for this path
	 */
	public var splineType(get, set):SplineType;
	
	/**
	 * return the number of waypoints of this path
	 */
	public var numWayPoints(get, null):Int;
	
	 /**
     * Triggers every time the target reach a waypoint on the path
     * @param motionControl the MotionEvent objects that reached the waypoint
     * @param wayPointIndex the index of the way point reached
     */
	public var onWayPointReach(get, null):Signal2<MotionEvent,Int>;
	
	private var _spline:Spline;

	private var mDebugNode:Node;

	private var prevWayPoint:Int;

	/**
	 *
	 */
	private var _wayPointReach:Signal2<MotionEvent,Int>;

	/**
	 * Create a motion Path
	 */
	public function new()
	{
		_spline = new Spline();

		_wayPointReach = new Signal2<MotionEvent,Int>();
	}

	private static var wayPointVec:Vector2f = new Vector2f();
	private static var tmp:Vector3f = new Vector3f();
	private static var tmpVector:Vector3f = new Vector3f();
	/**
	 * interpolate the path giving the time since the beginnin and the motionControl
	 * this methods sets the new localTranslation to the spatial of the motionTrack control.
	 * @param time the time since the animation started
	 * @param control the ocntrol over the moving spatial
	 */
	public function interpolatePath(time:Float, control:MotionEvent, tpf:Float):Float
	{
		//computing traveled distance according to new time
		var traveledDistance:Float = time * (getLength() / control.getInitialDuration());

		//getting waypoint index and current value from new traveled distance
		getWayPointIndexForDistance(traveledDistance, wayPointVec);

		//setting values
		control.currentWayPoint = Std.int(wayPointVec.x);
		control.setCurrentValue(wayPointVec.y);

		//interpolating new position
		_spline.interpolate(control.getCurrentValue(), control.currentWayPoint, tmp);

		if (control.needsDirection())
		{
			tmp.subtract(control.getSpatial().localTranslation, tmpVector);
			control.setDirection(tmpVector);
		}

		checkWayPoint(control, tpf);

		control.getSpatial().localTranslation = tmp;

		return traveledDistance;
	}

	public function checkWayPoint(control:MotionEvent, tpf:Float):Void
	{
		//Epsilon varies with the tpf to aVoid missing a waypoint on low framerate.
		var epsilon:Float = tpf * 4;
		if (control.currentWayPoint != prevWayPoint)
		{
			var curValue:Float = control.getCurrentValue();
			if (curValue >= 0 && curValue < epsilon)
			{
				triggerWayPointReach(control.currentWayPoint, control);
				prevWayPoint = control.currentWayPoint;
			}
		}
	}
	
	/**
	 * compute the index of the waypoint and the interpolation value according to a distance
	 * returns a vector 2 containing the index in the x field and the interpolation value in the y field
	 * @param distance the distance traveled on this path
	 * @return the waypoint index and the interpolation value in a vector2
	 */
	public function getWayPointIndexForDistance(distance:Float,store:Vector2f):Vector2f
	{
		var totalLength:Float = _spline.getTotalLength();
		if (totalLength == 0)
		{
			store.setTo(0, 0);
			return store;
		}
		
		var sum:Float = 0;
		distance = distance % totalLength;
		
		var list:Vector<Float> = _spline.getSegmentsLength();
		var length:Int = list.length;
		for (i in 0...length)
		{
			var len:Float = list[i];
			if (sum + len >= distance)
			{
				store.setTo(i, (distance - sum) / len);
				return store;
			}
			sum += len;
		}
		store.setTo(_spline.getControlPoints().length - 1, 1.0);
		return store;
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
	
	public function triggerWayPointReach(wayPointIndex:Int, control:MotionEvent):Void
	{
		_wayPointReach.dispatch(control, wayPointIndex);
	}

	/**
	 * Returns the curve tension
	 * @return
	 */
	public inline function getCurveTension():Float
	{
		return _spline.curveTension;
	}

	/**
	 * sets the tension of the curve (only for catmull rom) 0.0 will give a linear curve, 1.0 a round curve
	 * @param curveTension
	 */
	public function setCurveTension(curveTension:Float):Void
	{
		_spline.curveTension = curveTension;
	}

	/**
	 * Sets the path to be a cycle
	 * @param cycle
	 */
	public function setCycle(cycle:Bool):Void
	{
		_spline.cycle = cycle;
	}

	/**
	 * returns true if the path is a cycle
	 * @return
	 */
	public inline function isCycle():Bool
	{
		return _spline.cycle;
	}

	public function getSpline():Spline
	{
		return _spline;
	}
	
	public function enableDebugShape(node:Node):Void
	{
		attachDebugNode(node);
	}

	public function disableDebugShape():Void
	{
		if (mDebugNode != null)
		{
			var parent:Node = mDebugNode.parent;
			mDebugNode.removeFromParent();
			mDebugNode.detachAllChildren();
			mDebugNode = null;
		}
	}

	private function attachDebugNode(root:Node):Void
	{
		if (mDebugNode == null)
		{
			mDebugNode = new Node("MotionPath_debug");

			var points:Vector<Vector3f> = _spline.getControlPoints();
			for (i in 0...points.length)
			{
				var geo:WireframeGeometry = new WireframeGeometry("sphere" + i, new WireframeCube(0.3, 0.3, 0.3));
				
				var mat:Material = new Material();
				mat.load(Angle3D.materialFolder + "material/wireframe.mat");
				mat.setColor("u_color", Color.fromColor(0x00ffff));
				mat.setFloat("u_thickness", 0.001);
				geo.setMaterial(mat);
		
				geo.localTranslation = points[i];
				mDebugNode.attachChild(geo);
			}

			switch (_spline.type)
			{
				case SplineType.CatmullRom:
					mDebugNode.attachChild(_createCatmullRomPath());
				case SplineType.Linear:
					mDebugNode.attachChild(_createLinearPath());
				default:
					mDebugNode.attachChild(_createLinearPath());
			}

			root.attachChild(mDebugNode);
		}
	}

	private function _createLinearPath():Geometry
	{
		var geometry:WireframeGeometry = new WireframeGeometry("LinearPath", new WireframeCurve(_spline, 0));

		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/wireframe.mat");
		mat.setColor("u_color", Color.fromColor(0x0000ff));
		mat.setFloat("u_thickness", 0.001);
		
		geometry.setMaterial(mat);
		
		return geometry;
	}

	private function _createCatmullRomPath():Geometry
	{
		var geometry:WireframeGeometry = new WireframeGeometry("CatmullRomPath", new WireframeCurve(_spline, 10));
		
		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/wireframe.mat");
		mat.setColor("u_color", Color.fromColor(0x0000ff));
		mat.setFloat("u_thickness", 0.001);
		
		geometry.setMaterial(mat);

		return geometry;
	}
	
	private inline function get_splineType():SplineType
	{
		return _spline.type;
	}

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

	private inline function get_numWayPoints():Int
	{
		return _spline.getControlPoints().length;
	}

	private inline function get_onWayPointReach():Signal2<MotionEvent,Int>
	{
		return _wayPointReach;
	}
}

