package org.angle3d.renderer;
import org.angle3d.texture.MipFilter;
import org.angle3d.texture.TextureFilter;
import org.angle3d.texture.WrapMode;

/**
 * ...
 * @author weilichuang
 */
class TextureState
{
	public var mipFilter:MipFilter;
	public var textureFilter:TextureFilter;
	public var wrapMode:WrapMode;

	public inline function new() 
	{
		mipFilter = MipFilter.MIPNONE;
		textureFilter = TextureFilter.NEAREST;
		wrapMode = WrapMode.CLAMP;
	}
	
	public function reset():Void
	{
		mipFilter = MipFilter.MIPNONE;
		textureFilter = TextureFilter.NEAREST;
		wrapMode = WrapMode.CLAMP;
	}
}