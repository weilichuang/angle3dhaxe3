package examples;

import flash.Vector;
import flash.events.KeyboardEvent;
import flash.filters.GlowFilter;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.ui.Keyboard;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.light.Light;
import org.angle3d.material.Material;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.LightNode;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.utils.Stats;
import flash.display.StageDisplayState;

class BasicExample extends SimpleApplication
{
	private var msgText:TextField;
	private var msgPosition:String = "topLeft";
	private var stats:Stats;

	public function new() 
	{
		super();
		Angle3D.ignoreSamplerFlag = true;
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		mInputManager.addTrigger("fullscreen", new KeyTrigger(Keyboard.O));
		mInputManager.addTrigger("stats", new KeyTrigger(Keyboard.LEFTBRACKET));
		mInputManager.addListener(this, Vector.ofArray(["fullscreen","stats"]));
	}
	
	override public function onAction(name:String, isPressed:Bool, tpf:Float):Void
	{
		super.onAction(name, isPressed, tpf);
		
		if (name == "fullscreen" && isPressed)
		{
			if (stage.displayState == StageDisplayState.FULL_SCREEN_INTERACTIVE)
			{
				stage.displayState = StageDisplayState.NORMAL;
			}
			else
			{
				stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			}
		}
		else if (name == "stats" && isPressed)
		{
			if (stats == null || stats.visible == false)
			{
				if (stats == null)
					stats = Stats.show(this.stage);
				else
					stats.visible = true;
			}
			else
			{
				this.stats.visible = false;
			}
		}
	}
	
	override public function setSize(w:Int, h:Int):Void 
	{
		super.setSize(w, h);
		
		if (this.stats != null)
			this.stats.relayout(stage);
			
		relayoutMsg();
	}
	
	private function showMsg(text:String,position:String="topLeft", color:UInt = 0xFFFFFF, size:Int = 14, bold:Bool = false):Void
	{
		if (msgText == null)
		{
			msgText = new TextField();
			msgText.autoSize = TextFieldAutoSize.LEFT;
			msgText.selectable = false;
			
			var filter:GlowFilter = new GlowFilter(0x0, 1, 4, 4, 8);
			
			msgText.filters = [filter];
			
			this.addChild(msgText);
		}
		
		msgPosition = position;
		
		var format:TextFormat = msgText.defaultTextFormat;
		format.size = size;
		format.color = color;
		format.bold = bold;
		msgText.defaultTextFormat = format;
			
		msgText.text = text;
		
		relayoutMsg();
	}
	
	private function relayoutMsg():Void
	{
		if (msgText != null)
		{
			if (msgPosition == "topLeft")
			{
				msgText.x = 0;
				msgText.y = 0;
			}
			else if (msgPosition == "center")
			{
				msgText.x = (stage.stageWidth - msgText.width) * 0.5;
				msgText.y = (stage.stageHeight - msgText.height) * 0.5;
			}
			else if (msgPosition == "topRight")
			{
				msgText.x = stage.stageWidth - msgText.width;
				msgText.y = 0;
			}
		}
	}
	
	private function hideMsg():Void
	{
		if (msgText != null)
		{
			this.removeChild(msgText);
			msgText = null;
		}
	}
	
	override public function update():Void
	{
		super.update();
		
		if(stats != null)
			stats.setGpuInfo(mRenderer.getStatistics().totalTriangle, mRenderer.getStatistics().renderTriangle, mRenderer.getStatistics().drawCount);
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