package angle3d.asset.caches;
import flash.utils.Dictionary;
import haxe.ds.StringMap;

import angle3d.asset.AssetInfo;

class RefCache extends BaseCache {
	private var _needDisposeContent : Bool;
	private var _keepNoUseTimeSpan : Int; //最少不用了多久之后再回收

	/**
	 *
	 * @param maximum
	 * @param keepNoUseTimeSpan 保持未引的对象时间 （秒）
	 * @param needDisposeContent
	 */
	public function new( maximum : Int = 100, keepNoUseTimeSpan : Int = 30, needDisposeContent : Bool = true ) {
		super( maximum, true );
		_keepNoUseTimeSpan = keepNoUseTimeSpan * 1000;
		_needDisposeContent = needDisposeContent;
	}

	override public function clear() : Void {
		for ( info in _list ) {
			if ( _needDisposeContent )
				disposeAssetInfo( info );
			info.dispose();
		}
		_list = [];
		_indexDic = new StringMap<AssetInfo>();
	}

	private function disposeAssetInfo( info : AssetInfo ) : Void {
		if ( info.content != null ) {
			if (info.content.hasOwnProperty("dispose"))
				info.content.dispose();
		}
	}
}
