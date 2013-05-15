package org.angle3d.utils;
import flash.Lib;


class TimerUtil
{
	/**
	 * 以秒为单位返回当前运行时间
	 * @return
	 */
	public static inline function getTimeInSeconds():Float
	{
		return Lib.getTimer() * 0.001;
	}
}

