package examples.post;

import flash.text.TextField;

import org.angle3d.math.Vector2f;

import flash.ui.Keyboard;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.input.controls.AnalogListener;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.light.PointLight;
import org.angle3d.material.Material;
import org.angle3d.shader.VarType;
import org.angle3d.math.Color;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
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

class TestFog extends BasicExample implements AnalogListener
{
	static function main() 
	{
		Lib.current.addChild(new TestFog());
	}
	
	private var fpp:FilterPostProcessor;
	private var enabled:Bool = true;
	private var fog:FogFilter;
	private var usePCF:Bool = false;
	
	private var tf:TextField;
	
	private var basicShadowRender:BasicShadowRenderer;
	
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
		
		var pl = new PointLight();
		pl.color = new Color(1, 0, 0, 1);
		pl.radius = 150;
		scene.addLight(pl);
		
		//var lightNode:LightNode = new LightNode("pointLight", pl);
		//scene.attachChild(lightNode);
		//lightNode.setTranslationXYZ(0, 40, 80);
		
		basicShadowRender = new BasicShadowRenderer(1024);
		basicShadowRender.setShadowInfo(0.002, 0.8, usePCF);
		basicShadowRender.setDirection(camera.getDirection().normalizeLocal());
		viewPort.addProcessor(basicShadowRender);
		
		scene.attachChild(basicShadowRender.getDisplayPicture());
		
		fpp = new FilterPostProcessor();
		fog = new FogFilter(new Color(0.6, 0.6, 0.6, 1.0), 2.0, 100);
		fpp.addFilter(fog);
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
		floorGeom.localShadowMode = ShadowMode.Receive;
		scene.attachChild(floorGeom);
	}
	
	private function initInputs():Void
	{
		mInputManager.addTrigger("usePCF", new KeyTrigger(Keyboard.NUMBER_5));
		mInputManager.addTrigger("toggle", new KeyTrigger(Keyboard.SPACE));
		mInputManager.addTrigger("DensityUp", new KeyTrigger(Keyboard.NUMBER_1));
		mInputManager.addTrigger("DensityDown", new KeyTrigger(Keyboard.NUMBER_2));
		mInputManager.addTrigger("DistanceUp", new KeyTrigger(Keyboard.NUMBER_3));
		mInputManager.addTrigger("DistanceDown", new KeyTrigger(Keyboard.NUMBER_4));
		mInputManager.addListener(this, ["usePCF","toggle", "DensityUp", "DensityDown", "DistanceUp", "DistanceDown"]);
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
		else if (name == "usePCF" && value)
		{
			if (usePCF)
			{
				usePCF = false;
				basicShadowRender.setShadowInfo(0.002, 0.8, false);
			}
			else
			{
				usePCF = true;
				basicShadowRender.setShadowInfo(0.002, 0.8, true);
			}
		}
	}
	
	public function onAnalog(name:String, value:Float, tpf:Float):Void
	{
		switch(name)
		{
			case "DensityUp":
				fog.setFogDensity(fog.getFogDensity() + 0.01);
			case "DensityDown":
				fog.setFogDensity(fog.getFogDensity() - 0.01);
			case "DistanceUp":
				fog.setFogDistance(fog.getFogDistance() + 1);
			case "DistanceDown":
				fog.setFogDistance(fog.getFogDistance() - 1);
		}
		updateTF();
	}
	
	private function updateTF():Void
	{
		tf.text = "Density:" + fog.getFogDensity() + "\n";
		tf.text += "Distance:" + fog.getFogDistance() + "\n";
		tf.text += "usePCF:" + usePCF + "\n";
	}
	
	override public function update():Void 
	{
		super.update();
		
		if(basicShadowRender != null)
			basicShadowRender.setDirection(camera.getDirection().normalizeLocal());
	}
}