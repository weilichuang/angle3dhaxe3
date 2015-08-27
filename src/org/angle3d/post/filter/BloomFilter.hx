package org.angle3d.post.filter;

import org.angle3d.material.Material;
import org.angle3d.post.Filter;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;

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
    public var blurScale:Float = 1.5f;
    public var exposurePower:Float = 5.0f;
    public var exposureCutOff:Float = 0.0f;
    public var bloomIntensity:Float = 2.0f;
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

	public function new(name:String) 
	{
		super("BloomFilter");
	}
	
}

import org.angle3d.post.Pass;
class BloomExtractPass extends Pass
{
	public var extractMat:Material;
	
	private var bloomFilter:BloomFilter;
	public function new(bloomFilter:BloomFilter)
	{
		this.bloomFilter = bloomFilter;
		
		extractMat = new Material();
		extractMat.load(Angle3D.materialFolder + "material/bloomExtract.mat");
	}
	
	override public function requiresSceneAsTexture():Bool
	{
		return true;
	}
	
	override public function beforeRender():Void
	{
		extractMat.setFloat("ExposurePow", this.bloomFilter.exposurePower);
		extractMat.setFloat("ExposureCutoff", this.bloomFilter.exposureCutOff);
		if (glowMode != GlowMode.Scene)
		{
			extractMat.setTexture("GlowMap", this.bloomFilter.preGlowPass.getRenderedTexture());
		}
		extractMat.setBoolean("Extract", this.bloomFilter.glowMode != GlowMode.Objects);
	}
}

class HGaussianBlurPass extends Pass
{
	public var hBlurMat:Material;
	
	private var bloomFilter:BloomFilter;
	public function new(bloomFilter:BloomFilter)
	{
		this.bloomFilter = bloomFilter;
		
		hBlurMat = new Material();
		hBlurMat.load(Angle3D.materialFolder + "material/hGaussianBlur.mat");
	}
	
	override public function requiresSceneAsTexture():Bool
	{
		return true;
	}
	
	override public function beforeRender():Void
	{
		hBlurMat.setTexture("Texture", this.bloomFilter.extractPass.getRenderedTexture());
		hBlurMat.setFloat("Size", this.bloomFilter.screenWidth);
		hBlurMat.setFloat("Scale", this.bloomFilter.blurScale);
	}
}

class VGaussianBlurPass extends Pass
{
	public var vBlurMat:Material;
	
	private var bloomFilter:BloomFilter;
	public function new(bloomFilter:BloomFilter)
	{
		this.bloomFilter = bloomFilter;
		
		vBlurMat = new Material();
		vBlurMat.load(Angle3D.materialFolder + "material/vGaussianBlur.mat");
	}
	
	override public function requiresSceneAsTexture():Bool
	{
		return true;
	}
	
	override public function beforeRender():Void
	{
		vBlurMat.setTexture("Texture", this.bloomFilter.horizontalBlur.getRenderedTexture());
		vBlurMat.setFloat("Size", this.bloomFilter.screenHeight);
		vBlurMat.setFloat("Scale", this.bloomFilter.blurScale);
	}
}