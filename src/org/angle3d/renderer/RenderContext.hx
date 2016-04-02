package org.angle3d.renderer;

import flash.Vector;
import org.angle3d.material.BlendMode;
import org.angle3d.material.FaceCullMode;
import org.angle3d.material.StencilOperation;
import org.angle3d.material.TestFunction;
import org.angle3d.texture.Texture;


/**
 * Represents the current state of the graphics library. This class is used
 * internally to reduce state changes.
 */
class RenderContext
{
	/**
	 * If back-face culling is enabled.
	 */
	public var cullMode:FaceCullMode;

	/**
	 * If Depth testing is enabled.
	 */
	public var depthTestEnabled:Bool;
	
	public var depthWriteEnabled:Bool;

	public var depthFunc:TestFunction;

	public var colorWriteEnabled:Bool;

	public var clipRectEnabled:Bool;

	public var blendMode:BlendMode;
	
	/**
     * Stencil Buffer state
     */
	public var stencilTest:Bool;
	public var frontStencilStencilFailOperation:StencilOperation;
    public var frontStencilDepthFailOperation:StencilOperation;
    public var frontStencilDepthPassOperation:StencilOperation;
    public var backStencilStencilFailOperation:StencilOperation;
    public var backStencilDepthFailOperation:StencilOperation;
    public var backStencilDepthPassOperation:StencilOperation;
    public var frontStencilFunction:TestFunction;
    public var backStencilFunction:TestFunction;
	
	
	/**
     * Current bound texture IDs for each texture unit.
     * 
     * @see Renderer#setTexture(int, com.jme3.texture.Texture) 
     */
    public var boundTextures:Vector<Texture>;

	public function new()
	{
		reset();
	}

	public function reset():Void
	{
		cullMode = FaceCullMode.NONE;
		depthTestEnabled = true;
		depthWriteEnabled = true;
		depthFunc = TestFunction.LESS_EQUAL;
		colorWriteEnabled = false;
		clipRectEnabled = false;
		blendMode = BlendMode.Off;
		
		stencilTest = false;
        frontStencilStencilFailOperation = StencilOperation.KEEP;
        frontStencilDepthFailOperation = StencilOperation.KEEP;
        frontStencilDepthPassOperation = StencilOperation.KEEP;
        backStencilStencilFailOperation = StencilOperation.KEEP;
        backStencilDepthFailOperation = StencilOperation.KEEP;
        backStencilDepthPassOperation = StencilOperation.KEEP;
        frontStencilFunction = TestFunction.ALWAYS;
        backStencilFunction = TestFunction.ALWAYS;
	}
}

