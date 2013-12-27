package org.angle3d.utils;
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
	
}