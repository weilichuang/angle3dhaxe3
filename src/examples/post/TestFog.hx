package examples.post;

import flash.Lib;
import flash.ui.Keyboard;
import org.angle3d.app.SimpleApplication;
import org.angle3d.input.controls.AnalogListener;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.material.Material;
import org.angle3d.material.VarType;
import org.angle3d.math.Color;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.post.filter.FogFilter;
import org.angle3d.post.FilterPostProcessor;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Box;
import org.angle3d.utils.Stats;

class TestFog extends SimpleApplication implements AnalogListener
{
	static function main() 
	{
		Lib.current.addChild(new TestFog());
	}
	
	private var fpp:FilterPostProcessor;
	private var enabled:Bool = true;
	private var fog:FogFilter;
	public function new() 
	{
		super();
	}
	
	private var _center:Vector3f;
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
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
				node.setTranslationXYZ((i - halfHCount) * 15, 0, (j - halfVCount) * 15);
				scene.attachChild(node);
			}
		}
		
		_center = new Vector3f(0, 0, 0);

		camera.location.setTo(Math.cos(0) * 80, 60, Math.sin(0) * 80);
		camera.lookAt(_center, Vector3f.Y_AXIS);
		
		flyCam.setMoveSpeed(20);
		
		fpp = new FilterPostProcessor();
		fog = new FogFilter(new Color(0.9, 0.9, 0.9, 1.0), 2.0, 155);
		fpp.addFilter(fog);
		//viewPort.addProcessor(fpp);
		
		initInputs();
		
		Stats.show(stage);
		start();
	}
	
	private function initInputs():Void
	{
		mInputManager.addSingleMapping("toggle", new KeyTrigger(Keyboard.SPACE));
		mInputManager.addSingleMapping("DensityUp", new KeyTrigger(Keyboard.Y));
		mInputManager.addSingleMapping("DensityDown", new KeyTrigger(Keyboard.H));
		mInputManager.addSingleMapping("DistanceUp", new KeyTrigger(Keyboard.U));
		mInputManager.addSingleMapping("DistanceDown", new KeyTrigger(Keyboard.J));
		mInputManager.addListener(this, ["toggle", "DensityUp", "DensityDown", "DistanceUp", "DistanceDown"]);
	}
	
	private function createBox(index:Int):Geometry
	{
		var geometry:Geometry = new Geometry("box" + index,new Box(5,5,5));
		
		var mat:Material = new Material();
		mat.load("assets/material/unshaded.mat");
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
			case "DensityUp":
				fog.setFogDensity(fog.getFogDensity() + 0.001);
			case "DensityDown":
				fog.setFogDensity(fog.getFogDensity() - 0.001);
			case "DistanceUp":
				fog.setFogDistance(fog.getFogDistance() + 0.5);
			case "DistanceDown":
				fog.setFogDistance(fog.getFogDistance() - 0.5);
		}
	}
}