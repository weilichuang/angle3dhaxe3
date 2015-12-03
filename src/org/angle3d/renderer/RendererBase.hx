package org.angle3d.renderer;

import de.polygonal.ds.error.Assert;
import flash.display.Stage3D;
import flash.display3D.Context3D;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DClearMask;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DTriangleFace;
import flash.display3D.Program3D;
import flash.geom.Rectangle;
import flash.utils.ByteArray;
import flash.Vector;
import org.angle3d.light.Light;
import org.angle3d.material.BlendMode;
import org.angle3d.material.CullMode;
import org.angle3d.material.RenderState;
import org.angle3d.material.shader.AttributeParam;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderParam;
import org.angle3d.material.TestFunction;
import org.angle3d.math.Color;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.texture.FrameBuffer;
import org.angle3d.texture.TextureMapBase;

/**
 * The <code>Renderer</code> is responsible for taking rendering commands and
 * executing them on the underlying video hardware.
 *
 * @author weilichuang
 */
@:access(org.angle3d.material.RenderState)
class RendererBase
{
	public var stage3D(get, null):Stage3D;
	public var context3D(get, null):Context3D;
	
	public var enableDepthAndStencil(default, default):Bool;
	public var backgroundColor(default, default):Color;
	
	private var mContext3D:Context3D;

	private var mStage3D:Stage3D;
	
	private var mAntiAlias:Int = 0;

	private var mRenderContext:RenderContext;

	private var mClipRect:Rectangle;

	private var mFrameBuffer:FrameBuffer;

	private var mShader:Shader;

	private var mLastProgram:Program3D;

	private var mRegisterTextureIndex:Int = 0;
	private var mRegisterBufferIndex:Int = 0;
	
	private var _caps:Array<Caps>;
	
	private var mVpX:Int;
	private var mVpY:Int;
	private var mVpWidth:Int;
	private var mVpHeight:Int;

	public function new(stage3D:Stage3D)
	{
		mStage3D = stage3D;
		mContext3D = mStage3D.context3D;

		mRenderContext = new RenderContext();

		backgroundColor = new Color(0, 0, 0, 1);

		mClipRect = new Rectangle();

		enableDepthAndStencil = true;
		
		_caps = [];
	}
	
	public function initialize():Void
	{
		
	}

	public function invalidateState():Void
	{
		mRenderContext.reset();
	}

	public function clearBuffers(color:Bool, depth:Bool, stencil:Bool):Void
	{
		var bits:UInt = 0;
		if (color)
		{
			bits = Context3DClearMask.COLOR;
		}

		if (depth)
		{
			bits |= Context3DClearMask.DEPTH;
		}

		if (stencil)
			bits |= Context3DClearMask.STENCIL;

		mContext3D.clear(backgroundColor.r, backgroundColor.g, backgroundColor.b, backgroundColor.a, 1, 0, bits);
	}

	/**
	 *
	 * @param state
	 *
	 */
	public function applyRenderState(state:RenderState):Void
	{
		if (state.depthWrite != mRenderContext.depthWriteEnabled ||
			state.depthTest != mRenderContext.depthTestEnabled || 
			state.depthFunc != mRenderContext.depthFunc)
		{
			var depthFunc:TestFunction = state.depthFunc;
			if (!state.depthTest)
			{
				depthFunc = TestFunction.ALWAYS;
			}
			mContext3D.setDepthTest(state.depthWrite, depthFunc);
			
			mRenderContext.depthTestEnabled = state.depthTest;
			mRenderContext.depthWriteEnabled = state.depthWrite;
			mRenderContext.depthFunc = state.depthFunc;
		}

		if (state.colorWrite != mRenderContext.colorWriteEnabled)
		{
			var colorWrite:Bool = state.colorWrite;
			mContext3D.setColorMask(colorWrite, colorWrite, colorWrite, colorWrite);
			mRenderContext.colorWriteEnabled = colorWrite;
		}

		if (state.cullMode != mRenderContext.cullMode)
		{
			mContext3D.setCulling(state.cullMode);
			mRenderContext.cullMode = state.cullMode;
		}

		if (state.blendMode != mRenderContext.blendMode)
		{
			switch (state.blendMode)
			{
				case BlendMode.Off:
					mContext3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
				case BlendMode.Additive:
					mContext3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE);
				case BlendMode.AlphaAdditive:
					mContext3D.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE);
				case BlendMode.Color:
					mContext3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR);
				case BlendMode.Alpha:
					mContext3D.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
				case BlendMode.PremultAlpha:
					mContext3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
				case BlendMode.Modulate:
					mContext3D.setBlendFactors(Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.ZERO);
				case BlendMode.ModulateX2:
					mContext3D.setBlendFactors(Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.SOURCE_COLOR);
			}
			mRenderContext.blendMode = state.blendMode;
		}
		
		if (state.stencilTest != mRenderContext.stencilTest ||
			state.frontStencilStencilFailOperation != mRenderContext.frontStencilStencilFailOperation ||
			state.frontStencilDepthFailOperation != mRenderContext.frontStencilDepthFailOperation ||
			state.frontStencilDepthPassOperation != mRenderContext.frontStencilDepthPassOperation ||
			state.backStencilStencilFailOperation != mRenderContext.backStencilStencilFailOperation ||
			state.backStencilDepthFailOperation != mRenderContext.backStencilDepthFailOperation ||
			state.backStencilDepthPassOperation != mRenderContext.backStencilDepthPassOperation ||
			state.frontStencilFunction != mRenderContext.frontStencilFunction ||
			state.backStencilFunction != mRenderContext.backStencilFunction)
		{
			mRenderContext.frontStencilStencilFailOperation = mRenderContext.frontStencilStencilFailOperation;
			mRenderContext.frontStencilDepthFailOperation = mRenderContext.frontStencilDepthFailOperation;
			mRenderContext.frontStencilDepthPassOperation = mRenderContext.frontStencilDepthPassOperation;
			mRenderContext.backStencilStencilFailOperation = mRenderContext.backStencilStencilFailOperation;
			mRenderContext.backStencilDepthFailOperation = mRenderContext.backStencilDepthFailOperation;
			mRenderContext.backStencilDepthPassOperation = mRenderContext.backStencilDepthPassOperation;
			mRenderContext.frontStencilFunction = mRenderContext.frontStencilFunction;
			mRenderContext.backStencilFunction = mRenderContext.backStencilFunction;
			
			if (state.stencilTest)
			{
				mContext3D.setStencilActions(CullMode.FRONT, state.frontStencilFunction, state.frontStencilStencilFailOperation,
				state.frontStencilDepthFailOperation, state.frontStencilDepthPassOperation);
				
				mContext3D.setStencilActions(CullMode.BACK, state.backStencilFunction, state.backStencilStencilFailOperation,
					state.backStencilDepthFailOperation, state.backStencilDepthPassOperation);
					
				mContext3D.setStencilReferenceValue(0);
			}
			else
			{
				mContext3D.setStencilActions(CullMode.NONE, TestFunction.NEVER);
			}
			
		}

	}

	public function onFrame():Void
	{

	}
	
	
	public function setAntiAlias(antiAlias:Int):Void
	{
		if (mAntiAlias != antiAlias)
		{
			mAntiAlias = antiAlias;
			
			mContext3D.configureBackBuffer(mVpWidth, mVpHeight, mAntiAlias, enableDepthAndStencil);
		}
	}

	public function setViewPort(x:Int, y:Int, width:Int, height:Int):Void
	{
		if (mVpX != x || mVpY != y || mVpWidth != width || mVpHeight != height)
		{
			mVpX = x;
			mVpY = y;
			mVpWidth = width;
			mVpHeight = height;
			
			//if (mStage3D.x != x)
				//mStage3D.x = x;
			//if (mStage3D.y != y)
				//mStage3D.y = y;
			
			mContext3D.configureBackBuffer(mVpWidth, mVpHeight, mAntiAlias, enableDepthAndStencil);
		}
	}

	public function setClipRect(x:Int, y:Int, width:Int, height:Int):Void
	{
		if (!mRenderContext.clipRectEnabled)
		{
			mRenderContext.clipRectEnabled = true;
		}

		//由于渲染目标可能不同，所以不能简单以值是否相等来判断，以后优化
		//if (mClipRect.x != x || mClipRect.y != y ||
			//mClipRect.width != width || mClipRect.height != height)
		{
			mClipRect.setTo(x, y, width, height);
			mContext3D.setScissorRectangle(mClipRect);
		}
	}

	public function clearClipRect():Void
	{
		if (mRenderContext.clipRectEnabled)
		{
			mRenderContext.clipRectEnabled = false;
			mContext3D.setScissorRectangle(null);

			mClipRect.setEmpty();
		}
	}

	private var maxOutputIndex:Int;
	public function setFrameBuffer(fb:FrameBuffer):Void
	{
		if (mFrameBuffer == fb)
			return;

		mFrameBuffer = fb;

		if (mFrameBuffer == null)
		{
			if (maxOutputIndex > 0)
			{
				for (i in 0...maxOutputIndex)
				{
					mContext3D.setRenderToTexture(null, false, 0, 0, i);
				}
				maxOutputIndex = 0;
			}
			mContext3D.setRenderToBackBuffer();
		}
		else
		{
			var curOutputIndex = mFrameBuffer.getNumColorBuffers();
			for (i in 0...curOutputIndex)
			{
				mContext3D.setRenderToTexture(mFrameBuffer.getColorBuffer(i).texture.getTexture(mContext3D), true, 0, 0, i);
			}
			
			if (mFrameBuffer.getDepthBuffer() != null)
			{
				mContext3D.setRenderToTexture(mFrameBuffer.getDepthBuffer().texture.getTexture(mContext3D), true, 0, 0, curOutputIndex);
				curOutputIndex++;
			}
			
			if (curOutputIndex < maxOutputIndex)
			{
				for (i in curOutputIndex...maxOutputIndex)
				{
					mContext3D.setRenderToTexture(null, false, 0, 0, i);
				}
			}
			maxOutputIndex = curOutputIndex;
		}
	}

	public function setShader(shader:Shader):Void
	{
		#if debug
		Assert.assert(shader != null, "shader cannot be null");
		#end

		if (mShader != shader)
		{
			//clearTextures();

			mShader = shader;

			bindProgram(shader);
		}
		
		updateShaderUniforms(shader);
	}
	
	private function bindProgram(shader:Shader):Void
	{
		var program:Program3D = shader.getProgram3D(this.context3D);

		if (mLastProgram != program)
		{
			mContext3D.setProgram(program);
			mLastProgram = program;
		}
	}
	
	private function updateShaderUniforms(shader:Shader):Void
	{
		shader.updateUniforms(this);
	}

	public inline function setTextureAt(index:Int, map:TextureMapBase):Void
	{
		if (index > mRegisterTextureIndex)
		{
			mRegisterTextureIndex = index;
		}
		
		//TODO 减少变化
		mContext3D.setTextureAt(index, map.getTexture(mContext3D));
		
		if(Angle3D.supportSetSamplerState)
			untyped mContext3D["setSamplerStateAt"](index, map.wrapMode, map.textureFilter, map.mipFilter);
	}

	public inline function setShaderConstants(shaderType:Context3DProgramType, firstRegister:Int, data:Vector<Float>, numRegisters:Int):Void
	{
		mContext3D.setProgramConstantsFromVector(shaderType, firstRegister, data, numRegisters);
	}
	
	public inline function setShaderConstantsFromByteArray(shaderType:Context3DProgramType, firstRegister:Int, numRegisters:Int, data:ByteArray,byteArrayOffset:UInt):Void
	{
		mContext3D.setProgramConstantsFromByteArray(shaderType, firstRegister, numRegisters, data, byteArrayOffset);
	}

	public inline function setDepthTest(depthMask:Bool, passCompareMode:TestFunction):Void
	{
		mContext3D.setDepthTest(depthMask, passCompareMode);
	}

	public inline function setCulling(cullMode:CullMode):Void
	{
		mContext3D.setCulling(cullMode);
	}

	public function cleanup():Void
	{
		invalidateState();
	}

	public function renderMesh(mesh:Mesh, lodLevel:Int = 0):Void
	{
		setVertexBuffers(mesh);
		
		if (lodLevel == 0)
		{
			mContext3D.drawTriangles(mesh.getIndexBuffer3D(mContext3D));
		}
		else
		{
			mContext3D.drawTriangles(mesh.getLodIndexBuffer3D(mContext3D,lodLevel));
		}
	}
	
	public inline function present():Void
	{
		mContext3D.present();
	}
	
	private inline function get_stage3D():Stage3D
	{
		return mStage3D;
	}
	
	private inline function get_context3D():Context3D
	{
		return mContext3D;
	}

	public function clearTextures():Void
	{
		for (i in 0...mRegisterTextureIndex + 1)
		{
			mContext3D.setTextureAt(i, null);
		}
		mRegisterTextureIndex = 0;
	}

	/**
	 * 清理之前遗留下来未使用的属性寄存器
	 */
	private inline function clearVertexBuffers(maxRegisterIndex:Int):Void
	{
		if (mRegisterBufferIndex > maxRegisterIndex)
		{
			for (i in (maxRegisterIndex + 1)...(mRegisterBufferIndex + 1))
			{
				mContext3D.setVertexBufferAt(i, null);
			}
		}
		mRegisterBufferIndex = maxRegisterIndex;
	}

	/**
	 * 传递相关信息
	 * @param	vb
	 */
	private inline function setVertexBuffers(mesh:Mesh):Void
	{
		//属性寄存器使用的最大索引
		var maxRegisterIndex:Int = 0;

		var attributes:Vector<ShaderParam> = mShader.getAttributeList().params;
		for (key in attributes)
		{
			var attribute:AttributeParam = cast key;
			mContext3D.setVertexBufferAt(attribute.index, 
										mesh.getVertexBuffer3D(mContext3D, attribute.bufferType), 
										0, attribute.format);
			if (attribute.index > maxRegisterIndex)
			{
				maxRegisterIndex = attribute.index;
			}
		}

		clearVertexBuffers(maxRegisterIndex);
	}
	
	public function getCaps():Array<Caps>
	{
		return _caps;
	}
}


