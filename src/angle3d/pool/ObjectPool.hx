package angle3d.pool;

@:generic
class ObjectPool<T> {

	private var _type:Class<T>;

	private var _cursor:Int;

	private var _pool:Array<T>;

	public var capacity(get, never):Int;

	public function new(cls:Class<T>) {
		_type = cls;
		_pool = new Array<T>();
		_cursor = 0;
	}

	public function gc() : Void {
		_cursor = _pool.length;
	}

	private inline function get_capacity() : Int {
		return _pool.length;
	}

	public function shrink() : Void {
		_pool.length = 0;
		_cursor = 0;
	}

	private function allocInternal() : T {
		var result:T = null;
		if (_cursor > 0) {
			result = _pool[--_cursor];
		} else
		{
			result = Type.createEmptyInstance(_type);
			_pool.push(result);
		}
		return result;
	}
}
