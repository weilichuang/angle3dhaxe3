package examples;

import flash.display.Sprite;
import flash.display.Bitmap;
import flash.events.Event;

import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.Lib;

import hu.vpmedia.assets.AssetLoader;

class AssetLoaderMain extends Sprite {
        
    public static function main() {       
        Lib.current.addChild ( new AssetLoaderMain() );
    }
    
    public function new()
    {
        super();
        Lib.current.addChild(this);   
        Lib.current.stage.align = StageAlign.TOP_LEFT;
        Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
        addEventListener(Event.REMOVED_FROM_STAGE,onRemovedHandler,false,0,true);
        initialize();
    }
    
    public function onRemovedHandler(event:Event):Void
    {
        removeEventListener(Event.REMOVED_FROM_STAGE,onRemovedHandler);
    }
    
    public function initialize():Void
    {
		var baseURL:String = "resource/";
        
		var loader:AssetLoader = new AssetLoader();
		loader.signalSet.completed.addOnce(completeHandler);
		loader.add(baseURL + "test.txt");
		loader.add(baseURL + "test1.txt");
		loader.execute();
    }
	
	private function completeHandler(assetLoader:AssetLoader):Void
	{
		Lib.trace(assetLoader.get("resource/test.txt"));
	}
}
