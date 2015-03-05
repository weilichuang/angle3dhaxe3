package org.angle3d.utils;
import haxe.ds.UnsafeStringMap;

/**
 * ...
 * @author weilichuang
 */
class MapUtil
{

	public static function getSize<V>(map:UnsafeStringMap<V>):Int
	{
		var size:Int = 0;
		var keys = map.keys();
		for (key in keys)
		{
			size++;
		}
		return size;
	}
	
}