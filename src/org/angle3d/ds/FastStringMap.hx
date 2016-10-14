package org.angle3d.ds;

import flash.utils.Dictionary;

class FastStringMap<T>
{
	private var _map : Dictionary;
	private var _keys:Array<String>;
	private var _size:Int;

	public function new() : Void 
	{
		_map = new Dictionary();
		_keys = [];
		_size = 0;
	}
	
	public function clear():Void
	{
		//var a:Array<String> = untyped __keys__(_map);
		
		for (key in _keys) 
			untyped __delete__(_map, key);
		_size = 0;
		untyped _keys.length = 0;
		
		//h = new flash.utils.Dictionary();
		//_size = 0;
	}

	public inline function set( key : String, value : T ) : Void
	{
		if (!exists(key))
		{
			_keys[_size] = key;
			_size++;
		}
		untyped _map[key] = value;
	}

	public inline function get( key : String ) : Null<T> 
	{
		return untyped _map[key];
	}

	public inline function exists( key : String ) : Bool 
	{
		return untyped __in__(key,_map);
	}

	public function remove( key : String ) : Bool
	{
		if (!exists(key)) 
			return false;
			
		untyped __delete__(_map, key);
		_keys.remove(key);
		_size--;
		return true;
	}
	
	public inline function size():Int
	{
		return _size;
	}

	public inline function keys() : Array<String>
	{
		return _keys;// untyped (__keys__(_map));
	}
}
