package org.angle3d.renderer.queue;

/**
 * The render queue `Bucket` specifies the bucket
 * to which the spatial will be placed when rendered.
 * <p>
 * The behavior of the rendering will differ depending on which
 * bucket the spatial is placed. A spatial's queue bucket can be set
 * via {Spatial#setQueueBucket(org.angle3d.renderer.queue.RenderQueue.Bucket) }.
 */
@:enum abstract QueueBucket(Int) {
	/**
	 * The renderer will try to find the optimal order for rendering all
	 * objects using this mode.
	 * You should use this mode for most normal objects, except transparent
	 * ones, as it could give a nice performance boost to your application.
	 */
	var Opaque = 0;

	/**
	 * This is the mode you should use for object with
	 * transparency in them. It will ensure the objects furthest away are
	 * rendered first. That ensures when another transparent object is drawn on
	 * top of previously drawn objects, you can see those (and the object drawn
	 * using Opaque) through the transparent parts of the newly drawn
	 * object.
	 */
	var Transparent = 1;

	/**
	 * A special mode used for rendering really far away, flat objects -
	 * e.g. skies. In this mode, the depth is set_to infinity so
	 * spatials in this bucket will appear behind everything, the downside
	 * to this bucket is that 3D objects will not be rendered correctly
	 * due to lack of depth testing.
	 */
	var Sky = 2;

	/**
	 * A special mode used for rendering transparent objects that
	 * should not be effected by SceneProcessor.
	 * Generally this would contain translucent objects, and
	 * also objects that do not write to the depth buffer such as
	 * particle emitters.
	 */
	var Translucent = 3;

	/**
	 * This is a special mode, for drawing 2D object
	 * without perspective (such as GUI or HUD parts).
	 * The spatial's world coordinate system has the range
	 * of [0, 0, -1] to [Width, Height, 1] where Width/Height is
	 * the resolution of the screen rendered to. Any spatials
	 * outside of that range are culled.
	 */
	var Gui = 4;

	/**
	 * A special mode, that will ensure that this spatial uses the same
	 * mode as the parent Node does.
	 */
	var Inherit = 5;
}

