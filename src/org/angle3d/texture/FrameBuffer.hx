package org.angle3d.texture;

import flash.Vector;

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
	public static var SLOT_UNDEF:Int = -1;
    public static var SLOT_DEPTH:Int = -100;
    public static var SLOT_DEPTH_STENCIL:Int = -101;
	
	private var id:Int = -1;
	private var width:Int = 0;
    private var height:Int = 0;
    private var samples:Int = 1;
    private var colorBufs:Vector<RenderBuffer>;
    private var depthBuf:RenderBuffer = null;
    private var colorBufIndex:Int = 0;
    private var srgb:Bool;

	/**
     * <p>
     * Creates a new FrameBuffer with the given width, height, and number
     * of samples. If any textures are attached to this FrameBuffer, then
     * they must have the same number of samples as given in this constructor.
     * <p>
     * Note that if the {@link Renderer} does not expose the 
     * {@link Caps#NonPowerOfTwoTextures}, then an exception will be thrown
     * if the width and height arguments are not power of two.
     * 
     * @param width The width to use
     * @param height The height to use
     * 
     * @throws IllegalArgumentException If width or height are not positive.
     */
	public function new(width:Int, height:Int)
	{
		this.width = width;
        this.height = height;

		colorBufs  = new Vector<RenderBuffer>();
	}
	
	/**
     * Enables the use of a depth buffer for this <code>FrameBuffer</code>.
     * 
     * @param format The format to use for the depth buffer.
     * @throws IllegalArgumentException If <code>format</code> is not a depth format.
     */
    public function setDepthBuffer():Void
	{
        if (id != -1)
            throw "FrameBuffer already initialized.";

        depthBuf = new RenderBuffer();
        depthBuf.slot = SLOT_DEPTH_STENCIL;// : SLOT_DEPTH;
    }
	
	/**
     * Enables the use of a color buffer for this <code>FrameBuffer</code>.
     * 
     * @param format The format to use for the color buffer.
     * @throws IllegalArgumentException If <code>format</code> is not a color format.
     */
    public function setColorBuffer():Void
	{
        if (id != -1)
            throw "FrameBuffer already initialized.";

        var colorBuf:RenderBuffer = new RenderBuffer();
        colorBuf.slot = 0;

        colorBufs.length = 0;
        colorBufs.push(colorBuf);
    }
	
	private function checkSetTexture(tex:TextureMapBase, depth:Bool):Void
	{
        //Image img = tex.getImage();
        //if (img == null)
            //throw "Texture not initialized with RTT.";

        // check that resolution matches texture resolution
        if (width != tex.width || height != tex.height)
            throw "Texture image resolution must match FB resolution";

        //if (samples != tex.getImage().getMultiSamples())
            //throw "Texture samples must match framebuffer samples";
    }
	
	/**
     * If enabled, any shaders rendering into this <code>FrameBuffer</code>
     * will be able to write several results into the renderbuffers
     * by using the <code>gl_FragData</code> array. Every slot in that
     * array maps into a color buffer attached to this framebuffer.
     * 
     * @param enabled True to enable MRT (multiple rendering targets).
     */
    public function setMultiTarget(enabled:Bool):Void
	{
        if (enabled) 
			colorBufIndex = -1;
        else 
			colorBufIndex = 0;
    }

    /**
     * @return True if MRT (multiple rendering targets) is enabled.
     * @see FrameBuffer#setMultiTarget(boolean)
     */
    public function isMultiTarget():Bool
	{
        return colorBufIndex == -1;
    }
	
	/**
     * If MRT is not enabled ({@link FrameBuffer#setMultiTarget(boolean) } is false)
     * then this specifies the color target to which the scene should be rendered.
     * <p>
     * By default the value is 0.
     * 
     * @param index The color attachment index.
     * @throws IllegalArgumentException If index is negative or doesn't map
     * to any attachment on this framebuffer.
     */
    public function setTargetIndex(index:Int):Void
	{
        if (index < 0 || index > 3)
            throw ("Target index must be between 0 and 3");

        if (colorBufs.length < index)
            throw ("The target at " + index + " is not set!");

        colorBufIndex = index;
        //setUpdateNeeded();
    }

    /**
     * @return The color target to which the scene should be rendered.
     * 
     * @see FrameBuffer#setTargetIndex(int) 
     */
    public function getTargetIndex():Int
	{
        return colorBufIndex;
    }

    /**
     * Set the color texture to use for this framebuffer.
     * This automatically clears all existing textures added previously
     * with {@link FrameBuffer#addColorTexture } and adds this texture as the
     * only target.
     * 
     * @param tex The color texture to set.
     */
    public function setColorTexture(tex:Texture2D):Void
	{
        clearColorTargets();
        addColorTexture(tex);
    }
    
    /**
     * Set the color texture to use for this framebuffer.
     * This automatically clears all existing textures added previously
     * with {@link FrameBuffer#addColorTexture } and adds this texture as the
     * only target.
     *
     * @param tex The cube-map texture to set.
     * @param face The face of the cube-map to render to.
     */
    public function setCubeColorTexture(tex:CubeTextureMap, face:Int):Void
	{
        clearColorTargets();
        addCubeColorTexture(tex, face);
    }

    /**
     * Clears all color targets that were set or added previously.
     */
    public function clearColorTargets():Void
	{
        colorBufs.length = 0;
    }

    /**
     * Add a color texture to use for this framebuffer.
     * If MRT is enabled, then each subsequently added texture can be
     * rendered to through a shader that writes to the array <code>gl_FragData</code>.
     * If MRT is not enabled, then the index set with {@link FrameBuffer#setTargetIndex(int) }
     * is rendered to by the shader.
     * 
     * @param tex The texture to add.
     */
    public function addColorTexture(tex:Texture2D):Void
	{
        if (id != -1)
            throw "FrameBuffer already initialized.";

        //Image img = tex.getImage();
        checkSetTexture(tex, false);

        var colorBuf:RenderBuffer = new RenderBuffer();
        colorBuf.slot = colorBufs.length;
        colorBuf.texture = tex;

        colorBufs.push(colorBuf);
    }
    
     /**
     * Add a color texture to use for this framebuffer.
     * If MRT is enabled, then each subsequently added texture can be
     * rendered to through a shader that writes to the array <code>gl_FragData</code>.
     * If MRT is not enabled, then the index set with {@link FrameBuffer#setTargetIndex(int) }
     * is rendered to by the shader.
     *
     * @param tex The cube-map texture to add.
     * @param face The face of the cube-map to render to.
     */
    public function addCubeColorTexture(tex:CubeTextureMap, face:Int):Void
	{
        if (id != -1)
            throw ("FrameBuffer already initialized.");

        //Image img = tex.getImage();
        checkSetTexture(tex, false);

        var colorBuf:RenderBuffer = new RenderBuffer();
        colorBuf.slot = colorBufs.length;
        colorBuf.texture = tex;
        colorBuf.face = face;

        colorBufs.push(colorBuf);
    }

    /**
     * Set the depth texture to use for this framebuffer.
     * 
     * @param tex The color texture to set.
     */
    public function setDepthTexture(tex:Texture2D):Void
	{
        if (id != -1)
            throw ("FrameBuffer already initialized.");

        //Image img = tex.getImage();
        checkSetTexture(tex, true);
        
		if(depthBuf == null)
			depthBuf = new RenderBuffer();
        depthBuf.slot = SLOT_DEPTH_STENCIL;// : SLOT_DEPTH;
        depthBuf.texture = tex;
    }

    /**
     * @return The number of color buffers attached to this texture. 
     */
    public function getNumColorBuffers():Int
	{
        return colorBufs.length;
    }

    /**
     * @param index
     * @return The color buffer at the given index.
     */
    public function getColorBuffer(index:Int):RenderBuffer
	{
        return colorBufs[index];
    }

    /**
     * @return The first color buffer attached to this FrameBuffer, or null
     * if no color buffers are attached.
     */
    public function getFirstColorBuffer():RenderBuffer
	{
        if (colorBufs.length == 0)
            return null;
        
        return colorBufs[0];
    }

    /**
     * @return The depth buffer attached to this FrameBuffer, or null
     * if no depth buffer is attached
     */
    public function getDepthBuffer():RenderBuffer
	{
        return depthBuf;
    }

    /**
     * @return The height in pixels of this framebuffer.
     */
    public function getHeight():Int
	{
        return height;
    }

    /**
     * @return The width in pixels of this framebuffer.
     */
    public function getWidth():Int
	{
        return width;
    }

    /**
     * @return The number of samples when using a multisample framebuffer, or
     * 1 if this is a singlesampled framebuffer.
     */
    public function getSamples():Int
	{
        return samples;
    }

    public function resetObject():Void
	{
        //this.id = -1;
        
        for (i in 0...colorBufs.length)
		{
            colorBufs[i].resetObject();
        }
        
        if (depthBuf != null)
            depthBuf.resetObject();

        //setUpdateNeeded();
    }
	
	public function dispose():Void
	{
		
	}
}

/**
 * RenderBuffer represents either a texture or a 
 * buffer that will be rendered to. RenderBuffers
 * are attached to an attachment slot on a FrameBuffer.
 */
class RenderBuffer
{
	public var texture:TextureMapBase;
	public var id:Int = -1;
	public var slot:Int = -1;
	public var face:Int = -1;
	
	public function new()
	{
		
	}
	
	/**
	 * @return The texture to render to for this <code>RenderBuffer</code>
	 * or null if content should be rendered into a buffer.
	 */
	public function getTexture():TextureMapBase
	{
		return texture;
	}

	/**
	 * Do not use.
	 */
	public function getId():Int
	{
		return id;
	}

	/**
	 * Do not use.
	 */
	public function setId(id:Int):Void
	{
		this.id = id;
	}

	/**
	 * Do not use.
	 */
	public function getSlot():Int 
	{
		return slot;
	}
	
	public function getFace():Int 
	{
		return face;
	}

	public function resetObject():Void
	{
		id = -1;
	}
	
	public function toString():String
	{
		if (texture != null)
		{
			return "TextureTarget[id=" + id + "]";
		}
		else
		{
			return "BufferTarget[id=" + id + "]";
		}
	}
}

