package org.angle3d.utils;

/**
	This is similar to `StringMap` excepts that it does not sanitize the keys.
	As a result, it will be faster to access the map for reading, but it might fail
	with some reserved keys such as `constructor` or `prototype`.
**/
class FastStringMap<T>
{
	private var h : flash.utils.Dictionary;
	private var _size:Int;

	public function new() : Void 
	{
		h = new flash.utils.Dictionary();
		_size = 0;
	}
	
	public function clear():Void
	{
		//var a:Array<String> = untyped __keys__(h);
		//for (key in a) untyped __delete__(h, key);
		//_size = 0;
		
		h = new flash.utils.Dictionary();
		_size = 0;
	}

	public inline function set( key : String, value : T ) : Void
	{
		if (!exists(key))
		{
			_size++;
		}
		untyped h[key] = value;
	}

	public inline function get( key : String ) : Null<T> 
	{
		return untyped h[key];
	}

	public inline function exists( key : String ) : Bool 
	{
		return untyped __in__(key,h);
	}

	public function remove( key : String ) : Bool
	{
		if ( untyped !h.hasOwnProperty(key) ) 
			return false;
			
		untyped __delete__(h, key);
		_size--;
		return true;
	}
	
	public inline function size():Int
	{
		return _size;
	}

	public function keys() : Array<String>
	{
		return untyped (__keys__(h));
	}

	//public function iterator() : Iterator<T> 
	//{
		//return untyped {
			//ref : h,
			//it : __keys__(h).iterator(),
			//hasNext : function() { return __this__.it.hasNext(); },
			//next : function() { var i : Dynamic = __this__.it.next(); return __this__.ref[i]; }
		//};
	//}
}
