package angle3d.asset;

class WaitList {
	public var length(get, never):Int;
	public var data(get, never):Array<WaitInfo>;

	private var _waitArray:Array<WaitInfo>;

	public function new() {
		_waitArray = [];
	}

	private function get_data():Array<WaitInfo> {
		return _waitArray;
	}

	private function get_length():Int {
		return _waitArray.length;
	}

	public function addInfo(info:WaitInfo):Void {
		_waitArray.push(info);
	}

	public function sortPriority() : Void {
		_waitArray.sort(sortArray);
	}

	private function sortArray(a:WaitInfo, b:WaitInfo):Int {
		if (a.priority < b.priority)
			return 1;
		else if (a.priority > b.priority)
			return -1;
		else
			return 0;
	}

	public function clear() : Void {
		for ( i in 0..._waitArray.length ) {
			var info : WaitInfo = _waitArray[i];
			info.dispose();
		}
		_waitArray = [];
	}

	public function hasWaitInfo( url : String ) : Bool {
		for ( i in 0..._waitArray.length ) {
			var info : WaitInfo = _waitArray[i];
			if ( info.url == url ) {
				return true;
			}
		}
		return false;
	}

	public function getWaitInfo( url : String, type : String ) : WaitInfo {
		for ( i in 0..._waitArray.length ) {
			var info : WaitInfo = _waitArray[i];
			if ( info.url == url && info.type == type ) {
				return info;
			}
		}
		return null;
	}

	public function getWaitInfos( url : String, result : Array<WaitInfo> = null ) : Array<WaitInfo> {
		if ( result == null )
			result = [];
		for ( i in 0..._waitArray.length ) {
			var info : WaitInfo = _waitArray[i];
			if ( info.url == url ) {
				result.push(info);
			}
		}
		return result;
	}

	public function remove( url : String, type : String, complete : Dynamic ) : Void {
		var len : Int = length;
		var i:Int = 0;
		while (i < len) {
			var info : WaitInfo = _waitArray[ i ];
			if ( info.url == url ) {
				if (info.itemMap.exists(complete)) {
					var item : LoadingItemInfo = info.itemMap.get(complete);
					if ( item != null ) {
						info.itemMap.remove(complete);
						item.dispose();
					}

					if ( info.itemMap.size() == 0 ) {
						_waitArray.splice(i, 1);
						i--;
						len--;
						info.dispose();
					}
				}
				return;
			}
			i++;
		}
	}

	public function removeUrl( url : String ) : Array<WaitInfo> {
		var len : Int = _waitArray.length;
		var result : Array<WaitInfo> = [];
		var i:Int = 0;
		while (i < len) {
			var info : WaitInfo = _waitArray[ i ];
			if ( info.url == url ) {
				_waitArray.splice( i, 1 );
				result.push(info);
				i--;
				len--;
			}
			i++;
		}
		return result;
	}

	public function removeUrlType( url : String, type : String ) : WaitInfo {
		var len : Int = _waitArray.length;
		var i:Int = 0;
		while (i < len) {
			var info : WaitInfo = _waitArray[ i ];
			if ( info.url == url && info.type == type ) {
				_waitArray.splice( i, 1 );
				return info;
			}
			i++;
		}
		return null;
	}
}
