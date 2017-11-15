package org.angle3d.asset;

class LoaderPool {
	private static var _list : Array<StreamLoader> = [];

	public static function output() : StreamLoader {
		var loader : StreamLoader;
		if ( _list.length > 0 ) {
			loader = _list.pop();
			loader.clearTimeout();
		} else
		{
			loader = new StreamLoader();
		}
		return loader;
	}

	public static function input( loader : StreamLoader ) : Void {
		if ( _list.length < AssetManager.maxLoadNum ) {
			_list[ _list.length ] = loader;
		}
	}
}
