package com.bulletphysics.util;
import flash.Vector;
import org.angle3d.math.VectorUtil;
class FloatArrayList
{
	private var array:Vector<Float>;
	private var _size:Int;

	public function new(initialCapacity:Int = 16) 
	{
		this.array = new Vector<Float>(initialCapacity);
		this._size = 0;
	}
	
	public function add(value:Float):Bool
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
		var newArray:Vector<Float> = new Vector<Float>(array.length << 1);
		VectorUtil.blit(array, 0, newArray, 0, array.length);
		array = newArray;
	}
	
	public function remove(index:Int):Float
	{
		#if debug
		if (index < 0 || index >= _size) 
			throw "IndexOutOfBoundsException";
		#end
		
		var prev:Float = array[index];
		VectorUtil.blit(array, index + 1, array, index, _size - index - 1);
		_size--;
		return prev;
	}
	
	public inline function get(index:Int):Float
	{
		return array[index];
	}
	
	public inline function set(index:Int, value:Float):Void
	{
		#if debug
		if (index < 0 || index >= _size) 
			throw "IndexOutOfBoundsException";
		#end
		
		array[index] = value;
	}
	
	public inline function size():Int
	{
		return _size;
	}

	//TODO clear不清除元素的吗？
	public inline function clear():Void
	{
		_size = 0;
	}
}