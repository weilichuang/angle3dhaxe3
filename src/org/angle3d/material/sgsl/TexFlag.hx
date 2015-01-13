package org.angle3d.material.sgsl;

import org.angle3d.utils.StringUtil;

/**
 * andy
 * @author weilichuang
 */

class TexFlag
{
	public var type:Int;

	public var bias:Int;

	public var dimension:Int;

	public var mipmap:Int;

	public var filter:Int;

	public var wrap:Int;

	public var special:Int;

	public function new()
	{
		type = 0;
		bias = 0;
		dimension = 0;
		special = 4;
		wrap = 0;
		mipmap = 0;
		filter = 1;
	}

	public function getTexFlagsBits():Int
	{
		return type | (dimension << 4) | (special << 8) | (wrap << 12) | (mipmap << 16) | (filter << 20);
	}

	public function getLod():Int
	{
		var v:Int = Std.int(bias * 8);
		if (v < -128)
		{
			v = -128;
		}
		else if (v > 127)
		{
			v = 127;
		}

		if (v < 0)
			v = 0x100 + v;

		return v;
	}

	public function parseFlags(list:Array<String>):Void
	{
		var length:Int = list.length;
		for (i in 0...length)
		{
			var str:String = list[i];

			if (StringUtil.isDigit(str))
			{
				bias = Std.parseInt(str);
			}
			else
			{
				switch (str.toLowerCase())
				{
					case "rgba":
						type = 0;
					case "dxt1":
						type = 1;
					case "dxt5":
						type = 2;
					case "2d":
						dimension = 0;
					case "cube":
						dimension = 1;
					case "3d":
						dimension = 2;
					case "clamp":
						wrap = 0;
					case "wrap","repeat":
						wrap = 1;
					case "clamp_u_repeat_v":
						wrap = 2;
					case "repeat_u_clamp_v":
						wrap = 3;
					case "nomip","mipnone":
						mipmap = 0;
					case "mipnearest":
						mipmap = 1;
					case "miplinear":
						mipmap = 2;
					case "nearest":
						filter = 0;
					case "linear":
						filter = 1;
					case "anisotropic2x":
						filter = 2;
					case "anisotropic4x":
						filter = 3;
					case "anisotropic8x":
						filter = 4;
					case "anisotropic16x":
						filter = 5;
					case "centroid":
						special = 0;
					case "single":
						special = 2;
					case "ignore":
						special = 4;
				}
			}
		}
	}
}

