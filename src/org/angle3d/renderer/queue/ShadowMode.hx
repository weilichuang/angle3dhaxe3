package org.angle3d.renderer.queue;

/**
 * <code>ShadowMode</code> is a marker used to specify how shadow
 * effects should treat the spatial.
 */
enum ShadowMode
{
	/**
	 * Disable both shadow casting and shadow receiving for this spatial.
	 * Generally used for special effects like particle emitters.
	 */
	Off;

	/**
	 * Enable casting of shadows but not receiving them.
	 */
	Cast;

	/**
	 * Enable receiving of shadows but not casting them.
	 */
	Receive;

	/**
	 * Enable both receiving and casting of shadows.
	 */
	CastAndReceive;

	/**
	 * Inherit the <code>ShadowMode</code> from the parent node.
	 */
	Inherit;
}

