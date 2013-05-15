package org.angle3d.texture;

import flash.display.BitmapData;
import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.Texture;
import flash.display3D.textures.TextureBase;

import org.angle3d.utils.Assert;

/**
 * andy
 * @author andy
 */
class Texture2D extends TextureMapBase
{
	private var mBitmapData:BitmapData;

	public function new(bitmapData:BitmapData, mipmap:Bool = false)
	{
		super(mipmap);

		setBitmapData(bitmapData);
	}

	public function getBitmapData():BitmapData
	{
		return mBitmapData;
	}

	public function setBitmapData(value:BitmapData):Void
	{
		if (value == mBitmapData)
			return;

		Assert.assert(TextureUtil.isBitmapDataValid(value), 
			"Invalid bitmapData: Width and height must be power of 2 and cannot exceed 2048");

		invalidateContent();

		setSize(value.width, value.height);

		mBitmapData = value;
	}

	override private function createTexture(context:Context3D):TextureBase
	{
		return context.createTexture(mWidth, mHeight, 
					Context3DTextureFormat.BGRA, optimizeForRenderToTexture);
	}

	override private function uploadTexture():Void
	{
		var t:Texture = cast(mTexture, Texture);
		if (mMipmap)
		{
			MipmapGenerator.generateMipMaps(mBitmapData, t, null, true);
		}
		else
		{
			t.uploadFromBitmapData(mBitmapData);
		}
	}
}


