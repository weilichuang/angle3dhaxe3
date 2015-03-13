package org.angle3d.texture;

import flash.display.BitmapData;
import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.Texture;
import flash.display3D.textures.TextureBase;

import de.polygonal.ds.error.Assert;

class BitmapTexture extends Texture2D
{
	private var mBitmapData:BitmapData;

	public function new(bitmapData:BitmapData, mipmap:Bool = false)
	{
		super(bitmapData.width, bitmapData.height, mipmap);

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

		#if debug
		Assert.assert(TextureUtil.isBitmapDataValid(value), 
			"Invalid bitmapData: Width and height must be power of 2 and cannot exceed 2048");
		#end

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
		var t:Texture = Std.instance(mTexture, Texture);
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


