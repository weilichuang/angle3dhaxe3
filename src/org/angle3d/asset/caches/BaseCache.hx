package org.angle3d.asset.caches;
import haxe.ds.StringMap;

import org.angle3d.asset.AssetInfo;

class BaseCache {
	private var _indexDic : StringMap<AssetInfo>;
	private var _list : Array<AssetInfo> = [];
	private var _maximum : Int;
	private var _useRefCount : Bool;

	public var useRefCount(get, never):Bool;
	public var maximum(get, set):Int;
	public var count(get, never):Int;
	public var assetInfos(get, never):Array<AssetInfo>;

	public function new( maximum : Int = 100, useRefCount : Bool = false ) {
		_indexDic = new StringMap<AssetInfo>();
		_maximum = maximum;
		_useRefCount = useRefCount;
	}

	public function getAssetInfo( url : String ) : AssetInfo {
		return _indexDic.get(url);
	}

	public function addAssetInfo( info : AssetInfo ) : Void {
		var length : Int = _list.length;
		if ( length > _maximum ) {
			var item : AssetInfo = _list.shift();
			_indexDic.remove(item.url);
			item.dispose();
		}
		_list[ _list.length ] = info;
		_indexDic.set(info.url, info);
	}

	public function clear() : Void {
		for ( item in _list ) {
			item.dispose();
		}
		_list = [];
		_indexDic = new StringMap<AssetInfo>();
	}

	private function get_useRefCount() : Bool {
		return _useRefCount;
	}

	private function get_maximum(): Int {
		return _maximum;
	}

	private function set_maximum( value : Int ) : Int {
		return _maximum = value;
	}

	private function get_count() : Int {
		return _list.length;
	}

	private function get_assetInfos() : Array<AssetInfo> {
		return _list;
	}
}
