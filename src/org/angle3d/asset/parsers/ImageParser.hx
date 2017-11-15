package org.angle3d.asset.parsers;
import flash.display.Bitmap;
import flash.events.Event;
import org.angle3d.asset.AssetInfo;

class ImageParser extends LoaderParser {
	public function new() {
		super();
	}

	override private function onLoaderComplete( event : Event ) : Void {
		var bm : Bitmap = cast _loader.content;
		notifyComplete( new AssetInfo( _url, _type, bm.bitmapData ));
	}
}
