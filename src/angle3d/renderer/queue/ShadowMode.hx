package angle3d.renderer.queue;

/**
 * `ShadowMode` is a marker used to specify how shadow
 * effects should treat the spatial.
 */
@:enum abstract ShadowMode(Int) {
	/**
	 * Disable both shadow casting and shadow receiving for this spatial.
	 * Generally used for special effects like particle emitters.
	 */
	var Off = 0;

	/**
	 * Enable casting of shadows but not receiving them.
	 */
	var Cast = 1;

	/**
	 * Enable receiving of shadows but not casting them.
	 */
	var Receive = 2;

	/**
	 * Enable both receiving and casting of shadows.
	 */
	var CastAndReceive = 3;

	/**
	 * Inherit the `ShadowMode` from the parent node.
	 */
	var Inherit = 4;
}

