package org.angle3d.material;

/**
 * <code>RenderState</code> specifies material rendering properties that cannot
 * be controlled by a shader on a {@link Material}. The properties
 * allow manipulation of rendering features such as depth testing, alpha blending,
 * face culling, stencil operations, and much more.
 *
 * @author Kirill Vainer
 */
class RenderState
{
	/**
	 * The <code>DEFAULT</code> render state is the one used by default
	 * on all materials unless changed otherwise by the user.
	 *
	 * <p>
	 * It has the following properties:
	 * <ul>
	 * <li>Back Face Culling</li>
	 * <li>Depth Testing Enabled</li>
	 * <li>Depth Writing Enabled</li>
	 * </ul>
	 */
	public static var DEFAULT:RenderState;

	/**
	 * The <code>NULL</code> render state is identical to the {@link RenderState#DEFAULT}
	 * render state except that depth testing and face culling are disabled.
	 */
	public static var NULL:RenderState;

	/**
	 * The <code>ADDITIONAL</code> render state is identical to the
	 * {@link RenderState#DEFAULT} render state except that all apply
	 * values are set_to false. This allows the <code>ADDITIONAL</code> render
	 * state to be combined with other state but only influencing values
	 * that were changed from the original.
	 */
	public static var ADDITIONAL:RenderState;

	public static function __init__():Void
	{
		DEFAULT = new RenderState();

		NULL = new RenderState();
		NULL.cullMode = CullMode.NONE;
		NULL.depthTest = false;

		ADDITIONAL = new RenderState();
		ADDITIONAL.applyCullMode = false;
		ADDITIONAL.applyDepthTest = false;
		ADDITIONAL.applyColorWrite = false;
		ADDITIONAL.applyBlendMode = false;
	}

	public var cullMode:CullMode;
	public var applyCullMode:Bool;

	public var depthTest:Bool;
	public var applyDepthTest:Bool;
	public var compareMode:TestFunction;

	public var colorWrite:Bool;
	public var applyColorWrite:Bool;

	public var blendMode:BlendMode;
	public var applyBlendMode:Bool;

	public function new()
	{
		cullMode = CullMode.FRONT;
		applyCullMode = true;

		compareMode = TestFunction.LESS;

		depthTest = true;
		applyDepthTest = true;

		colorWrite = true;
		applyColorWrite = true;

		blendMode = BlendMode.Off;
		applyBlendMode = false;
	}

	/**
	 * Enable writing color.
	 *
	 * <p>When color write is enabled, the result of a fragment shader, the
	 * <code>gl_FragColor</code>, will be rendered into the color buffer
	 * (including alpha).
	 *
	 * @param colorWrite set_to true to enable color writing.
	 */
	public function setColorWrite(colorWrite:Bool):Void
	{
		applyColorWrite = true;
		this.colorWrite = colorWrite;
	}

	/**
	 * set_the face culling mode.
	 *
	 * <p>See the {@link FaceCullMode} enum on what each value does.
	 * Face culling will project the triangle's points onto the screen
	 * and determine if the triangle is in counter-clockwise order or
	 * clockwise order. If a triangle is in counter-clockwise order, then
	 * it is considered a front-facing triangle, otherwise, it is considered
	 * a back-facing triangle.
	 *
	 * @param cullMode the face culling mode.
	 */
	public function setCullMode(cullMode:CullMode):Void
	{
		applyCullMode = true;
		this.cullMode = cullMode;
	}

	/**
	 * set_the blending mode.
	 *
	 * <p>When blending is enabled, (<code>blendMode</code> is not {@link BlendMode#Off})
	 * the input pixel will be blended with the pixel
	 * already in the color buffer. The blending operation is determined
	 * by the {@link BlendMode}. For example, the {@link BlendMode#Additive}
	 * will add the input pixel's color to the color already in the color buffer:
	 * <br/>
	 * <code>Result = Source Color + Destination Color</code>
	 *
	 * @param blendMode The blend mode to use. set_to {@link BlendMode#Off}
	 * to disable blending.
	 */
	public function setBlendMode(blendMode:BlendMode):Void
	{
		applyBlendMode = true;
		this.blendMode = blendMode;
	}

	/**
	 * Enable depth testing.
	 *
	 * <p>When depth testing is enabled, a pixel must pass the depth test
	 * before it is written to the color buffer.
	 * The input pixel's depth value must be less than or equal than
	 * the value already in the depth buffer to pass the depth test.
	 *
	 * @param depthTest Enable or disable depth testing.
	 */
	public function setDepthTest(depthTest:Bool):Void
	{
		applyDepthTest = true;
		this.depthTest = depthTest;
	}

	/**
	 * Merges <code>this</code> state and <code>additionalState</code> into
	 * the parameter <code>state</code> based on a specific criteria.
	 *
	 * <p>The criteria for this merge is the following:<br/>
	 * For every given property, such as alpha test or depth write, check
	 * if it was modified from the original in the <code>additionalState</code>
	 * if it was modified, then copy the property from the <code>additionalState</code>
	 * into the parameter <code>state</code>, otherwise, copy the property from <code>this</code>
	 * into the parameter <code>state</code>. If <code>additionalState</code>
	 * is <code>null</code>, then no modifications are made and <code>this</code> is returned,
	 * otherwise, the parameter <code>state</code> is returned with the result
	 * of the merge.
	 *
	 * @param additionalState The <code>additionalState</code>, from which data is taken only
	 * if it was modified by the user.
	 * @param state Contains output of the method if <code>additionalState</code>
	 * is not null.
	 * @return <code>state</code> if <code>additionalState</code> is non-null,
	 * otherwise returns <code>this</code>
	 */
	public function copyMergedTo(additionalState:RenderState, state:RenderState):RenderState
	{
		if (additionalState == null)
		{
			return this;
		}

		if (additionalState.applyCullMode)
		{
			state.cullMode = additionalState.cullMode;
		}
		else
		{
			state.cullMode = cullMode;
		}

		if (additionalState.applyDepthTest)
		{
			state.depthTest = additionalState.depthTest;
		}
		else
		{
			state.depthTest = depthTest;
		}

		state.compareMode = compareMode;

		if (additionalState.applyColorWrite)
		{
			state.colorWrite = additionalState.colorWrite;
		}
		else
		{
			state.colorWrite = colorWrite;
		}

		if (additionalState.applyBlendMode)
		{
			state.blendMode = additionalState.blendMode;
		}
		else
		{
			state.blendMode = blendMode;
		}

		return state;
	}

	public function clone():RenderState
	{
		var result:RenderState = new RenderState();
		result.cullMode = this.cullMode;
		result.applyCullMode = this.applyCullMode;
		result.depthTest = this.depthTest;
		result.applyDepthTest = this.applyDepthTest;
		result.compareMode = this.compareMode;
		result.colorWrite = this.colorWrite;
		result.applyColorWrite = this.applyColorWrite;
		result.blendMode = this.blendMode;
		result.applyBlendMode = this.applyBlendMode;
		return result;
	}

	public function toString():String
	{
		return "RenderState[\n" + "\ncullMode=" + cullMode + "\napplyCullMode=" + applyCullMode + "\ndepthTest=" + depthTest + "\napplyDepthTest=" + applyDepthTest + "\ncolorWrite=" + colorWrite + "\napplyColorWrite=" + applyColorWrite + "\nblendMode=" + blendMode + "\napplyBlendMode=" + applyBlendMode + "\n]";
	}
}

