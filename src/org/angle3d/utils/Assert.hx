package org.angle3d.utils;
import flash.errors.Error;

class Assert
{
	/**
	 * 
	 * @param	condition 为false时报错
	 * @param	info
	 */
	public static inline function assert(condition:Bool, info:String = ""):Void
	{
		#if debug
			if (!condition)
				throw new Error(info);
		#end
	}
}


