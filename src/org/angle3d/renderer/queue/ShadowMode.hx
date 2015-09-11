package org.angle3d.renderer.queue;

/**
 * <code>ShadowMode</code> is a marker used to specify how shadow
 * effects should treat the spatial.
 */
@:final class ShadowMode
{
	/**
	 * Disable both shadow casting and shadow receiving for this spatial.
	 * Generally used for special effects like particle emitters.
	 */
	public static inline var Off:Int = 0;

	/**
	 * Enable casting of shadows but not receiving them.
	 */
	public static inline var Cast:Int = 1;

	/**
	 * Enable receiving of shadows but not casting them.
	 */
	public static inline var Receive:Int = 2;

	/**
	 * Enable both receiving and casting of shadows.
	 */
	public static inline var CastAndReceive:Int = 3;

	/**
	 * Inherit the <code>ShadowMode</code> from the parent node.
	 */
	public static inline var Inherit:Int = 4;
}

