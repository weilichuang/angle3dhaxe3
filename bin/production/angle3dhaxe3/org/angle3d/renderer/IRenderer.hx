package org.angle3d.renderer;

import flash.display.Stage3D;
import flash.display3D.Context3D;
import flash.Vector;
import org.angle3d.material.CullMode;
import org.angle3d.material.RenderState;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.material.TestFunction;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.texture.FrameBuffer;
import org.angle3d.texture.TextureMapBase;


/**
 * The <code>Renderer</code> is responsible for taking rendering commands and
 * executing them on the underlying video hardware.
 *
 * @author andy
 */
//TODO 添加设置 antiAlias
interface IRenderer
{
	var stage3D(get,null):Stage3D;

	var context3D(get, null):Context3D;
	
	var enableDepthAndStencil(default, default):Bool;
	
	function setAntiAlias(antiAlias:Int):Void;
	
	function setTextureAt(index:Int, map:TextureMapBase):Void;

	/**
	 * <p>设置着色器程序的常量输入</p>
	 * <p>设置要通过顶点或片段着色器程序访问的常量数组</p>
	 * <p>Program3D 中设置的常量在着色器程序内作为常量寄存器访问</p>
	 * <p>每个常量寄存器都由 4 个浮点值（x、y、z、w）组成</p>
	 * <p>因此，每个寄存器都要求数据 Vector 中有 4 个条目</p>
	 * <p>您可以为顶点程序设置 128 个寄存器，为片段程序设置 28 个寄存器</p>
	 * @param shaderType 着色器程序类型
	 * @param firstRegister 要设置的首个常量寄存器的索引
	 * @param data 浮点常量值。data 中至少有 numRegisters 4 个元素。
	 * @param numRegisters 要设置的常量数量。指定 -1（默认值），设置足够的寄存器以使用所有可用数据。
	 *
	 */
	function setShaderConstants(shaderType:ShaderType, firstRegister:Int, data:Vector<Float>, numRegisters:Int = -1):Void;

	/**
	 * Invalidates the current rendering state.
	 */
	function invalidateState():Void;

	/**
	 * Clears certain channels of the currently bound framebuffer.
	 *
	 * @param color True if to clear colors (RGBA)
	 * @param depth True if to clear depth/z
	 * @param stencil True if to clear stencil buffer (if available, otherwise
	 * ignored)
	 */
	function clearBuffers(color:Bool, depth:Bool, stencil:Bool):Void;

	/**
	 * Sets the background (aka clear) color.
	 *
	 * @param color The background color to set
	 */
	function setBackgroundColor(color:Int):Void;

	/**
	 * Applies the given {@link RenderState}, making the necessary
	 * calls so that the state is applied.
	 */
	function applyRenderState(state:RenderState):Void;


	function setDepthTest(depthMask:Bool, passCompareMode:TestFunction):Void;

	function setCulling(cullMode:CullMode):Void;

	/**
	 * Called when a new frame has been rendered.
	 */
	function onFrame():Void;

	/**
	 * 设置视窗位置和大小
	 *
	 * @param x The x coordinate of the viewport
	 * @param y The y coordinate of the viewport
	 * @param width Width of the viewport
	 * @param height Height of the viewport
	 */
	function setViewPort(x:Int, y:Int, width:Int, height:Int):Void;

	/**
	 * 设置一个裁剪矩形，绘制遮罩的类型。
	 * 渲染器仅绘制到裁剪矩形内部的区域。
	 * 裁剪不影响清除操作。
	 *
	 * @param x The x coordinate of the clip rect
	 * @param y The y coordinate of the clip rect
	 * @param width Width of the clip rect
	 * @param height Height of the clip rect
	 */
	function setClipRect(x:Int, y:Int, width:Int, height:Int):Void;

	/**
	 * Clears the clipping rectangle set_with
	 * {@link #setClipRect(int, int, int, int) }.
	 */
	function clearClipRect():Void;

	/**
	 * Sets the framebuffer that will be drawn to.
	 */
	function setFrameBuffer(fb:FrameBuffer):Void;

	/**
	 * Sets the shader to use for rendering.
	 * If the shader has not been uploaded yet, it is compiled
	 * and linked. If it has been uploaded, then the
	 * uniform data is updated and the shader is set.
	 *
	 * @param shader The shader to use for rendering.
	 */
	function setShader(shader:Shader):Void;

	/**
	 * Renders <code>count</code> meshes, with the geometry data supplied.
	 * The shader which is currently set_with <code>setShader</code> is
	 * responsible for transforming the input verticies into clip space
	 * and shading it based on the given vertex attributes.
	 *
	 * @param mesh The mesh to render
	 */
	function renderMesh(mesh:Mesh):Void;

//	function renderShadow(mesh:Mesh, light:Light, cam:Camera3D):Void;

	/**
	 * Synchronize graphics subsytem rendering
	 */
	function present():Void;

	/**
	 * Cleanup
	 */
	function cleanup():Void;
}


