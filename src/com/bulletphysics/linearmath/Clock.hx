package com.bulletphysics.linearmath;
import flash.Lib;

/**
 * Clock is a portable basic clock that measures accurate time in seconds, use for profiling.
 
 */
class Clock
{
	private var startTime:Int;

	public function new() 
	{
		this.reset();
	}
	
	public function reset():Void
	{
		startTime = Lib.getTimer();
	}
	
	public function getTimeMilliseconds():Int
	{
		return Lib.getTimer() - startTime;
	}
}