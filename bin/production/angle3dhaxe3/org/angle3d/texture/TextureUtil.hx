package org.angle3d.texture;


import flash.display.BitmapData;

class TextureUtil
{
	private static var MAX_SIZE:Int = 2048;

	public static function isBitmapDataValid(bitmapData:BitmapData):Bool
	{
		if (bitmapData == null)
			return true;

		return isDimensionValid(bitmapData.width) && isDimensionValid(bitmapData.height);
	}

	public static function isDimensionValid(d:Int):Bool
	{
		return d >= 2 && d <= MAX_SIZE && isPowerOfTwo(d);
	}

	public static function isPowerOfTwo(value:Int):Bool
	{
		return value != 0 ? ((value & -value) == value) : false;
	}

	public static function getBestPowerOf2(value:Int):Int
	{
		var p:Int = 1;

		while (p < value)
			p <<= 1;

		if (p > MAX_SIZE)
			p = MAX_SIZE;

		return p;
	}
}


