package org.angle3d.renderer;

import org.angle3d.material.BlendMode;
import org.angle3d.material.CullMode;
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
	public var depthTest:Bool;

	public var compareMode:TestFunction;

	public var colorWrite:Bool;

	public var clipRectEnabled:Bool;

	public var blendMode:BlendMode;

	public function new()
	{
		reset();
	}

	public function reset():Void
	{
		cullMode = CullMode.FRONT;
		depthTest = true;
		compareMode = TestFunction.LESS;
		colorWrite = true;
		clipRectEnabled = false;
		blendMode = BlendMode.Off;
	}
}

