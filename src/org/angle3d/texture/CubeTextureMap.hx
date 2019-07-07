package org.angle3d.texture;

import flash.display.BitmapData;
import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.CubeTexture;
import flash.display3D.textures.TextureBase;

import org.angle3d.error.Assert;
import flash.Vector;
/**
 * andy
 * 为何CubeTexture必须要生成mipmap,否则报错
 */
class CubeTextureMap extends Texture
{
	private var mBitmapDatas:Vector<BitmapData>;

	/**
	 * 
	 * @param	posX 正 X 轴
	 * @param	negX 负 X 轴
	 * @param	posY 正 Y 轴
	 * @param	negY 负 Y 轴
	 * @param	posZ 正 Z 轴
	 * @param	negZ 负 Z 轴
	 */
	public function new(posX:BitmapData, negX:BitmapData, 
						posY:BitmapData, negY:BitmapData, 
						posZ:BitmapData, negZ:BitmapData)
	{
		super(true);
		
		this.type = TextureType.CubeMap;

		mBitmapDatas = new Vector<BitmapData>(6, true);
		mBitmapDatas[0] = posX;
		mBitmapDatas[1] = negX;
		mBitmapDatas[2] = posY;
		mBitmapDatas[3] = negY;
		mBitmapDatas[4] = posZ;
		mBitmapDatas[5] = negZ;

		#if debug
		for (i in 0...6)
		{
			testSize(mBitmapDatas[i]);
		}
		#end
		

		setSize(posX.width, posX.height);
	}

	#if debug
	private function testSize(value:BitmapData):Void
	{
		Assert.assert(value.width == value.height, 
		"BitmapData should have equal width and height!");
		Assert.assert(TextureUtil.isBitmapDataValid(value), 
		"Invalid bitmapData: Width and height must be power of 2 and cannot exceed 1024");
	}
	#end

	override private function createTexture(context:Context3D):TextureBase
	{
		return context.createCubeTexture(mWidth, Context3DTextureFormat.BGRA, optimizeForRenderToTexture);
	}

	override private function uploadTexture():Void
	{
		var cubeTexture:CubeTexture = Std.downcast(mTexture, CubeTexture);

		for (i in 0...6)
		{
			MipmapGenerator.generateMipMapsCube(mBitmapDatas[i], cubeTexture, i, true);
		}
	}
}

