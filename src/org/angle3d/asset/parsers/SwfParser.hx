package org.angle3d.asset.parsers;
import flash.events.Event;

import org.angle3d.asset.AssetInfo;

class SwfParser extends LoaderParser {
	public function new() {
		super();
	}

	override private function onLoaderComplete( event : Event ) : Void {
		notifyComplete( new AssetInfo( _url, _type, _loader.content ));
	}
}
