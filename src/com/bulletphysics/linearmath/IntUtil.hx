package com.bulletphysics.linearmath;

/**
 * ...
 * @author weilichuang
 */
class IntUtil
{
	public static inline function floorToInt(val:Float):Int
	{
		var i:Int =  Std.int(val);
        return (val < 0 && val != i) ? i - 1 : i;
    }
	
}