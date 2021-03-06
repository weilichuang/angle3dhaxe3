package org.angle3d.material;

/**
 * `RenderState` specifies material rendering properties that cannot
 * be controlled by a shader on a {Material}. The properties
 * allow manipulation of rendering features such as depth testing, alpha blending,
 * face culling, stencil operations, and much more.
 *
 * 
 */
class RenderState
{
	/**
	 * The `DEFAULT` render state is the one used by default
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
	 * The `NULL` render state is identical to the {RenderState#DEFAULT}
	 * render state except that depth testing and face culling are disabled.
	 */
	public static var NULL:RenderState;

	/**
	 * The `ADDITIONAL` render state is identical to the
	 * {RenderState#DEFAULT} render state except that all apply
	 * values are set_to false. This allows the `ADDITIONAL` render
	 * state to be combined with other state but only influencing values
	 * that were changed from the original.
	 */
	public static var ADDITIONAL:RenderState;

	public static function __init__():Void
	{
		DEFAULT = new RenderState();

		NULL = new RenderState();
		NULL.cullMode = FaceCullMode.NONE;
		NULL.depthTest = false;

		ADDITIONAL = new RenderState();
		ADDITIONAL.applyCullMode = false;
		ADDITIONAL.applyDepthTest = false;
		ADDITIONAL.applyColorWrite = false;
		ADDITIONAL.applyBlendMode = false;
	}

	private var cullMode:FaceCullMode;
	private var applyCullMode:Bool;

	private var depthTest:Bool;
	private var applyDepthTest:Bool;
	
	private var depthWrite:Bool;
    private var applyDepthWrite:Bool;
	
	private var applyDepthFunc:Bool;
	private var depthFunc:TestFunction;

	private var colorWrite:Bool;
	private var applyColorWrite:Bool;

	private var blendMode:BlendMode;
	private var applyBlendMode:Bool;
	
	private var applyStencilTest:Bool;
	private var stencilTest:Bool;
	
	private var frontStencilStencilFailOperation:StencilOperation;
    private var frontStencilDepthFailOperation:StencilOperation;
    private var frontStencilDepthPassOperation:StencilOperation;
    private var backStencilStencilFailOperation:StencilOperation;
    private var backStencilDepthFailOperation:StencilOperation;
    private var backStencilDepthPassOperation:StencilOperation;
    private var frontStencilFunction:TestFunction;
    private var backStencilFunction:TestFunction;

	public function new()
	{
		cullMode = FaceCullMode.BACK;
		applyCullMode = true;

		applyDepthFunc = true;
		depthFunc = TestFunction.LESS_EQUAL;
		
		depthWrite = true;
		applyDepthWrite = true;

		depthTest = true;
		applyDepthTest = true;

		colorWrite = true;
		applyColorWrite = true;

		blendMode = BlendMode.Off;
		applyBlendMode = true;
		
		frontStencilStencilFailOperation = StencilOperation.KEEP;
	    frontStencilDepthFailOperation = StencilOperation.KEEP;
	    frontStencilDepthPassOperation = StencilOperation.KEEP;
	    backStencilStencilFailOperation = StencilOperation.KEEP;
	    backStencilDepthFailOperation = StencilOperation.KEEP;
	    backStencilDepthPassOperation = StencilOperation.KEEP;
	    frontStencilFunction = TestFunction.ALWAYS;
	    backStencilFunction = TestFunction.ALWAYS;
	}
	
	/**
     * Enable stencil testing.
     *
     * <p>Stencil testing can be used to filter pixels according to the stencil
     * buffer. Objects can be rendered with some stencil operation to manipulate
     * the values in the stencil buffer, then, other objects can be rendered
     * to test against the values written previously.
     *
     * @param enabled Set to true to enable stencil functionality. If false
     * all other parameters are ignored.
     *
     * @param frontStencilStencilFailOperation Sets the operation to occur when
     * a front-facing triangle fails the front stencil function.
     * @param frontStencilDepthFailOperation Sets the operation to occur when
     * a front-facing triangle fails the depth test.
     * @param frontStencilDepthPassOperation Set the operation to occur when
     * a front-facing triangle passes the depth test.
     * @param backStencilStencilFailOperation Set the operation to occur when
     * a back-facing triangle fails the back stencil function.
     * @param backStencilDepthFailOperation Set the operation to occur when
     * a back-facing triangle fails the depth test.
     * @param backStencilDepthPassOperation Set the operation to occur when
     * a back-facing triangle passes the depth test.
     * @param frontStencilFunction Set the test function for front-facing triangles.
     * @param backStencilFunction Set the test function for back-facing triangles.
     */
    public function setStencil(enabled:Bool,
							frontStencilStencilFailOperation:StencilOperation,
							frontStencilDepthFailOperation:StencilOperation,
							frontStencilDepthPassOperation:StencilOperation,
							backStencilStencilFailOperation:StencilOperation,
							backStencilDepthFailOperation:StencilOperation,
							backStencilDepthPassOperation:StencilOperation,
							frontStencilFunction:TestFunction,
							backStencilFunction:TestFunction):Void
	{
        this.stencilTest = enabled;
        this.applyStencilTest = true;
        this.frontStencilStencilFailOperation = frontStencilStencilFailOperation;
        this.frontStencilDepthFailOperation = frontStencilDepthFailOperation;
        this.frontStencilDepthPassOperation = frontStencilDepthPassOperation;
        this.backStencilStencilFailOperation = backStencilStencilFailOperation;
        this.backStencilDepthFailOperation = backStencilDepthFailOperation;
        this.backStencilDepthPassOperation = backStencilDepthPassOperation;
        this.frontStencilFunction = frontStencilFunction;
        this.backStencilFunction = backStencilFunction;
    }
	
	/**
     * Set the depth conparison function to the given TestFunction 
     * default is LessOrEqual (GL_LEQUAL)
     * @see TestFunction
     * @see RenderState#setDepthTest(boolean) 
     * @param depthFunc the depth comparison function
     */
    public function setDepthFunc(depthFunc:TestFunction):Void
	{       
        applyDepthFunc = true;
        this.depthFunc = depthFunc;
    }
	
	public function getDepthFunc():TestFunction
	{
		return this.depthFunc;
	}

	/**
	 * Enable writing color.
	 *
	 * <p>When color write is enabled, the result of a fragment shader, the
	 * `gl_FragColor`, will be rendered into the color buffer
	 * (including alpha).
	 *
	 * @param colorWrite set_to true to enable color writing.
	 */
	public function setColorWrite(colorWrite:Bool):Void
	{
		applyColorWrite = true;
		this.colorWrite = colorWrite;
	}
	
	public function getColorWrite():Bool
	{
		return this.colorWrite;
	}

	/**
	 * set_the face culling mode.
	 *
	 * <p>See the {FaceCullMode} enum on what each value does.
	 * Face culling will project the triangle's points onto the screen
	 * and determine if the triangle is in counter-clockwise order or
	 * clockwise order. If a triangle is in counter-clockwise order, then
	 * it is considered a front-facing triangle, otherwise, it is considered
	 * a back-facing triangle.
	 *
	 * @param cullMode the face culling mode.
	 */
	public function setCullMode(cullMode:FaceCullMode):Void
	{
		applyCullMode = true;
		this.cullMode = cullMode;
	}
	
	public function getCullMode():FaceCullMode
	{
		return this.cullMode;
	}

	/**
	 * set_the blending mode.
	 *
	 * <p>When blending is enabled, (`blendMode` is not {BlendMode#Off})
	 * the input pixel will be blended with the pixel
	 * already in the color buffer. The blending operation is determined
	 * by the {BlendMode}. For example, the {BlendMode#Additive}
	 * will add the input pixel's color to the color already in the color buffer:
	 * <br/>
	 * `Result = Source Color + Destination Color`
	 *
	 * @param blendMode The blend mode to use. set_to {BlendMode#Off}
	 * to disable blending.
	 */
	public function setBlendMode(blendMode:BlendMode):Void
	{
		applyBlendMode = true;
		this.blendMode = blendMode;
	}
	
	public inline function getBlendMode():BlendMode
	{
		return this.blendMode;
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
	
	public function isDepthTest():Bool
	{
		return this.depthTest;
	}
	
	public function setDepthWrite(depthWrite:Bool):Void
	{
		applyDepthWrite = true;
		this.depthWrite = depthWrite;
	}
	
	public function isDepthWrite():Bool
	{
		return this.depthWrite;
	}

	/**
	 * Merges this state and additionalState into
	 * the parameter state based on a specific criteria.
	 *
	 * <p>The criteria for this merge is the following:<br/>
	 * For every given property, such as alpha test or depth write, check
	 * if it was modified from the original in the additionalState
	 * if it was modified, then copy the property from the additionalState
	 * into the parameter state, otherwise, copy the property from `this`
	 * into the parameter state. If additionalState
	 * is `null`, then no modifications are made and `this` is returned,
	 * otherwise, the parameter state is returned with the result
	 * of the merge.
	 *
	 * @param additionalState The additionalState, from which data is taken only
	 * if it was modified by the user.
	 * @param state Contains output of the method if additionalState
	 * is not null.
	 * @return state if additionalState is non-null,
	 * otherwise returns this
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
		
		if (additionalState.applyDepthWrite) 
		{
            state.depthWrite = additionalState.depthWrite;
        } 
		else 
		{
            state.depthWrite = depthWrite;
        }

		if (additionalState.applyDepthTest)
		{
			state.depthTest = additionalState.depthTest;
		}
		else
		{
			state.depthTest = depthTest;
		}

		if(additionalState.applyDepthFunc)
			state.depthFunc = additionalState.depthFunc;
		else
			state.depthFunc = depthFunc;

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
		
		if (additionalState.applyStencilTest)
		{
            state.stencilTest = additionalState.stencilTest;

            state.frontStencilStencilFailOperation = additionalState.frontStencilStencilFailOperation;
            state.frontStencilDepthFailOperation = additionalState.frontStencilDepthFailOperation;
            state.frontStencilDepthPassOperation = additionalState.frontStencilDepthPassOperation;

            state.backStencilStencilFailOperation = additionalState.backStencilStencilFailOperation;
            state.backStencilDepthFailOperation = additionalState.backStencilDepthFailOperation;
            state.backStencilDepthPassOperation = additionalState.backStencilDepthPassOperation;

            state.frontStencilFunction = additionalState.frontStencilFunction;
            state.backStencilFunction = additionalState.backStencilFunction;
        }
		else
		{
            state.stencilTest = stencilTest;

            state.frontStencilStencilFailOperation = frontStencilStencilFailOperation;
            state.frontStencilDepthFailOperation = frontStencilDepthFailOperation;
            state.frontStencilDepthPassOperation = frontStencilDepthPassOperation;

            state.backStencilStencilFailOperation = backStencilStencilFailOperation;
            state.backStencilDepthFailOperation = backStencilDepthFailOperation;
            state.backStencilDepthPassOperation = backStencilDepthPassOperation;

            state.frontStencilFunction = frontStencilFunction;
            state.backStencilFunction = backStencilFunction;
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
		
		result.depthWrite = this.depthWrite;
		result.applyDepthWrite = this.applyDepthWrite;
		
		result.depthFunc = this.depthFunc;
		result.applyDepthFunc = this.applyDepthFunc;
		
		result.colorWrite = this.colorWrite;
		result.applyColorWrite = this.applyColorWrite;
		
		result.blendMode = this.blendMode;
		result.applyBlendMode = this.applyBlendMode;
		
		result.stencilTest = this.stencilTest;
		result.applyStencilTest = this.applyStencilTest;
		
		result.frontStencilStencilFailOperation = this.frontStencilStencilFailOperation;
		result.frontStencilDepthFailOperation = this.frontStencilDepthFailOperation;
		result.frontStencilDepthPassOperation = this.frontStencilDepthPassOperation;
		result.backStencilStencilFailOperation = this.backStencilStencilFailOperation;
		result.backStencilDepthFailOperation = this.backStencilDepthFailOperation;
		result.backStencilDepthPassOperation = this.backStencilDepthPassOperation;
		
		result.frontStencilFunction = this.frontStencilFunction;
		result.backStencilFunction = this.backStencilFunction;
		
		return result;
	}
	
	public function equals(rs:RenderState):Bool
	{
        if (rs == null)
		{
            return false;
        }

        if (cullMode != rs.cullMode)
		{
            return false;
        }

        if (depthWrite != rs.depthWrite)
		{
            return false;
        }

        if (depthTest != rs.depthTest) 
		{
            return false;
        }
        if (depthTest) 
		{
            if (depthFunc != rs.depthFunc)
			{
                return false;
            }
        }

        if (colorWrite != rs.colorWrite) 
		{
            return false;
        }

        if (blendMode != rs.blendMode)
		{
            return false;
        }

        //if (alphaTest != rs.alphaTest) 
		//{
            //return false;
        //}
		//
        //if (alphaTest)
		//{
            //if (alphaFunc != rs.alphaFunc)
			//{
                //return false;
            //}
        //}

        if (stencilTest != rs.stencilTest)
		{
            return false;
        }

        if (stencilTest) 
		{
            if (frontStencilStencilFailOperation != rs.frontStencilStencilFailOperation) 
			{
                return false;
            }
            if (frontStencilDepthFailOperation != rs.frontStencilDepthFailOperation)
			{
                return false;
            }
            if (frontStencilDepthPassOperation != rs.frontStencilDepthPassOperation) 
			{
                return false;
            }
            if (backStencilStencilFailOperation != rs.backStencilStencilFailOperation) 
			{
                return false;
            }
            if (backStencilDepthFailOperation != rs.backStencilDepthFailOperation) 
			{
                return false;
            }

            if (backStencilDepthPassOperation != rs.backStencilDepthPassOperation)
			{
                return false;
            }
            if (frontStencilFunction != rs.frontStencilFunction) 
			{
                return false;
            }
            if (backStencilFunction != rs.backStencilFunction) 
			{
                return false;
            }
        }

        return true;
    }

	public function toString():String
	{
		return "RenderState[\n"
                + "\ncullMode=" + cullMode
                + "\napplyCullMode=" + applyCullMode
				
                + "\ndepthWrite=" + depthWrite
                + "\napplyDepthWrite=" + applyDepthWrite
				
                + "\ndepthTest=" + depthTest
                + "\ndepthFunc=" + depthFunc
                + "\napplyDepthTest=" + applyDepthTest
				
                + "\ncolorWrite=" + colorWrite
                + "\napplyColorWrite=" + applyColorWrite
				
                + "\nblendMode=" + blendMode
                + "\napplyBlendMode=" + applyBlendMode    
                + "\n]";
	}
}

