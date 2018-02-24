package angle3d.cinematic;

/**
 * `LoopMode` determines how animations repeat, or if they
 * do not repeat.
 */
@:enum abstract LoopMode(Int) {

	/**
	 * The animation will play repeatedly, when it reaches the end
	 * the animation will play again from the beginning, and so on.
	 */
	var Loop = 0;

	/**
	 * The animation will not loop. It will play until the last frame, and then
	 * freeze at that frame. It is possible to decide to play a new animation
	 * when that happens by using a AnimEventListener.
	 */
	var DontLoop = 1;

	/**
	 * The animation will cycle back and forth. When reaching the end, the
	 * animation will play backwards from the last frame until it reaches
	 * the first frame.
	 */
	var Cycle = 2;
}

