package org.angle3d.math;

import flash.Vector;

class VectorUtil
{
	/**
		Copies `length` of elements from `src` Vector, beginning at `srcPos` to
		`dest` Vector, beginning at `destPos`

		The results are unspecified if `length` results in out-of-bounds access,
		or if `src` or `dest` are null
	**/
	public static inline function blit<T>(src:Vector<T>, srcPos:Int, dest:Vector<T>, destPos:Int, len:Int):Void
	{
		for (i in 0...len)
		{
			dest[destPos + i] = src[srcPos + i];
		}
	}
	
	public static inline function remove<T>(list:Vector<T>, item:T):Bool
	{
		var index:Int = list.indexOf(item);
		if (index != -1)
		{
			list.splice(index, 1);
		}
		return index != -1;
	}
	
	public static inline function contain<T>(list:Vector<T>, item:T):Bool
	{
		return list.indexOf(item) != -1;
	}
	
	public static function fillFloat(target:Vector<Float>, value:Float):Void
	{
		var length:Int = target.length;
		for (i in 0...length)
		{
			target[i] = value;
		}
	}

	public static function fillInt(target:Vector<Int>, value:Int):Void
	{
		var length:Int = target.length;
		for (i in 0...length)
		{
			target[i] = value;
		}
	}
	
	public static function insert<T>(target:Vector<T>, position:Int, item:T):Void
	{
		untyped target["splice"](position, 0, item);
	}
}


