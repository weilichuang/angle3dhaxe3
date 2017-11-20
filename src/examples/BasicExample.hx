package examples;

import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.core.Key;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.light.Light;
import org.angle3d.material.Material;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.LightNode;
import org.angle3d.scene.shape.Sphere;

class BasicExample extends SimpleApplication
{
	private var msgText:TextField;
	private var msgPosition:String = "topLeft";

	public function new() 
	{
		super();
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		mInputManager.addTrigger("fullscreen", new KeyTrigger(Key.O));
		mInputManager.addListener(this, ["fullscreen"]);
	}
	
	override public function onAction(name:String, isPressed:Bool, tpf:Float):Void
	{
		super.onAction(name, isPressed, tpf);
	}
	
	override public function setSize(w:Int, h:Int):Void 
	{
		super.setSize(w, h);
	}
	
	override public function update():Void
	{
		super.update();
	}
	
	override public function simpleUpdate(tpf:Float):Void
	{
		super.simpleUpdate(tpf);
	}
	
	private function createLightNode(light:Light, radius:Float = 10):LightNode
	{
		var colorMat:Material = new Material();
		colorMat.load(Angle3D.materialFolder + "material/unshaded.mat");
		colorMat.setColor("u_MaterialColor", light.color);
		
		var lightGeometry:Geometry = new Geometry("debugNode", new Sphere(radius, 12, 12));
		lightGeometry.setMaterial(colorMat);
		
		var lightNode:LightNode = new LightNode(light.name+"_node", light);
		lightNode.attachChild(lightGeometry);
		
		return lightNode;
	}
}