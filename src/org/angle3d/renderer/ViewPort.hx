package org.angle3d.renderer;

import flash.Vector;
import org.angle3d.material.post.SceneProcessor;
import org.angle3d.math.Color;
import org.angle3d.renderer.queue.RenderQueue;
import org.angle3d.scene.Spatial;
import org.angle3d.texture.FrameBuffer;
using org.angle3d.utils.VectorUtil;

/**
 * A <code>ViewPort</code> represents a view inside the display
 * window or a {@link FrameBuffer} to which scenes will be rendered.
 * <p>
 * A viewport has a {@link #ViewPort(java.lang.String, org.angle3d.renderer.Camera) camera}
 * which is used to render a set_of {@link #attachScene(org.angle3d.scene.Spatial) scenes}.
 * A view port has a location on the screen as set_by the
 * {@link Camera#setViewPort(float, float, float, float) } method.
 * By default, a view port does not clear the framebuffer, but it can be
 * set_to {@link #setClearFlags(Bool, Bool, Bool) clear the framebuffer}.
 * The background color which the color buffer is cleared to can be specified
 * via the {@link #setBackgroundColor(org.angle3d.math.ColorRGBA)} method.
 * <p>
 * A ViewPort has a list of {@link SceneProcessor}s which can
 * control how the ViewPort is rendered by the {@link RenderManager}.
 *
 * @author Kirill Vainer
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
	
	public var enabled(default, set):Bool;
	public var frameBuffer(default, set):FrameBuffer;
	public var processors(default, null):Vector<SceneProcessor>;

	private var _sceneList:Vector<Spatial>;
	
	private var _clearDepth:Bool;
	private var _clearColor:Bool;
	private var _clearStencil:Bool;

	/**
	 * Create a new viewport. User code should generally use these methods instead:<br>
	 * <ul>
	 * <li>{@link RenderManager#createPreView(java.lang.String, org.angle3d.renderer.Camera) }</li>
	 * <li>{@link RenderManager#createMainView(java.lang.String, org.angle3d.renderer.Camera)  }</li>
	 * <li>{@link RenderManager#createPostView(java.lang.String, org.angle3d.renderer.Camera)  }</li>
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
		initialize();
	}

	private function initialize():Void
	{
		renderQueue = new RenderQueue();
		enabled = true;
		backgroundColor = new Color();
		
		_sceneList = new Vector<Spatial>();
		processors = new Vector<SceneProcessor>();
		
	
		_clearDepth = false;
		_clearColor = false;
		_clearStencil = false;
		
	}

	/**
	 * Adds a {@link SceneProcessor} to this ViewPort.
	 * <p>
	 * SceneProcessors that are added to the ViewPort will be notified
	 * of events as the ViewPort is being rendered by the {@link RenderManager}.
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
	 * Removes a {@link SceneProcessor} from this ViewPort.
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
		for (processor in processors)
		{
			processor.cleanup();
		}
		processors.clear();
	}

	/**
	 * Check if depth buffer clearing is enabled.
	 *
	 * @return true if depth buffer clearing is enabled.
	 *
	 * @see #setClearDepth(Bool)
	 */
	public function isClearDepth():Bool
	{
		return _clearDepth;
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
		_clearDepth = clearDepth;
	}

	/**
	 * Check if color buffer clearing is enabled.
	 *
	 * @return true if color buffer clearing is enabled.
	 *
	 * @see #setClearColor(Bool)
	 */
	public function isClearColor():Bool
	{
		return _clearColor;
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
		_clearColor = clearColor;
	}

	/**
	 * Check if stencil buffer clearing is enabled.
	 *
	 * @return true if stencil buffer clearing is enabled.
	 *
	 * @see #setClearStencil(Bool)
	 */
	public function isClearStencil():Bool
	{
		return _clearStencil;
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
		_clearStencil = clearStencil;
	}

	/**
	 * set_the clear flags (color, depth, stencil) in one call.
	 *
	 * @param color If color buffer clearing should be enabled.
	 * @param depth If depth buffer clearing should be enabled.
	 * @param stencil If stencil buffer clearing should be enabled.
	 *
	 * @see #setClearColor(Bool)
	 * @see #setClearDepth(Bool)
	 * @see #setClearStencil(Bool)
	 */
	public function setClearFlags(color:Bool, depth:Bool, stencil:Bool):Void
	{
		_clearColor = color;
		_clearDepth = depth;
		_clearStencil = stencil;
	}

	/**
	 * set the framebuffer where this ViewPort's scenes are
	 * rendered to.
	 *
	 */
	private function set_frameBuffer(value:FrameBuffer):FrameBuffer
	{
		return frameBuffer = value;
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
	 * @see #attachScene(org.angle3d.scene.Spatial)
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
	 * @see #attachScene(org.angle3d.scene.Spatial)
	 */
	public function clearScenes():Void
	{
		_sceneList.clear();
	}

	/**
	 * Returns a list of all attached scenes.
	 *
	 * @return a list of all attached scenes.
	 *
	 * @see #attachScene(org.angle3d.scene.Spatial)
	 */
	public function getScenes():Vector<Spatial>
	{
		return _sceneList;
	}

	/**
	 * Returns true if the viewport is enabled, false otherwise.
	 * @return true if the viewport is enabled, false otherwise.
	 * @see #setEnabled(Bool)
	 */
	private inline function set_enabled(value:Bool):Bool
	{
		return this.enabled = value;
	}
}

