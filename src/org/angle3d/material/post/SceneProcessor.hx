package org.angle3d.material.post;

import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.queue.RenderQueue;
import org.angle3d.renderer.ViewPort;
import org.angle3d.texture.FrameBuffer;

/**
 * Scene processors are used to compute/render things before and after the classic render of the scene.
 * They have to be added to a viewport and are rendered in the order they've been added
 *
 * @author Kirill Vainer
 */
interface SceneProcessor
{

	/**
	 * Called in the render thread to initialize the scene processor.
	 *
	 * @param rm The render manager to which the SP was added to
	 * @param vp The viewport to which the SP is assigned
	 */
	function initialize(rm:RenderManager, vp:ViewPort):Void;

	/**
	 * @return True if initialize() has been called on this SceneProcessor,
	 * false if otherwise.
	 */
	function isInitialized():Bool;

	/**
	 * Called when the resolution of the viewport has been changed.
	 * @param vp
	 */
	function reshape(vp:ViewPort, w:Int, h:Int):Void;


	/**
	 * Called before a frame
	 *
	 * @param tpf Time per frame
	 */
	function preFrame(tpf:Float):Void;

	/**
	 * Called after the scene graph has been queued, but before it is flushed.
	 *
	 * @param rq The render queue
	 */
	function postQueue(rq:RenderQueue):Void;

	/**
	 * Called after a frame has been rendered and the queue flushed.
	 *
	 * @param out The FB to which the scene was rendered.
	 */
	function postFrame(out:FrameBuffer):Void;

	/**
	 * Called when the SP is removed from the RM.
	 */
	function cleanup():Void;
}

