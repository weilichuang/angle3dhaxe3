package org.angle3d.utils;
	
import flash.display.Sprite;
import flash.display.Stage;
import flash.events.Event;
import flash.system.System;
import flash.text.StyleSheet;
import flash.text.TextField;
import flash.xml.XML;
import flash.xml.XMLList;


class Stats extends Sprite 
{
	public static inline function show(stage:Stage):Void
	{
		var stats:Stats = new Stats();
		stats.x = stage.stageWidth - GRAPH_WIDTH;
		stage.addChild(stats);
	}
	
	public static inline var bgCSS : String = "#000033";
	public static inline var fpsCSS : String = "#ffff00";
	public static inline var msCSS : String = "#00ff00";
	public static inline var memCSS : String = "#00ffff";
	public static inline var memmaxCSS : String = "#ff0070";

	static inline var GRAPH_WIDTH : Int = 100;
	static inline var GRAPH_HEIGHT : Int = 90;

	private var xml : XML;

	private var text : TextField;
	private var style : StyleSheet;

	private var timer : Int;
	private var fps : Int;
	private var ms : Int;
	private var ms_prev : Int;
	private var mem : Float;
	private var mem_max : Float;

	private var _stage:Stage;

	public function new() 
	{
		super();
		
		mem_max = 0;
		fps = 0;

		xml = new XML("<xml><fps>FPS:</fps><ms>MS:</ms><mem>MEM:</mem><tri>TRI:</tri><cur>CUR:</cur><draw>DRA:</draw></xml>");

		style = new StyleSheet();
		style.setStyle('xml', {fontSize:'12px', fontFamily:'_sans', leading:'-2px'});
		style.setStyle('fps', {color: fpsCSS });
		style.setStyle('ms', {color: msCSS });
		style.setStyle('mem', {color: memCSS });
		style.setStyle('tri', { color: memmaxCSS } );
		style.setStyle('cur', { color: msCSS } );
		style.setStyle('draw', {color: memCSS });
		
		text = new TextField();
		text.width = GRAPH_WIDTH;
		text.height = GRAPH_HEIGHT;
		text.styleSheet = style;
		text.condenseWhite = true;
		text.selectable = false;
		text.mouseEnabled = false;

		this.addEventListener(Event.ADDED_TO_STAGE, init, false, 0, true);
		this.addEventListener(Event.REMOVED_FROM_STAGE, destroy, false, 0, true);
	}

	private function init(e : Event):Void  
	{
		_stage = flash.Lib.current.stage;
		graphics.beginFill(0x888888, 0.8);
		graphics.drawRect(0, 0, GRAPH_WIDTH, GRAPH_HEIGHT);
		graphics.endFill();

		this.addChild(text);

		this.addEventListener(Event.ENTER_FRAME, update);
	}

	private function destroy(e : Event):Void  
	{
		graphics.clear();
		
		removeChildren();		
		
		removeEventListener(Event.ENTER_FRAME, update);
	}

	private function update(e : Event):Void 
	{
		timer = flash.Lib.getTimer();
		
		//after a second has passed 
		if ( timer - 1000 > ms_prev ) 
		{
			mem = System.totalMemory * 0.000000954;
			mem_max = mem_max > mem ? mem_max : mem;

			xml.fps = new XMLList("FPS: " + fps + " / " + stage.frameRate); 
			xml.mem = new XMLList("MEM: " + Std.int(mem) + "/" + Std.int(mem_max) + "MB");		
			xml.tri = new XMLList("TRI: " + Angle3D.totalTriangle);	
			xml.cur = new XMLList("CUR: " + Angle3D.renderTriangle);	
			xml.draw = new XMLList("DRA: " + Angle3D.drawCount);

			//reset frame and time counters
			fps = 0;
			ms_prev = timer;

			return;
		}
		//increment number of frames which have occurred in current second
		fps++;

		xml.ms = new XMLList("MS: " + (timer - ms));
		ms = timer;
		
		text.htmlText = xml.toString();
	}
}