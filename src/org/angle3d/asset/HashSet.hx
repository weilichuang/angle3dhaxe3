package org.angle3d.asset;

import haxe.ds.ObjectMap;

class HashSet {
	private var _map:ObjectMap<Dynamic,Dynamic>;
	private var _length : Int;

	public var length(get, never):Int;

	public function new() {
		_map = new ObjectMap<Dynamic,Dynamic>();
	}

	private function get_length() : Int {
		return _length;
	}

	public function add( o : Dynamic ) : Void {
		if ( o == null ) {
			return;
		}
		if (!contains(o)) {
			_length++;
		}
		_map[o] = o;
	}

	public function contains( o : Dynamic ) : Bool {
		return _map.exists(o);
	}

	public function remove( o : Dynamic) : Bool {
		if ( contains(o) ) {
			_map.remove(o);
			_length--;
			return true;
		}
		return false;
	}
}
