package examples.post;

import flash.text.TextField;
import flash.Vector;
import org.angle3d.math.Vector2f;
import flash.Lib;
import flash.ui.Keyboard;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.input.controls.AnalogListener;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.light.PointLight;
import org.angle3d.material.Material;
import org.angle3d.material.VarType;
import org.angle3d.math.Color;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.post.filter.DepthOfFieldFilter;
import org.angle3d.post.filter.FogFilter;
import org.angle3d.post.FilterPostProcessor;
import org.angle3d.renderer.queue.QueueBucket;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.LightNode;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Box;
import org.angle3d.scene.ui.Picture;
import org.angle3d.shadow.BasicShadowRenderer;
import org.angle3d.utils.Stats;

class TestDepthOfField extends BasicExample implements AnalogListener
{
	static function main() 
	{
		Lib.current.addChild(new TestDepthOfField());
	}
	
	private var fpp:FilterPostProcessor;
	private var enabled:Bool = true;
	private var dofFilter:DepthOfFieldFilter;
	
	private var tf:TextField;

	public function new() 
	{
		super();
		
		//Angle3D.maxAgalVersion = 2;
	}
	
	private var _center:Vector3f;
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		setupFloor();
		
		var hCount:Int = 10;
		var vCount:Int = 10;
		var halfHCount:Float = (hCount / 2);
		var halfVCount:Float = (vCount / 2);
		var index:Int = 0;
		for (i in 0...hCount)
		{
			for (j in 0...vCount)
			{
				var node:Geometry = createBox(index++);
				node.localShadowMode = ShadowMode.CastAndReceive;
				node.setTranslationXYZ((i - halfHCount) * 15, 5, (j - halfVCount) * 15);
				scene.attachChild(node);
			}
		}
		
		_center = new Vector3f(0, 0, 0);

		camera.location.setTo(0, 40, 80);
		camera.lookAt(_center, Vector3f.Y_AXIS);
		
		flyCam.setMoveSpeed(20);
		
		fpp = new FilterPostProcessor();
		dofFilter = new DepthOfFieldFilter(10,50,2.4);
		fpp.addFilter(dofFilter);
		viewPort.addProcessor(fpp);
		
		initInputs();
		
		reshape(mContextWidth, mContextHeight);
		
		tf = new TextField();
		tf.textColor = 0xffffff;
		tf.width = 200;
		tf.height = 400;
		this.stage.addChild(tf);
		
		updateTF();
		
		
		start();
	}
	
	private function setupFloor():Void
	{
		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/unshaded.mat");
        mat.setColor("u_MaterialColor",  new Color(0.8,0.8,0.8));

		var floor:Box = new Box(150, 1, 150);
		var floorGeom:Geometry = new Geometry("Floor", floor);
		floorGeom.setMaterial(mat);
		floorGeom.setLocalTranslation(new Vector3f(0, 0, 0));
		scene.attachChild(floorGeom);
	}
	
	private function initInputs():Void
	{
		mInputManager.addTrigger("toggle", new KeyTrigger(Keyboard.SPACE));
		mInputManager.addTrigger("RangeUp", new KeyTrigger(Keyboard.NUMBER_1));
		mInputManager.addTrigger("RangeDown", new KeyTrigger(Keyboard.NUMBER_2));
		mInputManager.addTrigger("DistanceUp", new KeyTrigger(Keyboard.NUMBER_3));
		mInputManager.addTrigger("DistanceDown", new KeyTrigger(Keyboard.NUMBER_4));
		mInputManager.addTrigger("scaleUp", new KeyTrigger(Keyboard.NUMBER_5));
		mInputManager.addTrigger("scaleDown", new KeyTrigger(Keyboard.NUMBER_6));
		mInputManager.addListener(this, Vector.ofArray(["toggle", "RangeUp", "RangeDown", "DistanceUp", "DistanceDown","scaleUp","scaleDown"]));
	}
	
	private function createBox(index:Int):Geometry
	{
		var geometry:Geometry = new Geometry("box" + index,new Box(5,5,5));
		
		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/unshaded.mat");
		mat.setParam("u_MaterialColor", VarType.COLOR, new Color(Math.random(),Math.random(),Math.random()));
		
		geometry.setMaterial(mat);
		
		return geometry;
	}
	
	override public function onAction(name:String, value:Bool, tpf:Float):Void
	{
		super.onAction(name, value, tpf);
		
		if (name == "toggle" && value)
		{
			if (enabled)
			{
				enabled = false;
				viewPort.removeProcessor(fpp);
			}
			else
			{
				enabled = true;
				viewPort.addProcessor(fpp);
			}
		}
	}
	
	public function onAnalog(name:String, value:Float, tpf:Float):Void
	{
		switch(name)
		{
			case "RangeUp":
				dofFilter.setFocusRange(dofFilter.getFocusRange() + 1);
			case "RangeDown":
				dofFilter.setFocusRange(dofFilter.getFocusRange() - 1);
			case "DistanceUp":
				dofFilter.setFocusDistance(dofFilter.getFocusDistance() + 1);
			case "DistanceDown":
				dofFilter.setFocusDistance(dofFilter.getFocusDistance() - 1);
			case "scaleUp":
				dofFilter.setBlurScale(dofFilter.getBlurScale() + 0.1);
			case "scaleDown":
				dofFilter.setBlurScale(dofFilter.getBlurScale() - 0.1);
		}
		updateTF();
	}
	
	private function updateTF():Void
	{
		tf.text = "Range:" + dofFilter.getFocusRange() + "\n";
		tf.text += "Distance:" + dofFilter.getFocusDistance() + "\n";
		tf.text+="BlurScale:" + dofFilter.getBlurScale() + "\n";
	}
}