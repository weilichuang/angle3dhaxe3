package angle3d.cinematic;

/**
 * The play state of a cinematic event
 */
@:enum abstract PlayState(Int) {
	/**The CinematicEvent is currently beeing played*/
	var Playing = 0;
	/**The animatable has been paused*/
	var Paused = 1;
	/**the animatable is stoped*/
	var Stopped = 2;
}

