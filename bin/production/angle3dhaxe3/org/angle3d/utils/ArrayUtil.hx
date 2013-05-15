package org.angle3d.utils;

/**
 * andy
 * @author 
 */
class ArrayUtil
{
	public static inline function clear<T>(list:Array<T>):Array<T>
	{
		#if (flash || js)
		untyped list.length = 0;
		#else
		list = new Array<T>();
		#end
		return list;
	}

	public static inline function indexOf<T>(list:Array<T>, item:T):Int
	{
		#if flash
			return untyped list.indexOf(item);
		#else
			return Lambda.indexOf(list, item);
		#end
	}
	
	public static inline function contain<T>(list:Array<T>, item:T):Bool
	{
		var index:Int = indexOf(list, item);
		return index != -1;
	}
	
	//public static inline function remove<T>(list:Array<T>, item:T):Bool
	//{
		//var index:Int = indexOf(list, item);
		//if (index != -1)
		//{
			//list.splice(index, 1);
			//return true;
		//}
		//return false;
	//}
	
}