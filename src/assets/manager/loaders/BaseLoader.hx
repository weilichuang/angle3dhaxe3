package assets.manager.loaders;
import assets.manager.loaders.BaseLoader;
import haxe.Timer;
import flash.display.BitmapData;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.media.Sound;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.utils.ByteArray;
import assets.manager.misc.FileType;
import assets.manager.misc.LoaderStatus;

class BaseLoader extends EventDispatcher {

	/** The default loader, set to null to use other loader instead */
    var loader:URLLoader;
	
	public var type(default, null):FileType;
	public var id(default, null):String;
	public var data(default, null):Dynamic;
	public var status(default, null):LoaderStatus;
	public var error(default, null):String;
	
	function new(id:String, type:FileType) {
		super();
		this.id = id;
		this.data = null;
		this.type = type;
		status = LoaderStatus.IDLE;
		loader = new URLLoader();
        loader.addEventListener(Event.COMPLETE, handleComplete);
		loader.addEventListener(IOErrorEvent.IO_ERROR, onLoadFail);
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadFail);
	}
	
	function handleComplete(e:Event) {
		processData();
		status = LoaderStatus.LOADED;
        dispatchEvent(new Event(Event.COMPLETE));
    }
	
	function onLoadFail(e:ErrorEvent) {
		data = null;
		error = e.toString();
		status = LoaderStatus.ERROR;
		dispatchEvent(new Event(Event.COMPLETE));
	}
	
	function processData() {
		data = loader.data;
	}
	
	public function prepare() {
		status = LoaderStatus.READY;
	}
	
	public function reset(dispose:Bool) {
		status = LoaderStatus.IDLE;
		data = null;
        loader.data = null;
	}
	
	public function start() {
		this.status = LoaderStatus.LOADING;
		loader.load(new URLRequest(id));
	}
	
}