package examples.animation;

import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.Lib;
import flash.ui.Keyboard;
import flash.Vector;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.cinematic.events.DirectionType;
import org.angle3d.cinematic.events.MotionEvent;
import org.angle3d.cinematic.LoopMode;
import org.angle3d.cinematic.MotionPath;
import org.angle3d.input.ChaseCamera;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.material.Material;
import org.angle3d.math.FastMath;
import org.angle3d.math.Quaternion;
import org.angle3d.math.SplineType;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Box;
import org.angle3d.utils.Logger;
import org.angle3d.utils.Stats;




class MotionPathTest extends BasicExample
{
	static function main() 
	{
		//trace(MacroHelper.getFileContent("test.txt"));
		flash.Lib.current.addChild(new MotionPathTest());
	}
	
	private var box : Geometry;

	private var path : MotionPath;
	private var motionControl : MotionEvent;

	public function new()
	{
		super();
	}

	override private function initialize(width : Int, height : Int) : Void
	{
		super.initialize(width, height);

		stage.align = StageAlign.TOP_LEFT;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		
		createScene();

		camera.location.setTo(8.4399185, 11.189463, 14.267577);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);

		path = new MotionPath();
		path.setCycle(true);

		path.addWayPoint(new Vector3f(10, 3, 0));
		path.addWayPoint(new Vector3f(10, 3, 10));
		path.addWayPoint(new Vector3f(-40, 3, 10));
		path.addWayPoint(new Vector3f(-40, 3, 0));
		path.addWayPoint(new Vector3f(-40, 8, 0));
		path.addWayPoint(new Vector3f(10, 8, 0));
		path.addWayPoint(new Vector3f(10, 8, 10));
		path.addWayPoint(new Vector3f(15, 8, 10));

		path.splineType = SplineType.CatmullRom;
		path.enableDebugShape(scene);


		path.onWayPointReach.add(onWayPointReach);

		motionControl = new MotionEvent(box, path, 10, LoopMode.Loop);
		motionControl.directionType = DirectionType.PathAndRotation;
		var rot : Quaternion = new Quaternion();
		rot.fromAngleAxis(-FastMath.HALF_PI, Vector3f.UNIT_Y);
		motionControl.setRotation(rot);
		motionControl.setInitialDuration(10);
		motionControl.setSpeed(1);
		motionControl.play();

		flyCam.setDragToRotate(true);
		flyCam.setMoveSpeed(2.0);
		flyCam.setEnabled(false);

		var cc : ChaseCamera = new ChaseCamera(this.camera, box, mInputManager);
		cc.setEnabled(true);
		cc.setDragToRotate(true);
		
		initInputs();
		
		
		start();
	}
	
	private function initInputs():Void
	{
		mInputManager.addTrigger("toggle", new KeyTrigger(Keyboard.SPACE));
		mInputManager.addListener(this, Vector.ofArray(["toggle"]));
	}
	
	override public function onAction(name:String, value:Bool, tpf:Float):Void
	{
		super.onAction(name, value, tpf);
		
		if (name == "toggle" && value)
		{
			motionControl.setEnabled(!motionControl.isEnabled());
		}
	}

	private function createScene() : Void
	{
		box = new Geometry("box", new Box(1, 1, 1));
		
		var mat = new Material();
		mat.load(Angle3D.materialFolder + "material/unshaded.mat");
		mat.setBoolean("useVertexColor", true);
		
		box.setMaterial(mat);

		scene.attachChild(box);
	}

	override public function simpleUpdate(tpf : Float) : Void
	{
		super.simpleUpdate(tpf);
	}

	private function onWayPointReach(control:MotionEvent, wayPointIndex:Int) : Void
	{
		Logger.log("currentPointIndex is " + wayPointIndex);
	}
}


