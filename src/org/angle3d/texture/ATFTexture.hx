package org.angle3d.texture;

#if !flash
#error "ATFTexture Only support flash"
#end

import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.Texture;
import flash.display3D.textures.TextureBase;
import flash.utils.ByteArray;
import de.polygonal.ds.error.Assert;

/**
 * adobe atf file
 * @author weilichuang
 */
class ATFTexture extends TextureMapBase
{
	public var context3DTextureFormat(get, set):Context3DTextureFormat;
	
	private var mByteArray:ByteArray;

	private var mContext3DTextureFormat:Context3DTextureFormat;

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
		//var signature:String = String.fromCharCode(mByteArray[0], mByteArray[1], mByteArray[2]);
		//Assert.assert(signature == "ATF", "Invalid ATF data");
		#end

		switch (mByteArray[6])
		{
			case 0,1:
				mContext3DTextureFormat = Context3DTextureFormat.BGRA;
			case 2,3:
				mContext3DTextureFormat = Context3DTextureFormat.COMPRESSED;
			case 4,5:
				mContext3DTextureFormat = Context3DTextureFormat.COMPRESSED_ALPHA;
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

	
	private function get_context3DTextureFormat():Context3DTextureFormat
	{
		return mContext3DTextureFormat;
	}

	private function set_context3DTextureFormat(value:Context3DTextureFormat):Context3DTextureFormat
	{
		mContext3DTextureFormat = value;
		switch (mContext3DTextureFormat)
		{
			case Context3DTextureFormat.BGRA:
				setFormat(TextureFormat.RGBA);
			case Context3DTextureFormat.COMPRESSED:
				setFormat(TextureFormat.DXT1);
			case Context3DTextureFormat.COMPRESSED_ALPHA:
				setFormat(TextureFormat.DXT5);
		}
		
		return mContext3DTextureFormat;
	}

	override private function uploadTexture():Void
	{
		var t:Texture = Std.instance(mTexture, Texture);

		t.uploadCompressedTextureFromByteArray(mByteArray, 0, false);
	}

	override private function createTexture(context:Context3D):TextureBase
	{
		return context.createTexture(mWidth, mHeight, mContext3DTextureFormat, false);
	}
}

