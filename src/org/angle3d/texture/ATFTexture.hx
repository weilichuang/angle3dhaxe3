package org.angle3d.texture;

import de.polygonal.ds.error.Assert;
import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.Texture;
import flash.display3D.textures.TextureBase;
import flash.utils.ByteArray;
import org.angle3d.Angle3D;

/**
 * adobe atf file
 * @author weilichuang
 */
class ATFTexture extends org.angle3d.texture.Texture
{
	private var mByteArray:ByteArray;

	public function new(data:ByteArray)
	{
		super(false);

		setByteArray(data);
	}

	public function getByteArray():ByteArray
	{
		return mByteArray;
	}

	public function setByteArray(byte:ByteArray):Void
	{
		mByteArray = byte;
		mByteArray.position = 0;

		#if debug
		var signature:String = String.fromCharCode(mByteArray[0], mByteArray[1], mByteArray[2]);
		Assert.assert(signature == "ATF", "Invalid ATF data");
		#end

		switch (mByteArray[6])
		{
			case 0,1:
				mFormat = Context3DTextureFormat.BGRA;
			case 2,3:
				mFormat = Context3DTextureFormat.COMPRESSED;
			case 4,5:
				mFormat = Context3DTextureFormat.COMPRESSED_ALPHA;
			default:
				Assert.assert(false,"Invalid ATF format");
		}

		var log2Width:Int = mByteArray[7];
		var log2Height:Int = mByteArray[8];
		var numTextures:Int = mByteArray[9];

		mMipmap = numTextures > 1;

		invalidateContent();

		setSize(Std.int(Math.pow(2, log2Width)), Std.int(Math.pow(2, log2Height)));
	}

	override private function uploadTexture():Void
	{
		cast(mTexture,Texture).uploadCompressedTextureFromByteArray(mByteArray, 0, false);
	}

	override private function createTexture(context:Context3D):TextureBase
	{
		return context.createTexture(mWidth, mHeight, getFormat(), false);
	}
}

