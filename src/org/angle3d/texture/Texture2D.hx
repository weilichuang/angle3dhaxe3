package org.angle3d.texture;
import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.TextureBase;

/**
 * ...
 * @author weilichuang
 */
class Texture2D extends TextureMapBase
{

	public function new(width:Int, height:Int, mipmap:Bool = false) 
	{
		super(mipmap);
		
		setSize(width, height);
		invalidateContent();
	}
	
	override private function createTexture(context:Context3D):TextureBase
	{
		return context.createTexture(mWidth, mHeight, 
					Context3DTextureFormat.BGRA, optimizeForRenderToTexture);
	}
	
}