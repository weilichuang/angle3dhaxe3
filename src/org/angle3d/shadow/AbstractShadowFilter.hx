package org.angle3d.shadow;

import org.angle3d.material.Material;
import org.angle3d.material.post.Filter;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Vector4f;
import org.angle3d.renderer.queue.RenderQueue;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.texture.FrameBuffer;

/**
 *
 * Generic abstract filter that holds common implementations for the different
 * shadow filtesr
 *
 * @author weilichuang
 */
class AbstractShadowFilter extends Filter
{
	private var shadowRenderer:AbstractShadowRenderer;
	private var viewPort:ViewPort;

	/**
     * Abstract class constructor
     *
     * @param shadowMapSize the size of the rendered shadowmaps (512,1024,2048,
     * etc...)
     * @param nbShadowMaps the number of shadow maps rendered (the more shadow
     * maps the more quality, the less fps).
     * @param shadowRenderer the shadowRenderer to use for this Filter
     */
	public function new(shadowMapSize:Int,shadowRenderer:AbstractShadowRenderer) 
	{
		super("Post Shadow");
		
		material = new Material();
		this.shadowRenderer = shadowRenderer;
        this.shadowRenderer.setPostShadowMaterial(material);
		
		tmpv = new Vector4f();
	}
	
	private var tmpv:Vector4f;
	override public function preFrame(tpf:Float):Void
	{
		shadowRenderer.preFrame(tpf);
        material.setMatrix4("ViewProjectionMatrixInverse", viewPort.camera.getViewProjectionMatrix().invert());
        var m:Matrix4f = viewPort.camera.getViewProjectionMatrix();
		tmpv.setTo(m.m20, m.m21, m.m22, m.m23);
        material.setVector4("ViewProjectionMatrixRow2", tmpv);
	}
	
	override public function postQueue(queue:RenderQueue):Void
	{
		shadowRenderer.postQueue(queue);
	}
	
	override public function postFrame(renderManager:RenderManager, viewPort:ViewPort,
					prevFilterBuffer:FrameBuffer, sceneBuffer:FrameBuffer):Void
	{
		//shadowRenderer.setPostShadowParams();
	}
	
	override private function initFilter(renderManager:RenderManager, vp:ViewPort, w:Int, h:Int):Void
	{
		//shadowRenderer.needsfallBackMaterial = true;
        //shadowRenderer.initialize(renderManager, vp);
        this.viewPort = vp;
	}
	
	public var shadowIntensity(get, set):Float;
	/**
     * returns the shdaow intensity
     *
     * @see #setShadowIntensity(float shadowIntensity)
     * @return shadowIntensity
     */
    private function get_shadowIntensity():Float
	{
        return shadowRenderer.shadowIntensity;
    }

    /**
     * Set the shadowIntensity, the value should be between 0 and 1, a 0 value
     * gives a bright and invisilble shadow, a 1 value gives a pitch black
     * shadow, default is 0.7
     *
     * @param shadowIntensity the darkness of the shadow
     */
    private function set_shadowIntensity(shadowIntensity:Float):Float
	{
       return shadowRenderer.shadowIntensity = shadowIntensity;
    }

	public var edgesThickness(get, set):Float;
    /**
     * returns the edges thickness <br>
     *
     * @see #setEdgesThickness(int edgesThickness)
     * @return edgesThickness
     */
    private function get_edgesThickness():Float
	{
        return shadowRenderer.edgesThickness;
    }

    /**
     * Sets the shadow edges thickness. default is 1, setting it to lower values
     * can help to reduce the jagged effect of the shadow edges
     *
     * @param edgesThickness
     */
    private function set_edgesThickness(edgesThickness:Float):Float
	{
       return shadowRenderer.edgesThickness = edgesThickness;
    }

	public var flushQueues(get, set):Bool;
    /**
     * returns true if the PssmRenderer flushed the shadow queues
     *
     * @return flushQueues
     */
    private function get_flushQueues():Bool
	{
        return shadowRenderer.flushQueues;
    }

    /**
     * Set this to false if you want to use several PssmRederers to have
     * multiple shadows cast by multiple light sources. Make sure the last
     * PssmRenderer in the stack DO flush the queues, but not the others
     *
     * @param flushQueues
     */
    private function set_flushQueues(value:Bool):Bool
	{
        return shadowRenderer.flushQueues = value;
    }

	public var shadowCompareMode(get, set):CompareMode;
    /**
     * sets the shadow compare mode see {@link CompareMode} for more info
     *
     * @param compareMode
     */
    private function set_shadowCompareMode(compareMode:CompareMode):CompareMode 
	{
       return shadowRenderer.shadowCompareMode = compareMode;
    }

    /**
     * returns the shadow compare mode
     *
     * @see CompareMode
     * @return the shadowCompareMode
     */
    private function get_shadowCompareMode():CompareMode 
	{
        return shadowRenderer.shadowCompareMode;
    }

	public var edgeFilteringMode(get,set):EdgeFilteringMode;
    /**
     * Sets the filtering mode for shadow edges see {@link EdgeFilteringMode}
     * for more info
     *
     * @param filterMode
     */
    private function set_edgeFilteringMode(filterMode:EdgeFilteringMode):EdgeFilteringMode
	{
        return shadowRenderer.edgeFilteringMode = filterMode;
    }

    /**
     * returns the the edge filtering mode
     *
     * @see EdgeFilteringMode
     * @return
     */
    private function get_edgeFilteringMode():EdgeFilteringMode 
	{
        return shadowRenderer.edgeFilteringMode;
    }
}