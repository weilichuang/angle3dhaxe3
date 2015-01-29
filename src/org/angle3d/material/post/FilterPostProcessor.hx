package org.angle3d.material.post;

import flash.display3D.textures.Texture;
import flash.errors.Error;
import flash.Vector;
import org.angle3d.scene.ui.Picture;

import org.angle3d.material.Material;
import org.angle3d.renderer.Camera;
import org.angle3d.renderer.IRenderer;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.renderer.queue.RenderQueue;
import org.angle3d.texture.FrameBuffer;
import org.angle3d.texture.Texture2D;

/**
 * A FilterPostProcessor is a processor that can apply several {@link Filter}s to a rendered scene<br>
 * It manages a list of filters that will be applied in the order in which they've been added to the list
 */
class FilterPostProcessor implements SceneProcessor
{
	private var renderManager:RenderManager;
	private var renderer:IRenderer;
	private var viewPort:ViewPort;
	private var renderFrameBufferMS:FrameBuffer;
	
	private var numSamples:Int = 1;
	private var renderFrameBuffer:FrameBuffer;

	private var filterTexture:Texture2D;
	private var depthTexture:Texture2D;
	
	private var filters:Vector<Filter>;
	
	private var fsQuad:Picture;
	private var computeDepth:Bool = false;
	private var outputBuffer:FrameBuffer;
	
	private var width:Int;
    private var height:Int;
    private var bottom:Float;
    private var left:Float;
    private var right:Float;
    private var top:Float;
    private var originalWidth:Int;
    private var originalHeight:Int;
    private var lastFilterIndex:Int = -1;
    private var cameraInit:Bool = false;
    private var multiView:Bool = false;

	public function new()
	{
		filters = new Vector<Filter>();
	}

	/**
	 * Adds a filter to the filters list<br>
	 * @param filter the filter to add
	 */
	public function addFilter(filter:Filter):Void
	{
		if (filter == null)
		{
			return;
		}

		filters.push(filter);

		if (isInitialized())
		{
			initFilter(filter, viewPort);
		}

		setFilterState(filter, filter.isEnabled());
	}

	/**
	 * removes this filters from the filters list
	 * @param filter
	 */
	public function removeFilter(filter:Filter):Void
	{
		if (filter == null)
		{
			return;
		}
		var index:Int = filters.indexOf(filter);
		if (index != -1)
		{
			filters.splice(index, 1);
			filter.cleanup(renderer);
			updateLastFilterIndex();
		}
	}

	/**
	 * init the given filter
	 * @param filter
	 * @param vp
	 */
	private function initFilter(filter:Filter, vp:ViewPort):Void
	{
		filter.setProcessor(this);
		if (filter.isRequiresDepthTexture())
		{
			if (!computeDepth && renderFrameBuffer != null)
			{
				depthTexture = new Texture2D(width, height, Format.Depth24);
				renderFrameBuffer.setDepthTexture(depthTexture);
			}
			computeDepth = true;
			filter.init(assetManager, renderManager, vp, width, height);
			filter.setDepthTexture(depthTexture);
		}
		else
		{
			filter.init(assetManager, renderManager, vp, width, height);
		}
	}


	/**
	 * renders a filter on a fullscreen quad
	 * @param r
	 * @param buff
	 * @param mat
	 */
	private function renderProcessing(r:IRenderer, buff:FrameBuffer, mat:Material):Void
	{
		//if (buff == outputBuffer)
		//{
			//fsQuad.setWidth(width);
			//fsQuad.setHeight(height);
			//filterCam.resize(originalWidth, originalHeight, true);
			//fsQuad.setPosition(left * originalWidth, bottom * originalHeight);
		//}
		//else
		//{
			//fsQuad.setWidth(buff.getWidth());
			//fsQuad.setHeight(buff.getHeight());
			//filterCam.resize(buff.getWidth(), buff.getHeight(), true);
			//fsQuad.setPosition(0, 0);
		//}
//
		//if (mat.getAdditionalRenderState().isDepthWrite())
		//{
			//mat.getAdditionalRenderState().setDepthTest(false);
			//mat.getAdditionalRenderState().setDepthWrite(false);
		//}
//
		//fsQuad.setMaterial(mat);
		//fsQuad.updateGeometricState();
//
		//renderManager.setCamera(filterCam, true);
		//r.setFrameBuffer(buff);
		//r.clearBuffers(clearColor, true, true);
		//renderManager.renderGeometry(fsQuad);

	}

	/**
	 * Called in the render thread to initialize the scene processor.
	 *
	 * @param rm The render manager to which the SP was added to
	 * @param vp The viewport to which the SP is assigned
	 */
	public function initialize(rm:RenderManager, vp:ViewPort):Void
	{
		renderManager = rm;
        renderer = rm.getRenderer();
        viewPort = vp;
        fsQuad = new Picture("filter full screen quad");
        fsQuad.setWidth(1);
        fsQuad.setHeight(1);
        
        //if (!renderer.getCaps().contains(Caps.PackedFloatTexture)) {
            //fbFormat = Format.RGB8;
        //}
        
        var cam:Camera = vp.getCamera();

        //save view port diensions
        left = cam.viewPortRect.left;
        right = cam.viewPortRect.right;
        top = cam.viewPortRect.top;
        bottom = cam.viewPortRect.bottom;
        originalWidth = cam.width;
        originalHeight = cam.height;
        //first call to reshape
        reshape(vp, cam.width, cam.height);
	}

	/**
	 * Called when the resolution of the viewport has been changed.
	 * @param vp
	 */
	public function reshape(vp:ViewPort, w:Int, h:Int):Void
	{
		//this has no effect at first init but is useful when resizing the canvas with multi views
		//var cam:Camera = vp.camera;
		//cam.setViewPort(left, right, bottom, top);
		//resizing the camera to fit the new viewport and saving original dimensions
		//cam.resize(w, h, false);
		//left = cam.getViewPortLeft();
		//right = cam.getViewPortRight();
		//top = cam.getViewPortTop();
		//bottom = cam.getViewPortBottom();
		//originalWidth = w;
		//originalHeight = h;
		//cam.setViewPort(0, 1, 0, 1);
//
		//computing real dimension of the viewport and resizing he camera 
		//width = (w * (Math.abs(right - left)));
		//height = (h * (Math.abs(bottom - top)));
		//width = Math.max(1, width);
		//height = Math.max(1, height);
//
		//Testing original versus actual viewport dimension.
		//If they are different we are in a multiview situation and color from other view port must not be cleared.
		//However, not clearing the color can cause issues when AlphaToCoverage is active on the renderer.        
		//if (originalWidth != width || originalHeight != height)
		//{
			//clearColor = false;
		//}
		//else
		//{
			//clearColor = true;
		//}
//
		//cam.resize(width, height, false);
		//cameraInit = true;
		//computeDepth = false;
//
		//if (renderFrameBuffer == null)
		//{
			//outputBuffer = viewPort.getOutputFrameBuffer();
		//}
//
//
		//if (numSamples <= 1 || !caps.contains(Caps.OpenGL31))
		//{
			//renderFrameBuffer = new FrameBuffer(width, height, 1);
			//renderFrameBuffer.setDepthBuffer(Format.Depth);
			//filterTexture = new Texture2D(width, height, Format.RGBA8);
			//renderFrameBuffer.setColorTexture(filterTexture);
		//}
//
		//for (i in 0...filters.length)
		//{
			//var filter:Filter = filters[i];
			//initFilter(filter, vp);
		//}
//
		//if (renderFrameBufferMS != null)
		//{
			//viewPort.setOutputFrameBuffer(renderFrameBufferMS);
		//}
		//else
		//{
			//viewPort.setOutputFrameBuffer(renderFrameBuffer);
		//}
	}

	/**
	 * @return True if initialize() has been called on this SceneProcessor,
	 * false if otherwise.
	 */
	public function isInitialized():Bool
	{
		return viewPort != null;
	}

	/**
	 * Called before a frame
	 *
	 * @param tpf Time per frame
	 */
	public function preFrame(tpf:Float):Void
	{
		//if (filters.length == 0 || lastFilterIndex == -1)
		//{
			//If the camera is initialized and there are no filter to render, the camera viewport is restored as it was
			//if (cameraInit)
			//{
				//viewPort.getCamera().resize(originalWidth, originalHeight, true);
				//viewPort.getCamera().setViewPort(left, right, bottom, top);
				//viewPort.setOutputFrameBuffer(outputBuffer);
				//cameraInit = false;
			//}
//
		//}
		//else
		//{
			//if (renderFrameBufferMS != null)
			//{
				//viewPort.setOutputFrameBuffer(renderFrameBufferMS);
			//}
			//else
			//{
				//viewPort.setOutputFrameBuffer(renderFrameBuffer);
			//}
			//init of the camera if it wasn't already
			//if (!cameraInit)
			//{
				//viewPort.getCamera().resize(width, height, true);
				//viewPort.getCamera().setViewPort(0, 1, 0, 1);
			//}
		//}
//
		//for (i in 0...filters.length)
		//{
			//var filter:Filter = filters[i];
			//if (filter.isEnabled())
			//{
				//filter.preFrame(tpf);
			//}
		//}
	}

	/**
	 * Called after the scene graph has been queued, but before it is flushed.
	 *
	 * @param rq The render queue
	 */
	public function postQueue(rq:RenderQueue):Void
	{
		for (i in 0...filters.length)
		{
			var filter:Filter = filters[i];
			if (filter.enabled)
			{
				filter.postQueue(rq);
			}
		}
	}

	/**
	 * Called after a frame has been rendered and the queue flushed.
	 *
	 * @param out The FB to which the scene was rendered.
	 */
	public function postFrame(out:FrameBuffer):Void
	{
		//var sceneBuffer:FrameBuffer = renderFrameBuffer;
		//if (renderFrameBufferMS != null && !renderer.getCaps().contains(Caps.OpenGL31))
		//{
			//renderer.copyFrameBuffer(renderFrameBufferMS, renderFrameBuffer);
		//}
		//else if (renderFrameBufferMS != null)
		//{
			//sceneBuffer = renderFrameBufferMS;
		//}
		//renderFilterChain(renderer, sceneBuffer);
		//renderer.setFrameBuffer(outputBuffer);
//
		//viewport can be null if no filters are enabled
		//if (viewPort != null)
		//{
			//renderManager.setCamera(viewPort.camera, false);
		//}
	}

	/**
	 * Called when the SP is removed from the RM.
	 */
	public function cleanup():Void
	{
		//if (viewPort != null)
		//{
			//reseting the viewport camera viewport to its initial value
			//viewPort.camera.resize(originalWidth, originalHeight, true);
			//viewPort.camera.setViewPort(left, right, bottom, top);
			//viewPort.setOutputFrameBuffer(outputBuffer);
			//viewPort = null;
//
			//for (i in 0...filters.length)
			//{
				//var filter:Filter = filters[i];
				//filter.cleanup(renderer);
			//}
		//}
	}

	/**
	 *
	 * Removes all the filters from this processor
	 */
	public function removeAllFilters():Void
	{
		filters.length = 0;
		updateLastFilterIndex();
	}

	/**
	 * sets the filter to enabled or disabled
	 * @param filter
	 * @param enabled
	 */
	public function setFilterState(filter:Filter, enabled:Bool):Void
	{
		if (filters.indexOf(filter) != -1)
		{
			filter.enabled = enabled;
			updateLastFilterIndex();
		}
	}

	/**
	 * compute the index of the last filter to render
	 */
	private var lastFilterIndex:Int;
	private function updateLastFilterIndex():Void
	{
		lastFilterIndex = -1;
		var i:Int = filters.length - 1;
		while(i >= 0 && lastFilterIndex == -1)
		{
			if (filters[i].enabled)
			{
				lastFilterIndex = i;
				return;
			}
			i--;
		}
		if (lastFilterIndex == -1)
		{
			cleanup();
		}
	}

	/**
	 * For internal use only<br>
	 * returns the depth texture of the scene
	 * @return the depth texture
	 */
	public function getDepthTexture():Texture2D
	{
		return depthTexture;
	}

	/**
	 * For internal use only<br>
	 * returns the rendered texture of the scene
	 * @return the filter texture
	 */
	public function getFilterTexture():Texture2D
	{
		return filterTexture;
	}
}

