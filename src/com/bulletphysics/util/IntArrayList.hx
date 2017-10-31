package com.bulletphysics.util;

import org.angle3d.error.Assert;
import org.angle3d.utils.VectorUtil;
class IntArrayList
{
	private var array:Array<Int>;
	private var _capacity:Int;
	private var _size:Int;

	public function new(initialCapacity:Int = 16) 
	{
		this._capacity = initialCapacity;
		this._size = 0;
		this.array = new Array<Int>(_capacity, true);
	}
	
	public inline function add(value:Int):Bool
	{
		if (_size == _capacity)
		{
			expand();
		}
		
		array[_size++] = value;
		return true;
	}
	
	private inline function expand():Void
	{
		_capacity = _capacity << 1;
		array.fixed = false;
		array.length = _capacity;
		array.fixed = true;
	}
	
	public inline function remove(index:Int):Int
	{
		#if debug
		if (index < 0 || index >= _size) 
			throw "IndexOutOfBoundsException";
		#end
		
		var prev:Int = array[index];
		VectorUtil.blit(array, index + 1, array, index, _size - index - 1);
		_size--;
		return prev;
	}
	
	public inline function get(index:Int):Int
	{
		return array[index];
	}
	
	public inline function set(index:Int, value:Int):Int
	{
		#if debug
		Assert.assert(index >= 0 && index < _size);
		#end

		array[index] = value;
		
		return value;
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