package angle3d.animation;

import angle3d.utils.TempVars;

interface Track {
	/**
	 * Sets the time of the animation.
	 *
	 * Internally, the track will retrieve objects from the control
	 * and modify them according to the properties of the channel and the
	 * given parameters.
	 *
	 * @param time The time in the animation
	 * @param weight The weight from 0 to 1 on how much to apply the track
	 * @param control The control which the track should effect
	 * @param channel The channel which the track should effect
	 */
	function setTime(time:Float, weight:Float, control:AnimControl, channel:AnimChannel):Void;

	/**
	 * @return the time of the track
	 */
	function getLength():Float;

	/**
	 * This method creates a clone of the current object.
	 * @return a clone of the current object
	 */
	function clone():Track;

	/**
	 * Get the times in seconds for all keyframes.
	 *
	 * All keyframe times should be between 0.0 and {#getLength() length}.
	 * Modifying the provided array is not allowed, as it may corrupt internal
	 * state.
	 *
	 * @return the keyframe times
	 */
	function getKeyFrameTimes():Array<Float>;
}

