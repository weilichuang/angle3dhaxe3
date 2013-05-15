package org.angle3d.texture;

import flash.display.BitmapData;
import flash.display.StageQuality;
import flash.display3D.textures.CubeTexture;
import flash.display3D.textures.Texture;
import flash.geom.Matrix;
import flash.geom.Rectangle;

//TODO 添加一个MipMapDataPool,用于缓存用来生成mipmap数据的BitmapData
class MipmapGenerator
{
	private static var _matrix:Matrix = new Matrix();
	private static var _rect:Rectangle = new Rectangle();

	public static function generateMipMaps(source:BitmapData, target:Texture, mipmap:BitmapData = null, alpha:Bool = false):Void
	{
		var w:Int = source.width, h:Int = source.height;
		var i:Int = 0;
		var regen:Bool = mipmap != null;

		if (mipmap == null)
			mipmap = new BitmapData(w, h, alpha);

		_matrix.a = 1;
		_matrix.d = 1;

		_rect.width = w;
		_rect.height = h;

		while (w >= 1 && h >= 1)
		{
			if (alpha)
				mipmap.fillRect(_rect, 0x00000000);
			mipmap.draw(source, _matrix, null, null, null, true);
			target.uploadFromBitmapData(mipmap, i++);
			w >>= 1;
			h >>= 1;
			_matrix.a *= .5;
			_matrix.d *= .5;
			_rect.width = w;
			_rect.height = h;
		}

		if (!regen)
			mipmap.dispose();
	}

	/**
	 *
	 * @param	source
	 * @param	target
	 * @param	side 方向
	 * @param	mipmap
	 * @param	alpha
	 */
	public static function generateMipMapsCube(source:BitmapData, target:CubeTexture, 
					side:Int, mipmap:BitmapData = null, alpha:Bool = false):Void
	{
		var w:Int = source.width, h:Int = source.height;
		var i:Int = 0;
		var regen:Bool = mipmap != null;

		if (mipmap == null)
			mipmap = new BitmapData(w, h, alpha);

		_matrix.a = 1;
		_matrix.d = 1;

		_rect.width = w;
		_rect.height = h;

		while (w >= 1 && h >= 1)
		{
			if (alpha)
				mipmap.fillRect(_rect, 0);
			#if flash11_3
			mipmap.drawWithQuality(source, _matrix, null, null, null, true, StageQuality.BEST);
			#else
			mipmap.draw(source, _matrix, null, null, null, true);
			#end

			target.uploadFromBitmapData(mipmap, side, i++);
			
			w >>= 1;
			h >>= 1;
			_matrix.a *= .5;
			_matrix.d *= .5;
			_rect.width = w;
			_rect.height = h;
		}

		if (!regen)
			mipmap.dispose();
	}
}


