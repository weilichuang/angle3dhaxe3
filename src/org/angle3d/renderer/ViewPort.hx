package org.angle3d.renderer;

import flash.Vector;
import org.angle3d.post.SceneProcessor;
import org.angle3d.math.Color;
import org.angle3d.renderer.queue.RenderQueue;
import org.angle3d.scene.Spatial;
import org.angle3d.texture.FrameBuffer;
using org.angle3d.utils.VectorUtil;

/**
 * A ViewPort represents a view inside the display
 * window or a FrameBuffer to which scenes will be rendered.
 * <p>
 * A viewport has a {#ViewPort(String, org.angle3d.renderer.Camera) camera}
 * which is used to render a set of {#attachScene(org.angle3d.scene.Spatial) scenes}.
 * A view port has a location on the screen as set by the
 * {Camera#setViewPort(float, float, float, float) } method.
 * By default, a view port does not clear the framebuffer, but it can be
 * set to {#setClearFlags(Bool, Bool, Bool) clear the framebuffer}.
 * The background color which the color buffer is cleared to can be specified
 * via the {#setBackgroundColor(org.angle3d.math.Color)} method.
 * <p>
 * A ViewPort has a list of SceneProcessors which can
 * control how the ViewPort is rendered by the RenderManager.
 *
 * @see RenderManager
 * @see SceneProcessor
 * @see Spatial
 * @see Camera
 */

class ViewPort
{
	public var name:String;

	public var camera:Camera;

	public var renderQueue:RenderQueue;
	
	public var backgroundColor:Color;
	
	private var enabled:Bool = true;
	private var frameBuffer:FrameBuffer;
	
	public var processors(default, null):Vector<SceneProcessor>;

	private var _sceneList:Vector<Spatial>;
	
	private var mClearDepth:Bool = false;
	private var mClearColor:Bool = false;
	private var mClearStencil:Bool = false;

	/**
	 * Create a new viewport. User code should generally use these methods instead:<br>
	 * <ul>
	 * <li>{RenderManager#createPreView(String, org.angle3d.renderer.Camera) }</li>
	 * <li>{RenderManager#createMainView(String, org.angle3d.renderer.Camera)  }</li>
	 * <li>{RenderManager#createPostView(String, org.angle3d.renderer.Camera)  }</li>
	 * </ul>
	 *
	 * @param name The name of the viewport. Used for debugging only.
	 * @param cam The camera through which the viewport is rendered. The camera
	 * cannot be swapped to a different one after creating the viewport.
	 */
	public function new(name:String, camera:Camera)
	{
		this.name = name;
		this.camera = camera;
		
		renderQueue = new RenderQueue();
		enabled = true;
		backgroundColor = new Color();
		
		_sceneList = new Vector<Spatial>();
		processors = new Vector<SceneProcessor>();
	}
	
	public inline function getQueue():RenderQueue
	{
		return renderQueue;
	}
	
	public inline function getCamera():Camera
	{
		return camera;
	}

	/**
	 * Adds a SceneProcessor to this ViewPort.
	 * <p>
	 * SceneProcessors that are added to the ViewPort will be notified
	 * of events as the ViewPort is being rendered by the RenderManager.
	 *
	 * @param processor The processor to add
	 *
	 * @see SceneProcessor
	 */
	public function addProcessor(processor:SceneProcessor):Void
	{
		processors.push(processor);
	}

	/**
	 * Removes a SceneProcessor from this ViewPort.
	 * <p>
	 * The processor will no longer receive events occurring to this ViewPort.
	 *
	 * @param processor The processor to remove
	 *
	 * @see SceneProcessor
	 */
	public function removeProcessor(processor:SceneProcessor):Void
	{
		var index:Int = processors.indexOf(processor);
		if (index != -1)
		{
			processors.splice(index, 1);
			processor.cleanup();
		}
	}
	
	public function removeAllProcessor():Void
	{
		for (i in 0...processors.length)
		{
			processors[i].cleanup();
		}
		processors.length = 0;
	}

	/**
	 * Check if depth buffer clearing is enabled.
	 *
	 * @return true if depth buffer clearing is enabled.
	 *
	 * @see setClearDepth(Bool)
	 */
	public function isClearDepth():Bool
	{
		return mClearDepth;
	}

	/**
	 * Enable or disable clearing of the depth buffer for this ViewPort.
	 * <p>
	 * By default depth clearing is disabled.
	 *
	 * @param clearDepth Enable/disable depth buffer clearing.
	 */
	public function setClearDepth(clearDepth:Bool):Void
	{
		mClearDepth = clearDepth;
	}

	/**
	 * Check if color buffer clearing is enabled.
	 *
	 * @return true if color buffer clearing is enabled.
	 *
	 * @see setClearColor(Bool)
	 */
	public function isClearColor():Bool
	{
		return mClearColor;
	}

	/**
	 * Enable or disable clearing of the color buffer for this ViewPort.
	 * <p>
	 * By default color clearing is disabled.
	 *
	 * @param clearDepth Enable/disable color buffer clearing.
	 */
	public function setClearColor(clearColor:Bool):Void
	{
		mClearColor = clearColor;
	}

	/**
	 * Check if stencil buffer clearing is enabled.
	 *
	 * @return true if stencil buffer clearing is enabled.
	 *
	 * @see setClearStencil(Bool)
	 */
	public function isClearStencil():Bool
	{
		return mClearStencil;
	}

	/**
	 * Enable or disable clearing of the stencil buffer for this ViewPort.
	 * <p>
	 * By default stencil clearing is disabled.
	 *
	 * @param clearDepth Enable/disable stencil buffer clearing.
	 */
	public function setClearStencil(clearStencil:Bool):Void
	{
		mClearStencil = clearStencil;
	}

	/**
	 * set_the clear flags (color, depth, stencil) in one call.
	 *
	 * @param color If color buffer clearing should be enabled.
	 * @param depth If depth buffer clearing should be enabled.
	 * @param stencil If stencil buffer clearing should be enabled.
	 *
	 * @see setClearColor(Bool)
	 * @see setClearDepth(Bool)
	 * @see setClearStencil(Bool)
	 */
	public function setClearFlags(color:Bool, depth:Bool, stencil:Bool):Void
	{
		mClearColor = color;
		mClearDepth = depth;
		mClearStencil = stencil;
	}

	/**
	 * set the framebuffer where this ViewPort's scenes are
	 * rendered to.
	 *
	 */
	public function setOutputFrameBuffer(value:FrameBuffer):Void
	{
		frameBuffer = value;
	}
	
	public function getOutputFrameBuffer():FrameBuffer
	{
		return frameBuffer;
	}

	/**
	 * Attaches a new scene to render in this ViewPort.
	 *
	 * @param scene The scene to attach
	 *
	 * @see Spatial
	 */
	public function attachScene(scene:Spatial):Void
	{
		_sceneList.push(scene);
	}

	/**
	 * Detaches a scene from rendering.
	 *
	 * @param scene The scene to detach
	 *
	 * @see attachScene(org.angle3d.scene.Spatial)
	 */
	public function detachScene(scene:Spatial):Void
	{
		var index:Int = _sceneList.indexOf(scene);
		if (index != -1)
		{
			_sceneList.splice(index, 1);
		}
	}

	/**
	 * Removes all attached scenes.
	 *
	 * @see attachScene(org.angle3d.scene.Spatial)
	 */
	public function clearScenes():Void
	{
		_sceneList.length = 0;
	}

	/**
	 * Returns a list of all attached scenes.
	 *
	 * @return a list of all attached scenes.
	 *
	 * @see attachScene(org.angle3d.scene.Spatial)
	 */
	public function getScenes():Vector<Spatial>
	{
		return _sceneList;
	}

	/**
	 * Returns true if the viewport is enabled, false otherwise.
	 * @return true if the viewport is enabled, false otherwise.
	 * @see setEnabled(Bool)
	 */
	public inline function setEnabled(value:Bool):Void
	{
		this.enabled = value;
	}
	
	public inline function isEnabled():Bool
	{
		return this.enabled;
	}
}
