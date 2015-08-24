package org.angle3d.texture;
import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.TextureBase;
import org.angle3d.math.FastMath;

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
		if (!FastMath.isPowerOfTwo(mWidth) || !FastMath.isPowerOfTwo(mHeight))
		{
			var createFunc:Dynamic = untyped context["createRectangleTexture"];
			return createFunc(mWidth, mHeight, getFormat(), optimizeForRenderToTexture);
		}
		else
		{
			return context.createTexture(mWidth, mHeight, getFormat(), optimizeForRenderToTexture);
		}
	}
	
}