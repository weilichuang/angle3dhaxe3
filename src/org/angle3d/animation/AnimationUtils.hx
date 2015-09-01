package org.angle3d.animation;
import org.angle3d.cinematic.LoopMode;

class AnimationUtils
{

	public static function clampWrapTime(time:Float, duration:Float, loopMode:Int):Float
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