package org.angle3d.renderer;
import js.html.webgl.UniformLocation;
import org.angle3d.shader.Uniform;

#if js
import js.html.CanvasElement;
import js.html.webgl.RenderingContext;

import org.angle3d.error.Assert;
import org.angle3d.material.ProgramType;
import org.angle3d.light.Light;
import org.angle3d.material.BlendMode;
import org.angle3d.material.FaceCullMode;
import org.angle3d.material.RenderState;
import org.angle3d.shader.Attribute;
import org.angle3d.shader.Shader;
import org.angle3d.shader.ShaderVariable;
import org.angle3d.material.TestFunction;

import org.angle3d.shader.ShaderType;
import org.angle3d.math.Color;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.texture.FrameBuffer;
import org.angle3d.texture.Texture;

/**
 * Webgl Renderer
 *
 */
@:access(org.angle3d.material.RenderState)
class WebglRenderer implements Renderer {
	private var canvas:CanvasElement;
	private var mrtExt : { function drawBuffersWEBGL( colors : Array<Int> ) : Void; };
	public var gl : RenderingContext;

	public var enableDepthAndStencil(default, default):Bool;
	public var backgroundColor(default, default):Color;

	private var mAntiAlias:Int = 0;

	private var mRenderContext:RenderContext;

	private var mFrameBuffer:FrameBuffer;

	private var mShader:Shader;

	private var mCurRegisterTextureIndex:Array<Bool>;
	private var mPreRegisterTextureIndex:Array<Bool>;
	private var mRegisterBufferIndex:Int = 0;

	private var _caps:Array<Caps>;

	private var mVpX:Int;
	private var mVpY:Int;
	private var mVpWidth:Int;
	private var mVpHeight:Int;

	private var clipX:Int;
	private var clipY:Int;
	private var clipW:Int;
	private var clipH:Int;

	private var mBackBufferDirty:Bool = true;

	public var backBufferDirty(get, null):Bool;

	private var mStatistics:Statistics;

	private var mShaderTypes:Array<ProgramType> = [ProgramType.VERTEX, ProgramType.FRAGMENT];

	public function new(antiAlias:Int = 0) {
		mAntiAlias = antiAlias;

		#if js
		//canvas = @:privateAccess hxd.Stage.getInstance().canvas;
		gl = canvas.getContextWebGL({alpha:false, antialias:mAntiAlias > 0});
		if ( gl == null )
			throw "Could not acquire GL context";
		// debug if webgl_debug.js is included
		untyped if ( __js__('typeof')(WebGLDebugUtils) != "undefined" ) gl = untyped WebGLDebugUtils.makeDebugContext(gl);
		mrtExt = gl.getExtension('WEBGL_draw_buffers');
		#end

		gl.bindAttribLocation

		mRenderContext = new RenderContext();

		backgroundColor = new Color(0, 0, 0, 1);

		mClipRect = new Rectangle();

		enableDepthAndStencil = true;

		mStatistics = new Statistics();

		mCurRegisterTextureIndex = new Array<Bool>(8, true);
		mPreRegisterTextureIndex = new Array<Bool>(8, true);
		for (i in 0...8) {
			mCurRegisterTextureIndex[i] = false;
			mPreRegisterTextureIndex[i] = false;
		}

		_caps = [];
	}

	private function loadCapabilities():Void {
		_caps.push(Caps.AGAL1);

		if (mProfile == ShaderProfile.STANDARD_EXTENDED) {
			_caps.push(Caps.AGAL2);
			_caps.push(Caps.AGAL3);
		} else if (mProfile == ShaderProfile.STANDARD || mProfile == ShaderProfile.STANDARD_CONSTRAINED) {
			_caps.push(Caps.AGAL2);
		}
	}

	/**
	 * The statistics allow tracking of how data
	 * per frame, such as number of objects rendered, number of triangles, etc.
	 * These are updated when the Renderer's methods are used, make sure
	 * to call `Statistics#clearFrame()` at the appropriate time
	 * to get accurate info per frame.
	 */
	public inline function getStatistics():Statistics {
		return mStatistics;
	}

	private inline function get_backBufferDirty():Bool {
		return mBackBufferDirty;
	}

	public function configureBackBuffer():Void {
		if (mVpWidth >= 32 && mVpHeight >= 32) {
			mContext3D.configureBackBuffer(mVpWidth, mVpHeight, mAntiAlias, enableDepthAndStencil);
			mBackBufferDirty = false;
		}
	}

	public function initialize():Void {
		loadCapabilities();
	}

	public function invalidateState():Void {
		mRenderContext.reset();
	}

	public function clearBuffers(color:Bool, depth:Bool, stencil:Bool):Void {
		var bits:UInt = 0;
		if (color) {
			bits = Context3DClearMask.COLOR;
		}

		if (depth) {
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
	public function applyRenderState(state:RenderState):Void {
		if (state.depthWrite != mRenderContext.depthWriteEnabled ||
		state.depthTest != mRenderContext.depthTestEnabled ||
		state.depthFunc != mRenderContext.depthFunc) {
			var depthFunc:TestFunction = state.depthFunc;
			if (!state.depthTest) {
				depthFunc = TestFunction.ALWAYS;
			}
			mContext3D.setDepthTest(state.depthWrite, depthFunc);

			mRenderContext.depthTestEnabled = state.depthTest;
			mRenderContext.depthWriteEnabled = state.depthWrite;
			mRenderContext.depthFunc = state.depthFunc;
		}

		if (state.colorWrite != mRenderContext.colorWriteEnabled) {
			var colorWrite:Bool = state.colorWrite;
			mContext3D.setColorMask(colorWrite, colorWrite, colorWrite, colorWrite);
			mRenderContext.colorWriteEnabled = colorWrite;
		}

		if (state.cullMode != mRenderContext.cullMode) {
			mContext3D.setCulling(state.cullMode);
			mRenderContext.cullMode = state.cullMode;
		}

		if (state.blendMode != mRenderContext.blendMode) {
			switch (state.blendMode) {
				case BlendMode.Off:
					mContext3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
				case BlendMode.Additive:
					mContext3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE);
				case BlendMode.AlphaAdditive:
					mContext3D.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE);
				case BlendMode.COLOR:
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
				state.backStencilFunction != mRenderContext.backStencilFunction) {
			mRenderContext.frontStencilStencilFailOperation = mRenderContext.frontStencilStencilFailOperation;
			mRenderContext.frontStencilDepthFailOperation = mRenderContext.frontStencilDepthFailOperation;
			mRenderContext.frontStencilDepthPassOperation = mRenderContext.frontStencilDepthPassOperation;
			mRenderContext.backStencilStencilFailOperation = mRenderContext.backStencilStencilFailOperation;
			mRenderContext.backStencilDepthFailOperation = mRenderContext.backStencilDepthFailOperation;
			mRenderContext.backStencilDepthPassOperation = mRenderContext.backStencilDepthPassOperation;
			mRenderContext.frontStencilFunction = mRenderContext.frontStencilFunction;
			mRenderContext.backStencilFunction = mRenderContext.backStencilFunction;

			if (state.stencilTest) {
				mContext3D.setStencilActions(FaceCullMode.FRONT, state.frontStencilFunction, state.frontStencilStencilFailOperation,
											 state.frontStencilDepthFailOperation, state.frontStencilDepthPassOperation);

				mContext3D.setStencilActions(FaceCullMode.BACK, state.backStencilFunction, state.backStencilStencilFailOperation,
											 state.backStencilDepthFailOperation, state.backStencilDepthPassOperation);

				mContext3D.setStencilReferenceValue(0);
			} else {
				mContext3D.setStencilActions(FaceCullMode.NONE, TestFunction.NEVER);
			}

		}

	}

	public function onFrame():Void {

	}

	public function setAntiAlias(antiAlias:Int):Void {
		if (mAntiAlias != antiAlias) {
			mAntiAlias = antiAlias;

			mBackBufferDirty = true;
		}
	}

	public function setViewPort(x:Int, y:Int, width:Int, height:Int):Void {
		if (mVpX != x || mVpY != y || mVpWidth != width || mVpHeight != height) {
			mVpX = x;
			mVpY = y;
			mVpWidth = width;
			mVpHeight = height;

			//if (mStage3D.x != x)
			//mStage3D.x = x;
			//if (mStage3D.y != y)
			//mStage3D.y = y;

			mBackBufferDirty = true;

			//mContext3D.configureBackBuffer(mVpWidth, mVpHeight, mAntiAlias, enableDepthAndStencil);
		}
	}

	public function setClipRect(x:Int, y:Int, width:Int, height:Int):Void {
		if (!mRenderContext.clipRectEnabled) {
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

	public function clearClipRect():Void {
		if (mRenderContext.clipRectEnabled) {
			mRenderContext.clipRectEnabled = false;
			mContext3D.setScissorRectangle(null);

			mClipRect.setEmpty();
		}
	}

	private var maxOutputIndex:Int;
	public function setFrameBuffer(fb:FrameBuffer):Void {
		if (mFrameBuffer == fb)
			return;

		mFrameBuffer = fb;

		if (mFrameBuffer == null) {
			if (maxOutputIndex > 0) {
				for (i in 0...maxOutputIndex) {
					mContext3D.setRenderToTexture(null, false, 0, 0, i);
				}
				maxOutputIndex = 0;
			}
			mContext3D.setRenderToBackBuffer();
		} else
		{
			var curOutputIndex = mFrameBuffer.getNumColorBuffers();
			for (i in 0...curOutputIndex) {
				mContext3D.setRenderToTexture(mFrameBuffer.getColorBuffer(i).texture.getTexture(mContext3D), true, 0, 0, i);
			}

			if (mFrameBuffer.getDepthBuffer() != null) {
				mContext3D.setRenderToTexture(mFrameBuffer.getDepthBuffer().texture.getTexture(mContext3D), true, 0, 0, curOutputIndex);
				curOutputIndex++;
			}

			if (curOutputIndex < maxOutputIndex) {
				for (i in curOutputIndex...maxOutputIndex) {
					mContext3D.setRenderToTexture(null, false, 0, 0, i);
				}
			}
			maxOutputIndex = curOutputIndex;
		}
	}

	public function setShader(shader:Shader):Void {
		#if debug
		Assert.assert(shader != null, "shader cannot be null");
		#end

		if (mShader != shader) {
			mShader = shader;

			#if USE_STATISTICS
			getStatistics().onShaderUse(mShader, true);
			#end

			bindProgram(shader);
		} else
		{
			#if USE_STATISTICS
			getStatistics().onShaderUse(mShader, false);
			#end
		}

		updateShaderUniforms(shader);
	}

	private function updateUniformLocation(shader:Shader, uniform:Uniform):Void {
		var loc:UniformLocation = gl.getUniformLocation(shader.getProgram(), uniform.name);
		if (loc == null) {
			uniform.location = null;
			//// uniform is not declared in shader
			//logger.log(Level.FINE, "Uniform {0} is not declared in shader {1}.", new Object[]{uniform.getName(), shader.getSources()});
		} else{
			uniform.location = loc;
		}
	}

	private function bindProgram(shader:Shader):Void {
		var shaderId = shader.getId();

		if (mRenderContext.boundShaderProgram != shaderId) {
			gl.useProgram(shaderId);
			mStatistics.onShaderUse(shader, true);
			mRenderContext.boundShader = shader;
			mRenderContext.boundShaderProgram = shaderId;
		} else {
			mStatistics.onShaderUse(shader, false);
		}
	}

	private function updateUniform(shader:Shader, uniform:Uniform):Void {
		var program = shader.getProgram();

		Assert.assert(program != null);

		var loc = uniform.location;
		if (loc == null) {
			return;
		}

	}

	private inline function updateShaderUniforms(shader:Shader):Void {
		shader.updateUniforms(this);
	}

	public function resetStates():Void {
		for (i in 0...8) {
			if (mPreRegisterTextureIndex[i]) {
				mContext3D.setTextureAt(i, null);
				mPreRegisterTextureIndex[i] = false;
			}

			mRenderContext.boundTextures[i] = null;
			mRenderContext.boundTextureStates[i].reset();
			mContext3D.setVertexBufferAt(i, null);
			mCurRegisterTextureIndex[i] = false;
		}

		mLastProgram = null;
		mShader = null;
		mFrameBuffer = null;
	}

	public function setTexture(index:Int, texture:Texture):Void {
		mCurRegisterTextureIndex[index] = true;

		if (mRenderContext.boundTextures[index] != texture) {
			mContext3D.setTextureAt(index, texture.getTexture(mContext3D));
			mRenderContext.boundTextures[index] = texture;
		}

		//if (Angle3D.supportSetSamplerState)
		//{
		//var textureState:TextureState = mRenderContext.boundTextureStates[index];
		//if (textureState.wrapMode != texture.wrapMode ||
		//textureState.textureFilter != texture.textureFilter ||
		//textureState.mipFilter != texture.mipFilter)
		//{
		//textureState.wrapMode = texture.wrapMode;
		//textureState.textureFilter = texture.textureFilter;
		//textureState.mipFilter = texture.mipFilter;
		//Angle3D.setSamplerStateAt(index, texture.wrapMode.toString(), texture.textureFilter.toString(), texture.mipFilter.toString());
		//}
		//}
	}

	public inline function setShaderConstants(shaderType:ShaderType, firstRegister:Int, data:Array<Float>, numRegisters:Int):Void {
		#if USE_STATISTICS
		mStatistics.onUniformSet();
		#end
		mContext3D.setProgramConstantsFromVector(mShaderTypes[shaderType.toInt()], firstRegister, data, numRegisters);
	}

	public inline function setShaderConstantsFromByteArray(shaderType:ShaderType, firstRegister:Int, numRegisters:Int, data:ByteArray,byteArrayOffset:UInt):Void {
		#if USE_STATISTICS
		mStatistics.onUniformSet();
		#end
		mContext3D.setProgramConstantsFromByteArray(mShaderTypes[shaderType.toInt()], firstRegister, numRegisters, data, byteArrayOffset);
	}

	public inline function setDepthTest(depthMask:Bool, passCompareMode:TestFunction):Void {
		mContext3D.setDepthTest(depthMask, passCompareMode);
	}

	public inline function setCulling(cullMode:FaceCullMode):Void {
		mContext3D.setCulling(cullMode);
	}

	public function cleanup():Void {
		invalidateState();
	}

	public function renderMesh(mesh:Mesh, lodLevel:Int = 0):Void {
		setVertexBuffers(mesh);

		#if USE_STATISTICS
		getStatistics().onMeshDrawn(mesh, lodLevel);
		#end

		if (lodLevel == 0) {
			#if USE_STATISTICS
			getStatistics().renderTriangle += mesh.getTriangleCount();
			#end
			mContext3D.drawTriangles(mesh.getIndexBuffer3D(mContext3D));
		} else
		{
			#if USE_STATISTICS
			getStatistics().renderTriangle += mesh.getTriangleCount(lodLevel);
			#end
			mContext3D.drawTriangles(mesh.getLodIndexBuffer3D(mContext3D,lodLevel));
		}

		#if USE_STATISTICS
		getStatistics().drawCount++;
		#end
	}

	public inline function present():Void {
		mContext3D.present();
	}

	private inline function get_stage3D():Stage3D {
		return mStage3D;
	}

	private inline function get_context3D():Context3D {
		return mContext3D;
	}

	public function resetTextures():Void {
		for (i in 0...8) {
			mCurRegisterTextureIndex[i] = false;
		}
	}

	public function cleanTextures():Void {
		for (i in 0...8) {
			if (mCurRegisterTextureIndex[i] == false && mPreRegisterTextureIndex[i]) {
				mContext3D.setTextureAt(i, null);
				mRenderContext.boundTextures[i] = null;
			}

			mPreRegisterTextureIndex[i] = mCurRegisterTextureIndex[i];
		}
	}

	/**
	 * 清理之前遗留下来未使用的属性寄存器
	 */
	private inline function clearVertexBuffers(maxRegisterIndex:Int):Void {
		if (mRegisterBufferIndex > maxRegisterIndex) {
			for (i in (maxRegisterIndex + 1)...(mRegisterBufferIndex + 1)) {
				mContext3D.setVertexBufferAt(i, null);
			}
		}
		mRegisterBufferIndex = maxRegisterIndex;
	}

	/**
	 * 传递相关信息
	 * @param mesh
	 */
	private inline function setVertexBuffers(mesh:Mesh):Void {
		//属性寄存器使用的最大索引
		var maxRegisterIndex:Int = 0;

		var attributes:Array<ShaderVariable> = mShader.getAttributeList().params;
		for (i in 0...attributes.length) {
			var attribute:Attribute = cast attributes[i];
			mContext3D.setVertexBufferAt(attribute.index,
			mesh.getVertexBuffer3D(mContext3D, attribute.bufferType),
			0, attribute.format);
			if (attribute.index > maxRegisterIndex) {
				maxRegisterIndex = attribute.index;
			}
		}

		//清理当前渲染对象未使用的VertexBuffer
		clearVertexBuffers(maxRegisterIndex);
	}

	public inline function getCaps():Array<Caps> {
		return _caps;
	}
}

#end