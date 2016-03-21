package org.angle3d.shadow;

import org.angle3d.material.Material;
import org.angle3d.post.Filter;
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
 * add to a viewport's filter post-processor.
 */
class AbstractShadowFilter extends Filter
{
	private var shadowRenderer:AbstractShadowRenderer;
	private var viewPort:ViewPort;
	
	private var tmpv:Vector4f;
	
	private var invertVPM:Matrix4f;

	/**
     * Abstract class constructor
     *
     * @param shadowMapSize the size of the rendered shadowmaps (512,1024,2048,etc...)
     * @param nbShadowMaps the number of shadow maps rendered (the more shadow
     * maps the more quality, the less fps).
     * @param shadowRenderer the shadowRenderer to use for this Filter
     */
	public function new(shadowMapSize:Int,shadowRenderer:AbstractShadowRenderer) 
	{
		super("Post Shadow Filter");
		
		tmpv = new Vector4f();
		invertVPM = new Matrix4f();
		
		material = new Material(Angle3D.materialFolder + "material/postShadowFilter.mat");
		
		this.shadowRenderer = shadowRenderer;
        this.shadowRenderer.setPostShadowMaterial(material);
	}
	
	override public function getMaterial():Material 
	{
		return material;
	}
	
	override public function isRequiresDepthTexture():Bool 
	{
		return true;
	}
	
	public function getShadowMaterial():Material
	{
		return material;
	}
	
	override public function preFrame(tpf:Float):Void
	{
		shadowRenderer.preFrame(tpf);
		
		viewPort.camera.getViewProjectionMatrix().invert(invertVPM);
		
        material.setMatrix4("u_ViewProjectionMatrixInverse", invertVPM);
		
        var m:Matrix4f = viewPort.camera.getViewProjectionMatrix();
		tmpv.setTo(m.m20, m.m21, m.m22, m.m23);
        material.setVector4("u_ViewProjectionMatrixRow2", tmpv);
	}
	
	override public function postQueue(queue:RenderQueue):Void
	{
		shadowRenderer.postQueue(queue);
		if (shadowRenderer.skipPostPass)
		{
            //removing the shadow map so that the post pass is skipped
            material.setTexture("u_ShadowMap0", null);
        }
	}
	
	override public function postFrame(renderManager:RenderManager, viewPort:ViewPort,
										prevFilterBuffer:FrameBuffer, sceneBuffer:FrameBuffer):Void
	{
		if (!shadowRenderer.skipPostPass)
		{
            shadowRenderer.setPostShadowParams();
        }
	}
	
	override private function initFilter(renderManager:RenderManager, vp:ViewPort, w:Int, h:Int):Void
	{
		shadowRenderer.needsfallBackMaterial = true;
        shadowRenderer.initialize(renderManager, vp);
        this.viewPort = vp;
	}
	
	/**
     * How far the shadows are rendered in the view
     *
     * @see setShadowZExtend(float zFar)
     * @return shadowZExtend
     */
    public function getShadowZExtend():Float
	{
        return shadowRenderer.getShadowZExtend();
    }

    /**
     * Set the distance from the eye where the shadows will be rendered default
     * value is dynamicaly computed to the shadow casters/receivers union bound
     * zFar, capped to view frustum far value.
     *
     * @param zFar the zFar values that override the computed one
     */
    public function setShadowZExtend(zFar:Float):Void
	{
		shadowRenderer.setShadowZExtend(zFar);
    }
	
	/**
     * How far the shadows are rendered in the view
     *
     * @see setShadowZExtend(float zFar)
     * @return shadowZExtend
     */
    public function getShadowZFadeLength():Float
	{
        return shadowRenderer.getShadowZFadeLength();
    }

    /**
     * Set the distance from the eye where the shadows will be rendered default
     * value is dynamicaly computed to the shadow casters/receivers union bound
     * zFar, capped to view frustum far value.
     *
     * @param zFar the zFar values that override the computed one
     */
    public function setShadowZFadeLength(value:Float):Void
	{
		shadowRenderer.setShadowZFadeLength(value);
    }
	
    /**
     * Set the shadowIntensity, the value should be between 0 and 1, a 0 value
     * gives a bright and invisilble shadow, a 1 value gives a pitch black
     * shadow, default is 0.7
     *
     * @param shadowIntensity the darkness of the shadow
     */
    public function setShadowInfo(bias:Float,shadowIntensity:Float):Void
	{
		shadowRenderer.setShadowInfo(bias, shadowIntensity);
    }

    /**
     * returns the edges thickness <br>
     *
     * @see #setEdgesThickness(int edgesThickness)
     * @return edgesThickness
     */
    public function getEdgesThickness():Float
	{
        return shadowRenderer.getEdgesThickness();
    }

    /**
     * Sets the shadow edges thickness. default is 1, setting it to lower values
     * can help to reduce the jagged effect of the shadow edges
     *
     * @param edgesThickness
     */
    public function setEdgesThickness(edgesThickness:Float):Void
	{
       shadowRenderer.setEdgesThickness(edgesThickness);
    }

    /**
     * Sets the filtering mode for shadow edges see {EdgeFilteringMode}
     * for more info
     *
     * @param filterMode
     */
    public function setEdgeFilteringMode(filterMode:EdgeFilteringMode):Void
	{
        return shadowRenderer.setEdgeFilteringMode(filterMode);
    }

    /**
     * returns the the edge filtering mode
     *
     * @see EdgeFilteringMode
     * @return
     */
    public function getEdgeFilteringMode():EdgeFilteringMode 
	{
        return shadowRenderer.getEdgeFilteringMode();
    }
}