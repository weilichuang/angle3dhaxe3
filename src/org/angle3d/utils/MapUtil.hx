package org.angle3d.utils;

/**
 * ...
 * @author weilichuang
 */
class MapUtil
{

	public static function getSize<K,V>(map:Map<K,V>):Int
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