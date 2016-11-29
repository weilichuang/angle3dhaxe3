package org.angle3d.animation;
import org.angle3d.cinematic.LoopMode;

class AnimationUtils
{

	/**
	 * Clamps the time according to duration and loopMode
	 * @param	time
	 * @param	duration
	 * @param	loopMode
	 * @return
	 */
	public static function clampWrapTime(time:Float, duration:Float, loopMode:LoopMode):Float
	{
		if (time == 0) 
		{
            return 0; // prevent division by 0 errors
        }   
		
		switch (loopMode)
		{
			case LoopMode.Cycle:
                var sign:Bool = (Std.int(time / duration) % 2) != 0;
                return sign ? -(duration - (time % duration)) : time % duration;
            case LoopMode.DontLoop:
                return time > duration ? duration : (time < 0 ? 0 : time);
            case LoopMode.Loop:
                return time % duration;
		}

		return time;
	}
	
}