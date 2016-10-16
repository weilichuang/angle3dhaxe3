package org.angle3d.asset;

import flash.utils.Dictionary;

class HashSet
{
	private var _map:Dictionary;
	private var _length : Int;
	
	public var length(get, never):Int;

	public function new( weakKeys : Bool = false ) 
	{
		_map = new Dictionary(weakKeys);
	}

	private function get_length() : Int
	{
		return _length;
	}

	public function add( o : Dynamic ) : Void 
	{
		if ( o == null )
		{
			return;
		}
		if (!contains(o))
		{
			_length++;
		}
		untyped _map[o] = o;
	}

	public function contains( o : Dynamic ) : Bool
	{
		return untyped __in__(o,_map);
	}

	public function remove( o : Dynamic) : Bool
	{
		if ( contains(o) )
		{
			untyped __delete__(_map, o);
			_length--;
			return true;
		}
		return false;
	}
}
