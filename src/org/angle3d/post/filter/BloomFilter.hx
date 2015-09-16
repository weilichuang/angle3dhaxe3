package org.angle3d.post.filter;

import flash.Vector;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.post.Filter;
import org.angle3d.renderer.IRenderer;
import org.angle3d.renderer.queue.RenderQueue;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.post.Pass;

/**
 * GlowMode specifies if the glow will be applied to the whole scene,or to objects that have aglow color or a glow map
 */
enum GlowMode
{
	/**
	 * Apply bloom filter to bright areas in the scene.
	 */
	Scene;
	/**
	 * Apply bloom only to objects that have a glow map or a glow color.
	 */
	Objects;
	/**
	 * Apply bloom to both bright parts of the scene and objects with glow map.
	 */
	SceneAndObjects;
}

/**
 * BloomFilter is used to make objects in the scene have a glow effect.<br>
 * There are 2 mode : Scene and Objects.<br>
 * Scene mode extracts the bright parts of the scene to make them glow<br>
 * Object mode make objects glow according to their material's glowMap or their GlowColor<br>
 */
class BloomFilter extends Filter
{
	public var glowMode:GlowMode = GlowMode.Scene;
    //Bloom parameters
    public var blurScale:Float = 1.5;
    public var exposurePower:Float = 5.0;
    public var exposureCutOff:Float = 0.0;
    public var bloomIntensity:Float = 2.0;
    public var downSamplingFactor:Float = 1;
    public var preGlowPass:Pass;
    public var extractPass:Pass;
    public var horizontalBlur:Pass = new Pass();
    public var verticalalBlur:Pass = new Pass();
    //private Material extractMat;
    //private Material vBlurMat;
    //private Material hBlurMat;
    public var screenWidth:Int;
    public var screenHeight:Int;    
    public var renderManager:RenderManager;
    public var viewPort:ViewPort;

    public var initalWidth:Int;
    public var initalHeight:Int;

	public function new() 
	{
		super("BloomFilter");
	}
	
	override function initFilter(renderManager:RenderManager, vp:ViewPort, w:Int, h:Int):Void 
	{
		super.initFilter(renderManager, vp, w, h);
		
		this.viewPort = vp;
		this.initalWidth = w;
		this.initalHeight = h;
		
		screenWidth = Std.int(Math.max(1, w / downSamplingFactor));
		screenHeight = Std.int(Math.max(1, h / downSamplingFactor));
		if (glowMode != GlowMode.Scene)
		{
			preGlowPass = new Pass();
			preGlowPass.init(renderManager.getRenderer(), screenWidth, screenHeight);
		}
		
		postRenderPasses = new Vector<Pass>();
		extractPass = new BloomExtractPass(this);
		extractPass.init(renderManager.getRenderer(), screenWidth, screenHeight);
		postRenderPasses.push(extractPass);
		
		horizontalBlur = new HGaussianBlurPass(this);
		horizontalBlur.init(renderManager.getRenderer(), screenWidth, screenHeight);
		postRenderPasses.push(horizontalBlur);
		
		verticalalBlur = new VGaussianBlurPass(this);
		verticalalBlur.init(renderManager.getRenderer(), screenWidth, screenHeight);
		postRenderPasses.push(verticalalBlur);
		
		//final material
		this.material = new Material();
		this.material.load(Angle3D.materialFolder + "material/bloomFinal.mat");
		this.material.setTexture("u_BloomTex", verticalalBlur.getRenderedTexture());
	}
	
	override public function getMaterial():Material 
	{
		material.setFloat("u_BloomIntensity", bloomIntensity);
		return super.getMaterial();
	}
	
	override public function postQueue(queue:RenderQueue):Void 
	{
		super.postQueue(queue);
		
		if (glowMode != GlowMode.Scene)
		{
			var render:IRenderer = renderManager.getRenderer();
			render.backgroundColor = Color.BlackNoAlpha();
			render.clearBuffers(true, true, true);
			renderManager.setForcedTechnique("Glow");
			renderManager.renderViewPortQueues(viewPort, false);
			renderManager.setForcedTechnique(null);
			render.setFrameBuffer(viewPort.getOutputFrameBuffer());
		}
	}
	
	override public function cleanUpFilter(r:IRenderer):Void 
	{
		super.cleanUpFilter(r);
		if (glowMode != GlowMode.Scene)
		{
			preGlowPass.cleanup(r);
		}
	}
	
	/**
     * returns the bloom intensity
     * @return 
     */
    public function getBloomIntensity():Float 
	{
        return bloomIntensity;
    }

    /**
     * intensity of the bloom effect default is 2.0
     * @param bloomIntensity
     */
    public function setBloomIntensity(bloomIntensity:Float):Void 
	{
        this.bloomIntensity = bloomIntensity;
    }

    /**
     * returns the blur scale
     * @return 
     */
    public function getBlurScale():Float 
	{
        return blurScale;
    }

    /**
     * sets The spread of the bloom default is 1.5f
     * @param blurScale
     */
    public function setBlurScale(blurScale:Float):Void 
	{
        this.blurScale = blurScale;
    }

    /**
     * returns the exposure cutoff<br>
     * for more details see {@link #setExposureCutOff(float exposureCutOff)}
     * @return 
     */    
    public function getExposureCutOff():Float
	{
        return exposureCutOff;
    }

    /**
     * Define the color threshold on which the bloom will be applied (0.0 to 1.0)
     * @param exposureCutOff
     */
    public function setExposureCutOff(exposureCutOff:Float):Void 
	{
        this.exposureCutOff = exposureCutOff;
    }

    /**
     * returns the exposure power<br>
     * form more details see {@link #setExposurePower(float exposurePower)}
     * @return 
     */
    public function getExposurePower():Float 
	{
        return exposurePower;
    }

    /**
     * defines how many time the bloom extracted color will be multiplied by itself. default id 5.0<br>
     * a high value will reduce rough edges in the bloom and somhow the range of the bloom area     * 
     * @param exposurePower
     */
    public function setExposurePower(exposurePower:Float):Void 
	{
        this.exposurePower = exposurePower;
    }

    /**
     * returns the downSampling factor<br>
     * form more details see {@link #setDownSamplingFactor(float downSamplingFactor)}
     * @return
     */
    public function getDownSamplingFactor():Float 
	{
        return downSamplingFactor;
    }

    /**
     * Sets the downSampling factor : the size of the computed texture will be divided by this factor. default is 1 for no downsampling
     * A 2 value is a good way of widening the blur
     * @param downSamplingFactor
     */
    public function setDownSamplingFactor(downSamplingFactor:Float):Void 
	{
        this.downSamplingFactor = downSamplingFactor;
		if(renderManager != null)
			initFilter(renderManager, viewPort, initalWidth, initalHeight);
    }	
}


class BloomExtractPass extends Pass
{
	public var extractMat:Material;
	
	private var bloomFilter:BloomFilter;
	
	private var exposureVec:Vector2f;
	public function new(bloomFilter:BloomFilter)
	{
		super();
		this.bloomFilter = bloomFilter;
		
		exposureVec = new Vector2f();
		
		extractMat = new Material();
		extractMat.load(Angle3D.materialFolder + "material/bloomExtract.mat");
		this.passMaterial = extractMat;
	}
	
	override public function requiresSceneAsTexture():Bool
	{
		return true;
	}
	
	override public function beforeRender():Void
	{
		exposureVec.x = this.bloomFilter.exposurePower;
		exposureVec.y = this.bloomFilter.exposureCutOff;
		
		extractMat.setVector2("u_Exposure", exposureVec);
		if (this.bloomFilter.glowMode != GlowMode.Scene)
		{
			extractMat.setTexture("u_GlowMap", this.bloomFilter.preGlowPass.getRenderedTexture());
		}
		extractMat.setBoolean("u_Extract", this.bloomFilter.glowMode != GlowMode.Objects);
	}
}

class HGaussianBlurPass extends Pass
{
	public var hBlurMat:Material;
	
	private var bloomFilter:BloomFilter;
	
	private var hBlurInfo:Vector3f;
	public function new(bloomFilter:BloomFilter)
	{
		super();
		this.bloomFilter = bloomFilter;
		
		hBlurInfo = new Vector3f();
		
		hBlurMat = new Material();
		hBlurMat.load(Angle3D.materialFolder + "material/hGaussianBlur.mat");
		this.passMaterial = hBlurMat;
	}
	
	override public function requiresSceneAsTexture():Bool
	{
		return true;
	}
	
	override public function beforeRender():Void
	{
		hBlurMat.setTexture("u_Texture", this.bloomFilter.extractPass.getRenderedTexture());
		
		hBlurInfo.x = this.bloomFilter.screenWidth;
		hBlurInfo.y = this.bloomFilter.blurScale;
		hBlurInfo.z = this.bloomFilter.blurScale / this.bloomFilter.screenWidth;
		
		hBlurMat.setVector3("u_SizeScale", hBlurInfo);
	}
}

class VGaussianBlurPass extends Pass
{
	public var vBlurMat:Material;
	
	private var bloomFilter:BloomFilter;
	private var vBlurInfo:Vector3f;
	public function new(bloomFilter:BloomFilter)
	{
		super();
		
		this.bloomFilter = bloomFilter;
		
		vBlurInfo = new Vector3f();
		
		vBlurMat = new Material();
		vBlurMat.load(Angle3D.materialFolder + "material/vGaussianBlur.mat");
		this.passMaterial = vBlurMat;
	}
	
	override public function requiresSceneAsTexture():Bool
	{
		return true;
	}
	
	override public function beforeRender():Void
	{
		vBlurMat.setTexture("u_Texture", this.bloomFilter.horizontalBlur.getRenderedTexture());
		
		vBlurInfo.x = this.bloomFilter.screenHeight;
		vBlurInfo.y = this.bloomFilter.blurScale;
		vBlurInfo.z = this.bloomFilter.blurScale / this.bloomFilter.screenHeight;
		
		vBlurMat.setVector3("u_SizeScale", vBlurInfo);
	}
}