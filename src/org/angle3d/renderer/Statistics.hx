package org.angle3d.renderer;

import org.angle3d.material.shader.Shader;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.texture.FrameBuffer;
import org.angle3d.texture.Texture;

/**
 * The statistics class allows tracking of real-time rendering statistics.
 * <p>
 * The Statistics can be retrieved by using Renderer.getStatistics().
 
 */
class Statistics
{
	private var enabled:Bool = false;

    private var numObjects:Int;
    private var numLights:Int;
    private var numTriangles:Int;
    private var numVertices:Int;
    private var numShaderSwitches:Int;
    private var numTextureBinds:Int;
    private var numFboSwitches:Int;
    private var numUniformsSet:Int;
	
	private var memoryShaders:Int;
    private var memoryFrameBuffers:Int;
    private var memoryTextures:Int;
	
	private var lastShader:Int = -1;
	
	private var shadersUsed:Array<Int>;
	private var texturesUsed:Array<Int>;
	private var fbosUsed:Array<Int>;
	
	public var totalTriangle:Int = 0;
	public var renderTriangle:Int = 0;
	public var drawCount:Int = 0;

	public function new() 
	{
		shadersUsed = new Array<Int>();
		texturesUsed = new Array<Int>();
		fbosUsed = new Array<Int>();
	}
	
	/**
     * Called by the Renderer when a mesh has been drawn.
     */
	public function onMeshDrawn(mesh:Mesh, lod:Int, count:Int = 1):Void
	{
		if( !enabled )
            return;
            
        numObjects += 1;
        numTriangles += mesh.getTriangleCount(lod) * count;
        numVertices += mesh.getVertexCount() * count;
	}
	
	/**
     * Called by the Renderer when a shader has been utilized.
     * 
     * @param shader The shader that was used
     * @param wasSwitched If true, the shader has required a state switch
     */
	public function onShaderUse(shader:Shader, wasSwitched:Bool):Void
	{
		if (!enabled)
			return;
			
		if (lastShader != shader.id)
		{
			lastShader = shader.id;
			if (shadersUsed.indexOf(lastShader) == -1)
			{
				shadersUsed.push(lastShader);
			}
		}
		
		if (wasSwitched)
            numShaderSwitches++;
	}
	
	/**
     * Called by the Renderer when a uniform was set.
     */
    public function onUniformSet():Void
	{
        if( !enabled )
            return;
        numUniformsSet ++;
    }
	
	/**
     * Called by the Renderer when a texture has been set.
     * 
     * @param image The image that was set
     * @param wasSwitched If true, the texture has required a state switch
     */
	public function onTextureUse(texture:Texture, wasSwitched:Bool):Void
	{
		if (!enabled)
			return;
			
		if (texturesUsed.indexOf(texture.id) == -1)
		{
			texturesUsed.push(texture.id);
		}
		
		if (wasSwitched)
            numTextureBinds++;
	}
	
	/**
     * Called by the Renderer when a framebuffer has been set.
     * 
     * @param fb The framebuffer that was set
     * @param wasSwitched If true, the framebuffer required a state switch
     */
	public function onFrameBufferUse(fb:FrameBuffer, wasSwitched:Bool):Void
	{
		if (!enabled)
			return;
			
		if (fbosUsed.indexOf(fb.id) == -1)
		{
			fbosUsed.push(fb.id);
		}
		
		if (wasSwitched)
            numFboSwitches++;
	}
	
	public function clearFrame():Void
	{
		shadersUsed.length = 0;
		texturesUsed.length = 0;
		fbosUsed.length = 0;
		
		numObjects = 0;
        numLights = 0;
        numTriangles = 0;
        numVertices = 0;
        numShaderSwitches = 0;
        numTextureBinds = 0;
        numFboSwitches = 0;
        numUniformsSet = 0;
        
        lastShader = -1;
	}
	
	/**
     * Called by the Renderer when it creates a new shader
     */
    public function onNewShader():Void
	{
        if( !enabled )
            return;
        memoryShaders ++;
    }

    /**
     * Called by the Renderer when it creates a new texture
     */
    public function onNewTexture():Void
	{
        if( !enabled )
            return;
        memoryTextures ++;
    }

    /**
     * Called by the Renderer when it creates a new framebuffer
     */
    public function onNewFrameBuffer():Void
	{
        if( !enabled )
            return;
        memoryFrameBuffers ++;
    }

    /**
     * Called by the Renderer when it deletes a shader
     */
    public function onDeleteShader():Void
	{
        if( !enabled )
            return;
        memoryShaders --;
    }

    /**
     * Called by the Renderer when it deletes a texture
     */
    public function onDeleteTexture():Void
	{
        if( !enabled )
            return;
        memoryTextures --;
    }

    /**
     * Called by the Renderer when it deletes a framebuffer
     */
    public function onDeleteFrameBuffer():Void
	{
        if( !enabled )
            return;
        memoryFrameBuffers --;
    }

    /**
     * Called by the RenderManager once filtering has happened.
     *
     * @param lightCount the number of lights which will be passed to the materials for inclusion in rendering.
     */
    public function onLights(lightCount:Int):Void
	{
        if (!enabled)
		{
            return;
        }

        numLights += lightCount;
    }

    /**
     * Called when video memory is cleared.
     */
    public function clearMemory():Void
	{
        memoryFrameBuffers = 0;
        memoryShaders = 0;
        memoryTextures = 0;
    }

    public function setEnabled( f:Bool ):Void 
	{
        this.enabled = f;
    }
    
    public function isEnabled():Bool 
	{
        return enabled;
    }
}