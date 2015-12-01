package org.angle3d.renderer;

import org.angle3d.material.BlendMode;
import org.angle3d.material.CullMode;
import org.angle3d.material.StencilOperation;
import org.angle3d.material.TestFunction;


/**
 * Represents the current state of the graphics library. This class is used
 * internally to reduce state changes.
 */
class RenderContext
{
	/**
	 * If back-face culling is enabled.
	 */
	public var cullMode:CullMode;

	/**
	 * If Depth testing is enabled.
	 */
	public var depthTestEnabled:Bool;
	
	public var depthWriteEnabled:Bool;

	public var depthFunc:TestFunction;

	public var colorWriteEnabled:Bool;

	public var clipRectEnabled:Bool;

	public var blendMode:Int;
	
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

	public function new()
	{
		reset();
	}

	public function reset():Void
	{
		cullMode = CullMode.NONE;
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

