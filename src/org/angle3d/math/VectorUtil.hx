package org.angle3d.math;

import flash.Vector;

class VectorUtil
{
	public static inline function clear<T>(list:Vector<T>):Vector<T>
	{
		#if flash
			untyped list.length = 0;
		#else
			list = new Vector<T>();
		#end
		
		return list;
	}

	public static inline function remove<T>(list:Vector<T>, item:T):Bool
	{
		var index:Int = list.indexOf(item);
		if (index != -1)
		{
			list.splice(index, 1);
			return true;
		}
		else
		{
			return false;
		}
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
		Reflect.callMethod(target, target.splice, [position, 0, item]);
	}
}


