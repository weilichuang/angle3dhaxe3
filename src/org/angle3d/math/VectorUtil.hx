package org.angle3d.math;

import flash.Vector;

class VectorUtil
{
	public static inline function clear<T>(list:Vector<T>):Void
	{
		untyped list.length = 0;
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

	//public static function insert(target:Vector<Float>, position:Int, inserts:Vector<Float>):Void
	//{
		//var lefts:Vector<Float> = target.splice(position, target.length - position);
		//
		//var length:Int = inserts.length;
		//for (i in 0...length)
		//{
			//target.push(inserts[i]);
		//}
//
		//length = lefts.length;
		//for (i in 0...length)
		//{
			//target.push(lefts[i]);
		//}
	//}
}

