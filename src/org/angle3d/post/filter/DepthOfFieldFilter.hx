package org.angle3d.post.filter;

import org.angle3d.math.Vector4f;
import org.angle3d.material.Material;
import org.angle3d.post.Filter;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;

/**
 * A post-processing filter that performs a depth range
 *  blur using a scaled convolution filter.
 * @author 
 */
class DepthOfFieldFilter extends Filter
{
	private var focusDistance:Float = 50;
    private var focusRange:Float = 10;
    private var blurScale:Float = 1;
    // These values are set internally based on the viewport size.
    private var xScale:Float;
    private var yScale:Float;

	private var u_DofInfo:Vector4f;
	private var u_NearFar:Vector4f;
	public function new(focusDistance:Float = 50, focusRange:Float = 10, bulrScale:Float = 1, near:Float = 0.1, far:Float = 1000) 
	{
		super("Depth Of Field");
		
		u_DofInfo = new Vector4f();
		u_DofInfo.x = focusDistance;
		u_DofInfo.y = focusRange;
		
		u_NearFar = new Vector4f();
		u_NearFar.x = far / (far - near);
		u_NearFar.y = far * near / (near - far);
		u_NearFar.z = 2.0;
		u_NearFar.w = 1/12.0;
	}
	
	override public function isRequiresDepthTexture():Bool
	{
		return true;
	}
	
	override private function initFilter(renderManager:RenderManager, vp:ViewPort, w:Int, h:Int):Void
	{
		material = new Material();
		material.load(Angle3D.materialFolder + "material/depthoffield.mat");

        xScale = 1.0 / w;
        yScale = 1.0 / h;
		
		u_DofInfo.z = blurScale * xScale;
		u_DofInfo.w = blurScale * yScale;
		
		material.setVector4("u_DofInfo", this.u_DofInfo);
		material.setVector4("u_NearFar", this.u_NearFar);
	}

	override public function getMaterial():Material
	{
		return material;
	}
	
	/**
     *  Sets the distance at which objects are purely in focus.
     */
    public function setFocusDistance(f:Float):Void
	{
        this.focusDistance = f;
		u_DofInfo.x = f;
        if (material != null)
		{
            material.setVector4("u_DofInfo", this.u_DofInfo);
        }

    }

    /**
     * returns the focus distance
     * @return 
     */
    public function getFocusDistance():Float
	{
        return focusDistance;
    }

    /**
     *  Sets the range to either side of focusDistance where the
     *  objects go gradually out of focus.  Less than focusDistance - focusRange
     *  and greater than focusDistance + focusRange, objects are maximally "blurred".
     */
    public function setFocusRange(f:Float):Void
	{
        this.focusRange = f;
		u_DofInfo.y = f;
        if (material != null)
		{
            material.setVector4("u_DofInfo", this.u_DofInfo);
        }

    }

    /**
     * returns the focus range
     * @return 
     */
    public function getFocusRange():Float
	{
        return focusRange;
    }

    /**
     *  Sets the blur amount by scaling the convolution filter up or
     *  down.  A value of 1 (the default) performs a sparse 5x5 evenly
     *  distribubted convolution at pixel level accuracy.  Higher values skip
     *  more pixels, and so on until you are no longer blurring the image
     *  but simply hashing it.
     *
     *  The sparse convolution is as follows:
     *%MINIFYHTMLc3d0cd9fab65de6875a381fd3f83e1b338%*
     *  Where 'x' is the texel being modified.  Setting blur scale higher
     *  than 1 spaces the samples out.
     */
    public function setBlurScale(f:Float):Void
	{
        this.blurScale = f;
		u_DofInfo.z = blurScale * xScale;
		u_DofInfo.w = blurScale * yScale;
        if (material != null) 
		{
			material.setVector4("u_DofInfo", this.u_DofInfo);
        }
    }

    /**
     * returns the blur scale
     * @return 
     */
    public function getBlurScale():Float
	{
        return blurScale;
    }
}