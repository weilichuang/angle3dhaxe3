package org.angle3d.texture;

/**
 * <p>
 * <code>FrameBuffer</code>s are rendering surfaces allowing
 * off-screen rendering and render-to-texture functionality.
 * Instead of the scene rendering to the screen, it is rendered into the
 * FrameBuffer, the result can be either a texture or a buffer.
 * <p>
 * A <code>FrameBuffer</code> supports two methods of rendering,
 * using a {@link Texture} or using a buffer.
 * When using a texture, the result of the rendering will be rendered
 * onto the texture, after which the texture can be placed on an object
 * and rendered as if the texture was uploaded from disk.
 * When using a buffer, the result is rendered onto
 * a buffer located on the GPU, the data of this buffer is not accessible
 * to the user. buffers are useful if one
 * wishes to retrieve only the color content of the scene, but still desires
 * depth testing (which requires a depth buffer).
 * Buffers can be copied to other framebuffers
 * including the main screen, by using
 * {@link Renderer#copyFrameBuffer(org.angle3d.texture.FrameBuffer, org.angle3d.texture.FrameBuffer) }.
 * The content of a {@link RenderBuffer} can be retrieved by using
 * {@link Renderer#readFrameBuffer(org.angle3d.texture.FrameBuffer, java.nio.ByteBuffer) }.
 * <p>
 * <code>FrameBuffer</code>s have several attachment points, there are
 * several <em>color</em> attachment points and a single <em>depth</em>
 * attachment point.
 * The color attachment points support image formats such as
 * {@link Format#RGBA8}, allowing rendering the color content of the scene.
 * The depth attachment point requires a depth image format.
 *
 * @see Renderer#setFrameBuffer(org.angle3d.texture.FrameBuffer)
 *
 */
class FrameBuffer
{
	public var texture:TextureMapBase;
	public var enableDepthAndStencil:Bool;
	public var antiAlias:Int;
	public var surfaceSelector:Int;

	/**
	 *
	 * @param texture
	 * @param enableDepthAndStencil
	 * @param antiAlias
	 * @param surfaceSelector
	 *
	 */
	public function new(texture:TextureMapBase, enableDepthAndStencil:Bool = false, 
	antiAlias:Int = 0, surfaceSelector:Int = 0)
	{
		this.texture = texture;
		this.enableDepthAndStencil = enableDepthAndStencil;
		this.antiAlias = antiAlias;
		this.surfaceSelector = surfaceSelector;
	}
}

