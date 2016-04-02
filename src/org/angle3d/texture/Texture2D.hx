package org.angle3d.texture;
import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.TextureBase;
import org.angle3d.math.FastMath;

/**
 * ...
 * @author weilichuang
 */
class Texture2D extends Texture
{

	public function new(width:Int, height:Int, mipmap:Bool = false) 
	{
		super(mipmap);
		
		setSize(width, height);
		invalidateContent();
	}
	
	override private function createTexture(context:Context3D):TextureBase
	{
		var isWidthPOT:Bool = FastMath.isPowerOfTwo(mWidth);
		var isHeightPOT:Bool = FastMath.isPowerOfTwo(mHeight);
		if (!isWidthPOT || !isHeightPOT)
		{
			if(Reflect.hasField(context,"createRectangleTexture"))
				return untyped context["createRectangleTexture"](mWidth, mHeight, getFormat(), optimizeForRenderToTexture);
			else
				throw "this flash version dont support RectangleTexture";
		}
		else
		{
			return context.createTexture(mWidth, mHeight, getFormat(), optimizeForRenderToTexture);
		}
	}
	
}