package com.bulletphysics.util;
import haxe.ds.Vector;

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
	
	public function get(index:Int):Int
	{
		return array[index];
	}
	
	public function set(index:Int, value:Int):Void
	{
		if (index < 0 || index >= _size) 
			throw "IndexOutOfBoundsException";
		array[index] = value;
	}
	
	public function size():Int
	{
		return _size;
	}

	//TODO clear不清除元素的吗？
	public function clear():Void
	{
		_size = 0;
	}
}