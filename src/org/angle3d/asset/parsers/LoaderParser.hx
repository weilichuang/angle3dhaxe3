package org.angle3d.asset.parsers;
import flash.display.Loader;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.system.ImageDecodingPolicy;
import flash.system.LoaderContext;

class LoaderParser extends BaseParser
{
	private var _loader : Loader;

	public function new() 
	{
		super();
	}

	override public function parse( url : String, data : Dynamic ) : Void
	{
		super.parse( url, data );
		if ( _loader == null )
		{
			_loader = new Loader();
			_loader.contentLoaderInfo.addEventListener( Event.COMPLETE, onLoaderComplete );
			_loader.contentLoaderInfo.addEventListener( IOErrorEvent.IO_ERROR, onLoaderError );
			_loader.contentLoaderInfo.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onLoaderError );
		}
		var context : LoaderContext = new LoaderContext();
		context.allowCodeImport = true;
		context.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;
		_loader.loadBytes( data, context );
	}

	override public function dispose() : Void 
	{
		_loader.contentLoaderInfo.removeEventListener( Event.COMPLETE, onLoaderComplete );
		_loader.contentLoaderInfo.removeEventListener( IOErrorEvent.IO_ERROR, onLoaderError );
		_loader.contentLoaderInfo.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, onLoaderError );
		_loader.unload();
		super.dispose();
	}

	private function onLoaderComplete( event : Event ) : Void
	{

	}

	private function onLoaderError( event : Event ) : Void 
	{
		notifyError();
	}
}
