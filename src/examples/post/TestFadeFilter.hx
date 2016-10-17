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
import org.angle3d.post.filter.FadeFilter;
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

class TestFadeFilter extends BasicExample implements AnalogListener
{
	static function main() 
	{
		Lib.current.addChild(new TestFadeFilter());
	}
	
	private var fpp:FilterPostProcessor;
	private var enabled:Bool = false;
	private var fade:FadeFilter;

	public function new() 
	{
		super();
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
		camera.lookAt(_center, Vector3f.UNIT_Y);
		
		flyCam.setMoveSpeed(20);
		
		fpp = new FilterPostProcessor();
		fade = new FadeFilter(2);
		fpp.addFilter(fade);
		viewPort.addProcessor(fpp);
		
		initInputs();
		
		reshape(mContextWidth, mContextHeight);
		
		
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
		floorGeom.localShadowMode = ShadowMode.Receive;
		scene.attachChild(floorGeom);
	}
	
	private function initInputs():Void
	{
		mInputManager.addTrigger("toggle", new KeyTrigger(Keyboard.SPACE));
		mInputManager.addListener(this, Vector.ofArray(["toggle"]));
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
				fade.fadeIn();
			}
			else
			{
				enabled = true;
				fade.fadeOut();
			}
		}
	}
	
	public function onAnalog(name:String, value:Float, tpf:Float):Void
	{
	}
}