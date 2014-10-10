package org.angle3d.utils;

class ArrayUtil
{
	//public static inline function clear<T>(list:Array<T>):Array<T>
	//{
		//#if (flash || js)
		//untyped list.length = 0;
		//#else
		//list = new Array<T>();
		//#end
		//return list;
	//}
	
	public static inline function contains<T>(list:Array<T>, item:T):Bool
	{
		return list.indexOf(item) != -1;
	}
}