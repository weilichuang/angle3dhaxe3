package org.angle3d.post;

import flash.display3D.Context3DMipFilter;
import flash.display3D.Context3DTextureFilter;
import flash.display3D.Context3DWrapMode;
import flash.Vector;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.renderer.Camera;
import org.angle3d.renderer.IRenderer;
import org.angle3d.renderer.queue.QueueBucket;
import org.angle3d.renderer.queue.RenderQueue;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.scene.ui.Picture;
import org.angle3d.texture.FrameBuffer;
import org.angle3d.texture.Texture2D;


/**
 * A FilterPostProcessor is a processor that can apply several Filters to a rendered scene<br>
 * It manages a list of filters that will be applied in the order in which they've been added to the list
 */
@:access(org.angle3d.material.RenderState)
class FilterPostProcessor implements SceneProcessor
{
	private var renderManager:RenderManager;
	private var renderer:IRenderer;
	private var viewPort:ViewPort;

	private var renderFrameBuffer:FrameBuffer;

	private var filterTexture:Texture2D;
	private var depthTexture:Texture2D;
	
	private var depthFB:FrameBuffer;
	
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
	
	private var depthMat:Material;
	
	public function new()
	{
		filters = new Vector<Filter>();
		
		depthMat = new Material();
		depthMat.load(Angle3D.materialFolder + "material/preshadow.mat");
	}

	/**
	 * Adds a filter to the filters list<br>
	 * @param filter the filter to add
	 */
	public function addFilter(filter:Filter):Void
	{
		if (filter == null)
		{
			throw "Filter cannot be null.";
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
			throw "Filter cannot be null.";
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
        
        var cam:Camera = vp.camera;

        //save view port diensions
        left = cam.viewPortLeft;
        right = cam.viewPortRight;
        top = cam.viewPortTop;
        bottom = cam.viewPortBottom;
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
		var cam:Camera = vp.camera;
		//this has no effect at first init but is useful when resizing the canvas with multi views
		cam.setViewPortRect(left, right, bottom, top);
		//resizing the camera to fit the new viewport and saving original dimensions
		cam.resize(w, h, false);
		left = cam.viewPortLeft;
		right = cam.viewPortRight;
		top = cam.viewPortTop;
		bottom = cam.viewPortBottom;
		originalWidth = w;
		originalHeight = h;

		//computing real dimension of the viewport and resizing he camera 
		width = Std.int(w * (Math.abs(right - left)));
		height = Std.int(h * (Math.abs(bottom - top)));
		width = FastMath.maxInt(1, width);
		height = FastMath.maxInt(1, height);

		//Testing original versus actual viewport dimension.
        //If they are different we are in a multiview situation and 
        //camera must be handled differently
        if (originalWidth != width || originalHeight != height)
		{
            multiView = true;
        }

		cameraInit = true;
		computeDepth = false;

		if (renderFrameBuffer == null)
		{
			outputBuffer = viewPort.getOutputFrameBuffer();
		}

		if (renderFrameBuffer != null)
		{
			renderFrameBuffer.dispose();
		}
		renderFrameBuffer = new FrameBuffer(width, height);
		renderFrameBuffer.setDepthBuffer();
		
		if (filterTexture != null)
		{
			filterTexture.dispose();
		}
		filterTexture = new Texture2D(width, height);
		renderFrameBuffer.setColorTexture(filterTexture);

		for (i in 0...filters.length)
		{
			initFilter(filters[i], vp);
		}
		setupViewPortFrameBuffer();
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
		if (filters.length == 0 || lastFilterIndex == -1)
		{
			//If the camera is initialized and there are no filter to render, the camera viewport is restored as it was
			if (cameraInit)
			{
				viewPort.getCamera().resize(originalWidth, originalHeight, true);
				viewPort.getCamera().setViewPortRect(left, right, bottom, top);
				viewPort.setOutputFrameBuffer(outputBuffer);
				cameraInit = false;
			}

		}
		else
		{
			setupViewPortFrameBuffer();
            //if we are ina multiview situation we need to resize the camera 
            //to the viewportsize so that the backbuffer is rendered correctly
            if (multiView)
		    {
                viewPort.getCamera().resize(width, height, false);
                viewPort.getCamera().setViewPortRect(0, 1, 0, 1);
                viewPort.getCamera().update();
                renderManager.setCamera(viewPort.getCamera(), false);
            }
		}

		for (i in 0...filters.length)
		{
			var filter:Filter = filters[i];
			if (filter.isEnabled())
			{
				filter.preFrame(tpf);
			}
		}
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
			if (filter.isEnabled())
			{
				filter.postQueue(rq);
			}
		}
		
		renderDepth(rq);
	}

	/**
	 * Called after a frame has been rendered and the queue flushed.
	 *
	 * @param out The FB to which the scene was rendered.
	 */
	public function postFrame(out:FrameBuffer):Void
	{
		var sceneBuffer:FrameBuffer = renderFrameBuffer;
		renderFilterChain(renderer, sceneBuffer);
		renderer.setFrameBuffer(outputBuffer);

		//viewport can be null if no filters are enabled
		if (viewPort != null)
		{
			renderManager.setCamera(viewPort.camera, false);
		}
	}

	/**
	 * Called when the SP is removed from the RM.
	 */
	public function cleanup():Void
	{
		if (viewPort != null)
		{
			//reseting the viewport camera viewport to its initial value
			viewPort.camera.resize(originalWidth, originalHeight, true);
			viewPort.camera.setViewPortRect(left, right, bottom, top);
			viewPort.setOutputFrameBuffer(outputBuffer);
			viewPort = null;

			renderFrameBuffer.dispose();
            if (depthTexture != null)
			{
               depthTexture.dispose();
            }
			
            filterTexture.dispose();
			
			for (i in 0...filters.length)
			{
				var filter:Filter = filters[i];
				filter.cleanup(renderer);
			}
		}
		
		//if (depthPic != null)
		//{
			//depthPic.removeFromParent();
			//depthPic = null;
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
			filter.setEnabled(enabled);
			updateLastFilterIndex();
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
	
	/**
	 * compute the index of the last filter to render
	 */
	private function updateLastFilterIndex():Void
	{
		lastFilterIndex = -1;
		var i:Int = filters.length - 1;
		while(i >= 0 && lastFilterIndex == -1)
		{
			if (filters[i].isEnabled())
			{
				lastFilterIndex = i;
				
				//the Fpp is initialized, but the viwport framebuffer is the 
                //original out framebuffer so we must recover from a situation 
                //where no filter was enabled. So we set th correc framebuffer 
                //on the viewport
				if (isInitialized() && viewPort.getOutputFrameBuffer() == outputBuffer)
				{
                    setupViewPortFrameBuffer();
                }
				return;
			}
			i--;
		}
		
		if (isInitialized() && lastFilterIndex == -1) 
		{
            //There is no enabled filter, we restore the original framebuffer 
            //to the viewport to bypass the fpp.
            viewPort.setOutputFrameBuffer(outputBuffer);
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
				depthTexture = new Texture2D(width, height);
				depthTexture.optimizeForRenderToTexture = true;
				depthTexture.textureFilter = Context3DTextureFilter.NEAREST;
				depthTexture.mipFilter = Context3DMipFilter.MIPNONE;
				depthTexture.wrapMode = Context3DWrapMode.CLAMP;
				
				renderFrameBuffer.setDepthTexture(depthTexture);
				
				depthFB = new FrameBuffer(width, height);
				depthFB.addColorTexture(depthTexture);
			}
			computeDepth = true;
			filter.init(renderManager, vp, width, height);
			filter.setDepthTexture(depthTexture);
		}
		else
		{
			filter.init(renderManager, vp, width, height);
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
		if (buff == outputBuffer)
		{
            viewPort.getCamera().resize(originalWidth, originalHeight, false);
            viewPort.getCamera().setViewPortRect(left, right, bottom, top);
			
            // update is redundant because resize and setViewPort will both
            // run the appropriate (and same) onXXXChange methods.
            // Also, update() updates some things that don't need to be updated.
            //viewPort.getCamera().update();
			
            renderManager.setCamera( viewPort.getCamera(), false);        
            if (mat.getAdditionalRenderState().isDepthWrite()) 
			{
                mat.getAdditionalRenderState().setDepthTest(false);
                mat.getAdditionalRenderState().setDepthWrite(false);
            }
        }
		else
		{
            viewPort.getCamera().resize(buff.getWidth(), buff.getHeight(), false);
            viewPort.getCamera().setViewPortRect(0, 1, 0, 1);
			
            // update is redundant because resize and setViewPort will both
            // run the appropriate (and same) onXXXChange methods.
            // Also, update() updates some things that don't need to be updated.
            //viewPort.getCamera().update();
			
            renderManager.setCamera( viewPort.getCamera(), false);            
            mat.getAdditionalRenderState().setDepthTest(true);
            mat.getAdditionalRenderState().setDepthWrite(true);
        }

		fsQuad.setMaterial(mat);
		fsQuad.updateGeometricState();

		r.setFrameBuffer(buff);
		r.clearBuffers(true, true, true);
		renderManager.renderGeometry(fsQuad);
	}

	
	private function setupViewPortFrameBuffer():Void
	{
		viewPort.setOutputFrameBuffer(renderFrameBuffer);
	}
	
	private function renderDepth(rq:RenderQueue):Void
	{
		var r:IRenderer = renderManager.getRenderer();
        renderManager.setForcedMaterial(depthMat);
		renderManager.setForcedTechnique("preShadow");
		
		var dc:Color = r.backgroundColor;

        r.setFrameBuffer(depthFB);
		r.backgroundColor = new Color(1, 1, 1, 1);
        r.clearBuffers(true, true, true);
	
		renderManager.renderViewPortQueues(viewPort, false);
		
        r.setFrameBuffer(viewPort.getOutputFrameBuffer());
        renderManager.setForcedMaterial(null);
		renderManager.setForcedTechnique(null);
		r.backgroundColor = dc;
		//r.clearBuffers(true, true, true);
	}
	
	/**
     * iterate through the filter list and renders filters
     * @param r
     * @param sceneFb 
     */
    private function renderFilterChain(r:IRenderer, sceneFb:FrameBuffer):Void
	{
        var tex:Texture2D = filterTexture;
        var buff:FrameBuffer = sceneFb;
        var msDepth:Bool = false;// depthTexture != null && depthTexture.getImage().getMultiSamples() > 1;
        for (i in 0...filters.length) 
		{
            var filter:Filter = filters[i];
            if (filter.isEnabled()) 
			{
                if (filter.getPostRenderPasses() != null) 
				{
                    for (pass in filter.getPostRenderPasses())
					{
                        pass.beforeRender();
                        if (pass.requiresSceneAsTexture()) 
						{
                            pass.getPassMaterial().setTexture("u_Texture", tex);
                            //if (tex.getImage().getMultiSamples() > 1)
							//{
                                //pass.getPassMaterial().setInt("u_NumSamples", tex.getImage().getMultiSamples());
                            //}
							//else
							//{
                                //pass.getPassMaterial().clearParam("u_NumSamples");
                            //}
                        }
						
                        if (pass.requiresDepthAsTexture())
						{
                            pass.getPassMaterial().setTexture("u_DepthTexture", depthTexture);
                            //if (msDepth)
							//{
                                //pass.getPassMaterial().setInt("u_NumSamplesDepth", depthTexture.getImage().getMultiSamples());
                            //} 
							//else 
							//{
                                //pass.getPassMaterial().clearParam("u_NumSamplesDepth");
                            //}
                        }
                        renderProcessing(r, pass.getRenderFrameBuffer(), pass.getPassMaterial());
                    }
                }

                filter.postFrame(renderManager, viewPort, buff, sceneFb);

                var mat:Material = filter.getMaterial();
                if (msDepth && filter.isRequiresDepthTexture()) 
				{
                    //mat.setInt("u_NumSamplesDepth", depthTexture.getImage().getMultiSamples());
                }

                if (filter.isRequiresSceneTexture()) 
				{
                    mat.setTexture("u_Texture", tex);
                    //if (tex.getImage().getMultiSamples() > 1)
					//{
                        //mat.setInt("u_NumSamples", tex.getImage().getMultiSamples());
                    //}
					//else
					//{
                        //mat.clearParam("u_NumSamples");
                    //}
                }

                buff = outputBuffer;
                if (i != lastFilterIndex) 
				{
                    buff = filter.getRenderFrameBuffer();
                    tex = filter.getRenderedTexture();

                }
                renderProcessing(r, buff, mat);
                filter.postFilter(r, buff);
            }
        }
    }
}

