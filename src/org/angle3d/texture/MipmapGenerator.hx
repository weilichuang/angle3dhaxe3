package org.angle3d.texture;

import flash.display.BitmapData;
import flash.display.StageQuality;
import flash.display3D.textures.CubeTexture;
import flash.display3D.textures.Texture;
import flash.geom.Matrix;
import flash.geom.Rectangle;

//TODO 添加一个MipMapDataPool,用于缓存用来生成mipmap数据的BitmapData
class MipmapGenerator {
	private static var _matrix:Matrix = new Matrix();
	private static var _rect:Rectangle = new Rectangle();

	public static function generateMipMaps(source:BitmapData, target:Texture, alpha:Bool = false):Void {
		var i:Int = 0;
		target.uploadFromBitmapData(source, i++);

		var w:Int = source.width, h:Int = source.height;
		w >>= 1;
		h >>= 1;
		_matrix.a = .5;
		_matrix.d = .5;

		var prevMipMap:BitmapData = source;

		while (w >= 1 && h >= 1) {
			var mipmap:BitmapData = new BitmapData(w, h, alpha, 0x00000000);
			mipmap.draw(prevMipMap, _matrix, null, null, null, true);
			target.uploadFromBitmapData(mipmap, i++);

			w >>= 1;
			h >>= 1;
			if (prevMipMap != source) {
				prevMipMap.dispose();
			}
			prevMipMap = mipmap;
		}
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
			side:Int, alpha:Bool = false):Void {
		var i:Int = 0;
		target.uploadFromBitmapData(source, side, i++);

		var w:Int = source.width, h:Int = source.height;
		w >>= 1;
		h >>= 1;
		_matrix.a = .5;
		_matrix.d = .5;

		var prevMipMap:BitmapData = source;

		while (w >= 1 && h >= 1) {
			var mipmap:BitmapData = new BitmapData(w, h, alpha, 0x00000000);
			mipmap.draw(prevMipMap, _matrix, null, null, null, true);
			target.uploadFromBitmapData(mipmap, side, i++);

			w >>= 1;
			h >>= 1;
			if (prevMipMap != source) {
				prevMipMap.dispose();
			}
			prevMipMap = mipmap;
		}
	}
}

