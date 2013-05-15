package org.angle3d.utils;
import flash.Lib;

class Logger
{
	public static inline function log(message:Dynamic):Void
	{
		#if debug
			Lib.trace(message);
		#end
	}

	public static inline function warn(message:Dynamic):Void
	{
		#if debug
			Lib.trace(message);
		#end
	}
}

