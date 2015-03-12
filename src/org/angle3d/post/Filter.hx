package org.angle3d.post;

import flash.Vector;
import org.angle3d.material.Material;
import org.angle3d.renderer.IRenderer;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.renderer.queue.RenderQueue;
import org.angle3d.texture.FrameBuffer;
import org.angle3d.texture.Texture2D;
import org.angle3d.texture.TextureMapBase;

/**
 * Filters are 2D effects applied to the rendered scene.<br>
 * The filter is fed with the rendered scene image rendered in an offscreen frame buffer.<br>
 * This texture is applied on a fullscreen quad, with a special material.<br>
 * This material uses a shader that aplly the desired effect to the scene texture.<br>
 * <br>
 * This class is abstract, any Filter must extend it.<br>
 * Any filter holds a frameBuffer and a texture<br>
 * The getMaterial must return a Material that use a GLSL shader immplementing the desired effect<br>
 *
 * @author Rémy Bouquet aka Nehon
 */
class Filter
{
	public var name:String;

	private var defaultPass:Pass;
	private var postRenderPasses:Vector<Pass>;
	private var material:Material;
	private var mEnabled:Bool = true;
	private var processor:FilterPostProcessor;


	public function new(name:String)
	{
		this.name = name;
	}

	/**
	 *
	 * initialize this filter
	 * use InitFilter for overriding filter initialization
	 * @param manager the assetManager
	 * @param renderManager the renderManager
	 * @param vp the viewport
	 * @param w the width
	 * @param h the height
	 */
	private function init(renderManager:RenderManager, vp:ViewPort, w:Int, h:Int):Void
	{
		defaultPass = new Pass();
		defaultPass.init(renderManager.getRenderer(), w, h, 1, true);
		initFilter(renderManager, vp, w, h);
	}

	/**
	 * Initialization of sub classes filters
	 * This method is called once when the filter is added to the FilterPostProcessor
	 * It should contain Material initializations and extra passes initialization
	 * @param manager the assetManager
	 * @param renderManager the renderManager
	 * @param vp the viewPort where this filter is rendered
	 * @param w the width of the filter
	 * @param h the height of the filter
	 */
	private function initFilter(renderManager:RenderManager, vp:ViewPort, w:Int, h:Int):Void
	{

	}


	/**
	 * cleanup this filter
	 * @param r
	 */
	public function cleanup(r:IRenderer):Void
	{
		processor = null;
		if (defaultPass != null)
		{
			defaultPass.cleanup(r);
		}
		if (postRenderPasses != null)
		{
			for (i in 0...postRenderPasses.length)
			{
				var pass:Pass = postRenderPasses[i];
				pass.cleanup(r);
			}
		}
		cleanUpFilter(r);
	}

	/**
	 * override this method if you have some cleanup to do
	 * @param r the renderer
	 */
	private function cleanUpFilter(r:IRenderer):Void
	{

	}

	/**
	 * Must return the material used for this filter.
	 * this method is called every frame.
	 *
	 * @return the material used for this filter.
	 */
	public function getMaterial():Material
	{
		return material;
	}
	
	/**
     * Override if you want to do something special with the depth texture;
     * @param depthTexture 
     */
    private function setDepthTexture(depthTexture:TextureMapBase):Void
	{
        getMaterial().setTexture("DepthTexture", depthTexture);
    }

	/**
	 * Override this method if you want to make a pre pass, before the actual rendering of the frame
	 * @param queue
	 */
	public function postQueue(queue:RenderQueue):Void
	{
	}

	/**
	 * Override this method if you want to modify parameters according to tpf before the rendering of the frame.
	 * This is usefull for animated filters
	 * Also it can be the place to render pre passes
	 * @param tpf the time used to render the previous frame
	 */
	public function preFrame(tpf:Float):Void
	{
	}

	/**
	 * Override this method if you want to make a pass just after the frame has been rendered and just before the filter rendering
	 * @param renderManager
	 * @param viewPort
	 * @param prevFilterBuffer
	 * @param sceneBuffer
	 */
	public function postFrame(renderManager:RenderManager, viewPort:ViewPort,
							prevFilterBuffer:FrameBuffer, sceneBuffer:FrameBuffer):Void
	{
		
	}

	public function setEnabled(enabled:Bool):Void
	{
		if (processor != null)
		{
			processor.setFilterState(this, enabled);
		}
		else
		{
			this.mEnabled = enabled;
		}
	}

	public function isEnabled():Bool
	{
		return this.mEnabled;
	}
	
	/**
     * returns the default pass frame buffer
     * @return
     */
    private function getRenderFrameBuffer():FrameBuffer
	{
        return defaultPass.renderFrameBuffer;
    }

    /**
     * sets the default pas frame buffer
     * @param renderFrameBuffer
     */
    private function setRenderFrameBuffer(renderFrameBuffer:FrameBuffer):Void
	{
        this.defaultPass.renderFrameBuffer = renderFrameBuffer;
    }

	private function setRenderedTexture(renderedTexture:Texture2D):Void
	{
		this.defaultPass.renderedTexture = renderedTexture;
	}

	private function getRenderedTexture():Texture2D
	{
        return defaultPass.renderedTexture;
    }

	public function setProcessor(proc:FilterPostProcessor):Void
	{
		this.processor = proc;
	}
	
	/**
	 * Override this method and return true if your Filter needs the depth texture
	 *
	 * @return true if your Filter need the depth texture
	 */
	public function requiresDepthAsTexture():Bool
	{
		return false;
	}

	/**
	 * Override this method and return false if your Filter does not need the scene texture
	 *
	 * @return false if your Filter does not need the scene texture
	 */
	public function requiresSceneAsTexture():Bool
	{
		return true;
	}
	
	public function isRequiresDepthTexture():Bool
	{
		return false;
	}

	public function isRequiresSceneTexture():Bool
	{
		return true;
	}

	/**
     * This method is called right after the filter has been rendered to the 
     * framebuffer.
     * Note that buffer will be null if the filter is the last one in the stack 
     * and has been rendered to screen
     * @param r the renderer
     * @param buffer the framebuffer on which the filter has been rendered.
     */
    private function postFilter(r:IRenderer, buffer:FrameBuffer):Void
	{        
    }
}

