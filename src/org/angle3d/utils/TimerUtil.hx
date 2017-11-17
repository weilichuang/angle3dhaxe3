package org.angle3d.utils;

import haxe.Timer;


class TimerUtil
{
	/**
	 * 以秒为单位返回当前运行时间
	 * @return
	 */
	public static inline function getTimeInSeconds():Float
	{
		return Timer.stamp();
	}
}

