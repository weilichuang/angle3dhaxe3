package org.angle3d.material.post;

import flash.display.Bitmap;
import flash.display.BitmapData;

import org.angle3d.material.Material;
import org.angle3d.renderer.IRenderer;
import org.angle3d.texture.FrameBuffer;
import org.angle3d.texture.Texture2D;
import org.angle3d.texture.TextureMapBase;

/**
 * Filters are 2D effects applied to the rendered scene.<br>
 * The filter is fed with the rendered scene image rendered in an offscreen frame buffer.<br>
 * This texture is applied on a fullscreen quad, with a special material.<br>
 * This material uses a shader that aplly the desired effect to the scene texture.<br>
 * <br>
 * This class is abstract, any Filter must extend it.<br>
 * Any filter holds a frameBuffer and a texture<br>
 * The getMaterial must return a Material that use a GLSL shader immplementing the desired effect<br>
 *
 */
class Pass
{
	private var renderFrameBuffer:FrameBuffer;
	private var renderedTexture:Texture2D;
	private var depthTexture:Texture2D;
	private var passMaterial:Material;

	public function new()
	{

	}

	public function init(render:IRenderer, width:Int, height:Int, numSamples:Int, renderDepth:Bool):Void
	{
		var textureMap:Texture2D = new Texture2D(new BitmapData(width, height, true, 0x0));
		renderFrameBuffer = new FrameBuffer(textureMap);
	}

	public function getPassMaterial():Material
	{
		return passMaterial;
	}

	public function setPassMaterial(passMaterial:Material):Void
	{
		this.passMaterial = passMaterial;
	}

	public function getDepthTexture():Texture2D
	{
		return depthTexture;
	}

	public function getRenderedTexture():Texture2D
	{
		return renderedTexture;
	}

	public function setRenderedTexture(renderedTexture:Texture2D):Void
	{
		this.renderedTexture = renderedTexture;
	}

	public function cleanup(r:IRenderer):Void
	{

	}
}

