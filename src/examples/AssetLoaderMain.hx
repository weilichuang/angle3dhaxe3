package examples;

import assets.manager.FileLoader;
import assets.manager.misc.FileInfo;
import flash.display.Sprite;
import flash.display.Bitmap;
import flash.events.Event;

import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.Lib;

class AssetLoaderMain extends Sprite 
{
        
    public static function main()
	{       
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
		
		var loader:FileLoader = new FileLoader();
		loader.queueText(baseURL + "test.txt");
		loader.queueText(baseURL + "test1.txt");
		loader.onFilesLoaded.addOnce(completeHandler);
		loader.loadQueuedFiles();
        
		//var loader:AssetLoader = new AssetLoader();
		//loader.signalSet.completed.addOnce(completeHandler);
		//loader.add(baseURL + "test.txt");
		//loader.add(baseURL + "test1.txt");
		//loader.execute();
    }
	
	private function completeHandler(infos:Array<FileInfo>):Void
	{
		for (i in 0...infos.length)
		{
			Lib.trace(infos[i].id);
		}
	}
}
