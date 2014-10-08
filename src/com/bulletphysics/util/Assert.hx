package com.bulletphysics.util;

/**
 * ...
 * @author weilichuang
 */
class Assert
{

	public function new() 
	{
		
	}
	
	public static inline function assert(value:Bool):Void
	{
		#if debug
		if (!value)
		   throw "assert error";
		#end
	}
	
}