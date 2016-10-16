package org.angle3d.cinematic.events;
import org.angle3d.signal.Signal;

import org.angle3d.signal.Signal.Signal1;
import org.angle3d.app.LegacyApplication;
import org.angle3d.cinematic.Cinematic;
import org.angle3d.cinematic.LoopMode;
import org.angle3d.cinematic.PlayState;
import org.angle3d.utils.TimerUtil;
import org.angle3d.animation.AnimationUtils;

/**
 * This calls contains basic behavior of a cinematic event
 * every cinematic event must extend this class
 *
 * A cinematic event must be given an inital duration in seconds (duration of the event at speed = 1) (default is 10)
 */
class AbstractCinematicEvent implements CinematicEvent
{
	public var onPlaySignal(get, never):Signal1<AbstractCinematicEvent>;
	public var onPauseSignal(get, never):Signal1<AbstractCinematicEvent>;
	public var onStopSignal(get, never):Signal1<AbstractCinematicEvent>;
	
	private var playState:PlayState = PlayState.Stopped;
	private var loopMode:LoopMode;
	private var initialDuration:Float = 10;
	private var speed:Float = 1;
	private var time:Float = 0;
	private var resuming:Bool = false;
	
	private var _onPlaySignal:Signal1<AbstractCinematicEvent>;
	private var _onPauseSignal:Signal1<AbstractCinematicEvent>;
	private var _onStopSignal:Signal1<AbstractCinematicEvent>;

	public function new(initialDuration:Float = 10, mode:LoopMode = LoopMode.Loop)
	{
		this.initialDuration = initialDuration;
		this.loopMode = mode;

		_initSignals();
	}
	
	/**
     * Implement this method if the event needs different handling when 
     * stopped naturally (when the event reach its end),
     * or when it was force-stopped during playback.
     * By default, this method just calls regular stop().
     */
    public function forceStop():Void
	{
        stop();
    }

	private function _initSignals():Void
	{
		_onPlaySignal = new Signal1<AbstractCinematicEvent>();
		_onPauseSignal = new Signal1<AbstractCinematicEvent>();
		_onStopSignal = new Signal1<AbstractCinematicEvent>();
	}

	private function get_onPlaySignal():Signal1<AbstractCinematicEvent>
	{
		return _onPlaySignal;
	}

	private function get_onPauseSignal():Signal1<AbstractCinematicEvent>
	{
		return _onPauseSignal;
	}

	private function get_onStopSignal():Signal1<AbstractCinematicEvent>
	{
		return _onStopSignal;
	}

	public function play():Void
	{
		onPlay();

		playState = PlayState.Playing;

		_onPlaySignal.dispatch(this);
	}

	/**
     * Implement this method with code that you want to execute when the event is started.
     */
	public function onPlay():Void
	{

	}

	public function internalUpdate(tpf:Float):Void
	{
		if (playState == PlayState.Playing)
		{
			time = time + tpf * speed;

			onUpdate(tpf);

			if (time >= initialDuration && loopMode == LoopMode.DontLoop)
			{
                stop();
            } 
			else if (time >= initialDuration && loopMode == LoopMode.Loop)
			{
                setTime(0);
            }
			else
			{
                time = AnimationUtils.clampWrapTime(time, initialDuration, loopMode);
                if (time < 0)
				{
                    speed = - speed;
                    time = - time;
                }
            }
		}

	}

	/**
     * Implement this method with the code that you want to execute on update 
     * (only called when the event is playing).
     * @param tpf time per frame
     */
	public function onUpdate(tpf:Float):Void
	{

	}

	/**
	 * stops the animation, next time play() is called the animation will start from the begining.
	 */
	public function stop():Void
	{
		onStop();

		time = 0;
		playState = PlayState.Stopped;

		_onStopSignal.dispatch(this);
	}

	/**
     * Implement this method with code that you want to execute when the event is stopped.
     */
	public function onStop():Void
	{

	}

	/**
     * Pause this event.
     * Next time when play() is called, the animation restarts from here.
     */
	public function pause():Void
	{
		onPause();

		playState = PlayState.Paused;

		_onPauseSignal.dispatch(this);
	}

	/**
     * Implement this method with code that you want to execute when the event is paused.
     */
	public function onPause():Void
	{

	}

	/**
	 * returns the actual duration of the animtion (initialDuration/speed)
	 * @return
	 */
	public function getDuration():Float
	{
		return initialDuration / speed;
	}

	/**
	 * Sets the speed of the animation.
	 * At speed = 1, the animation will last initialDuration seconds,
	 * At speed = 2 the animation will last initialDuraiton/2...
	 * @param speed
	 */
	public function setSpeed(speed:Float):Void
	{
		this.speed = speed;
	}

	/**
	 * returns the speed of the animation.
	 * @return
	 */
	public function getSpeed():Float
	{
		return speed;
	}

	/**
	 * Returns the current playstate of the animation
	 * @return
	 */
	public function getPlayState():PlayState
	{
		return playState;
	}

	/**
	 * returns the initial duration of the animation at speed = 1 in seconds.
	 * @return
	 */
	public function getInitialDuration():Float
	{
		return initialDuration;
	}

	/**
	 * Sets the duration of the antionamtion at speed = 1 in seconds
	 * @param initialDuration
	 */
	public function setInitialDuration(initialDuration:Float):Void
	{
		this.initialDuration = initialDuration;
	}

	/**
	 * retursthe loopMode of the animation
	 * @see LoopMode
	 * @return
	 */
	public function getLoopMode():LoopMode
	{
		return loopMode;
	}

	/**
	 * Sets the loopMode of the animation
	 * @see LoopMode
	 * @param loopMode
	 */
	public function setLoopMode(loopMode:LoopMode):Void
	{
		this.loopMode = loopMode;
	}

	public function initEvent(app:LegacyApplication, cinematic:Cinematic):Void
	{

	}

	/**
	 * When this method is invoked, the event should fast forward to the given time according tim 0 is the start of the event.
	 * @param time the time to fast forward to
	 */
	public function setTime(time:Float):Void
	{
		this.time = time;
	}

	/**
	 * 已运行时间(秒)
	 * @return
	 */
	public function getTime():Float
	{
		return time;
	}
	
	public function dispose():Void
	{
		
	}
}

