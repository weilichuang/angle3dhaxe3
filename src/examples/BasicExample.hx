package examples;

import flash.filters.GlowFilter;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.utils.Stats;

class BasicExample extends SimpleApplication
{
	private var msgText:TextField;
	private var stats:Stats;

	public function new() 
	{
		super();
		Angle3D.ignoreSamplerFlag = true;
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		this.stats = Stats.show(stage);
	}
	
	override public function setSize(w:Int, h:Int):Void 
	{
		super.setSize(w, h);
		
		if (this.stats != null)
			this.stats.relayout(stage);
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
		
		var format:TextFormat = msgText.defaultTextFormat;
		format.size = size;
		format.color = color;
		format.bold = bold;
		
		msgText.defaultTextFormat = format;
			
		msgText.text = text;
		
		if (position == "topLeft")
		{
			msgText.x = 0;
			msgText.y = 0;
		}
		else if (position == "center")
		{
			msgText.x = (stage.stageWidth - msgText.width) * 0.5;
			msgText.y = (stage.stageHeight - msgText.height) * 0.5;
		}
		else if (position == "topRight")
		{
			msgText.x = stage.stageWidth - msgText.width;
			msgText.y = 0;
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
		
		stats.setGpuInfo(mRenderer.getStatistics().totalTriangle, mRenderer.getStatistics().renderTriangle, mRenderer.getStatistics().drawCount);
	}
	
	override public function simpleUpdate(tpf:Float):Void
	{
		super.simpleUpdate(tpf);
	}
}