package org.angle3d.utils;

class ArrayUtil
{
	public static inline function contains<T>(list:Array<T>, item:T):Bool
	{
		return list.indexOf(item) != -1;
	}
	
	public static function containsAll<T>(list:Array<T>, list1:Array<T>):Bool
	{
		if (list1.length == 0)
			return true;
		
		for (i in 0...list1.length)
		{
			if (list.indexOf(list1[i]) == -1)
			{
				return false;
			}
		}
		
		return true;
	}
}