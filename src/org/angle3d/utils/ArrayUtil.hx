package org.angle3d.utils;

class ArrayUtil
{
	public static inline function contains<T>(list:Array<T>, item:T):Bool
	{
		return list.indexOf(item) != -1;
	}
}