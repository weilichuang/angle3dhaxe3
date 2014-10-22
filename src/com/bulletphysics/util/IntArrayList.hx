package com.bulletphysics.util;
import haxe.ds.Vector;
import de.polygonal.ds.error.Assert;

class IntArrayList
{
	private var array:Vector<Int>;
	private var _size:Int;

	public function new(initialCapacity:Int = 16) 
	{
		this.array = new Vector<Int>(initialCapacity);
		this._size = 0;
	}
	
	public function add(value:Int):Bool
	{
		if (_size == array.length)
		{
			expand();
		}
		
		array[_size++] = value;
		return true;
	}
	
	private function expand():Void
	{
		var newArray:Vector<Int> = new Vector<Int>(array.length << 1);
		Vector.blit(array, 0, newArray, 0, array.length);
		array = newArray;
	}
	
	public function remove(index:Int):Int
	{
		if (index < 0 || index >= _size) 
			throw "IndexOutOfBoundsException";
		
		var prev:Int = array[index];
		Vector.blit(array, index + 1, array, index, _size - index - 1);
		_size--;
		return prev;
	}
	
	public inline function get(index:Int):Int
	{
		return array[index];
	}
	
	public inline function set(index:Int, value:Int):Void
	{
		#if debug
		Assert.assert(index >= 0 && index < _size);
		#end

		array[index] = value;
	}
	
	public inline function size():Int
	{
		return _size;
	}

	public inline function clear():Void
	{
		_size = 0;
	}
}