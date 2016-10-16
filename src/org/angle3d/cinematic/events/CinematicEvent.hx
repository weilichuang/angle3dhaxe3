package org.angle3d.cinematic.events;

import org.angle3d.cinematic.LoopMode;
import org.angle3d.app.LegacyApplication;
import org.angle3d.cinematic.PlayState;
import org.angle3d.cinematic.Cinematic;

interface CinematicEvent
{
	/**
	 * Starts the animation
	 */
	function play():Void;

	/**
	 * Stops the animation
	 */
	function stop():Void;
	
	/**
     * this method can be implemented if the event needs different handling when 
     * stopped naturally (when the event reach its end)
     * or when it was forced stopped during playback
     * otherwise it just call regular stop()
     */
	function forceStop():Void;

	/**
	 * Pauses the animation
	 */
	function pause():Void;

	/**
	 * Returns the actual duration of the animation
	 */
	function getDuration():Float;

	/**
	 * Sets the speed of the animation (1 is normal speed, 2 is twice faster)
	 * @param speed
	 */
	function setSpeed(speed:Float):Void;

	/**
	 * returns the speed of the animation
	 * @return
	 */
	function getSpeed():Float;

	/**
	 * returns the PlayState of the animation
	 * @return
	 */
	function getPlayState():PlayState;

	/**
	 * @param loopMode set_the loop mode for the channel. The loop mode
	 * determines what will happen to the animation once it finishes
	 * playing.
	 *
	 * For more information, see the LoopMode enum class.
	 * @see LoopMode
	 */
	function setLoopMode(loop:LoopMode):Void;

	/**
	 * @return The loop mode currently set_for the animation. The loop mode
	 * determines what will happen to the animation once it finishes
	 * playing.
	 *
	 * For more information, see the LoopMode enum class.
	 * @see LoopMode
	 */
	function getLoopMode():LoopMode;

	/**
	 * returns the initial duration of the animation at speed = 1 in seconds.
	 * @return
	 */
	function getInitialDuration():Float;

	/**
	 * Sets the duration of the antionamtion at speed = 1 in seconds
	 * @param initialDuration
	 */
	function setInitialDuration(initialDuration:Float):Void;

	/**
	 * called internally in the update method, place here anything you want to run in the update loop
	 * @param tpf time per frame
	 */
	function internalUpdate(tpf:Float):Void;

	/**
	 * initialize this event
	 * @param app the application
	 * @param cinematic the cinematic
	 */
	function initEvent(app:LegacyApplication, cinematic:Cinematic):Void;

	/**
	 * When this method is invoked, the event should fast forward to the given time according tim 0 is the start of the event.
	 * @param time the time to fast forward to
	 */
	function setTime(time:Float):Void;

	/**
	 * returns the current time of the cinematic event
	 * @return the time
	 */
	function getTime():Float;
	
	function dispose():Void;
}


