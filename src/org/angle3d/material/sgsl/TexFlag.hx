package org.angle3d.material.sgsl;

import org.angle3d.utils.StringUtil;

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
		reset();
	}
	
	public inline function reset():Void
	{
		type = 0;
		bias = 0;
		dimension = 0;
		special = 0;
		wrap = 0;
		mipmap = 0;
		filter = 1;
	}
	
	public function copyFrom(other:TexFlag):Void
	{
		this.type = other.type;
		this.bias = other.bias;
		this.dimension = other.dimension;
		this.special = other.special;
		this.wrap = other.wrap;
		this.mipmap = other.mipmap;
		this.filter = other.filter;
	}
	
	public function clone():TexFlag
	{
		var result:TexFlag = new TexFlag();
		result.copyFrom(this);
		return result;
	}

	public function getTexFlagsBits():Int
	{
		if (Angle3D.ignoreSamplerFlag && Angle3D.supportSetSamplerState)
			special = 4;
		else
			special = 0;
			
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
	
	public function parseTextureFormat(format:String):Void
	{
		switch (format.toLowerCase())
		{
			case "bgra","bgraPacked4444","bgrPacked565","rgbaHalfFloat":
				type = 0;
			case "compressed":
				type = 1;
			case "compressedAlpha":
				type = 2;
		}
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
					//case "centroid":
						//special = 0;
					//case "single":
						//special = 2;
					case "ignore":
						special = 4;
				}
			}
		}
		
		if (Angle3D.ignoreSamplerFlag && Angle3D.supportSetSamplerState)
			special = 4;
		else
			special = 0;
			
	}
	
	public function toString():String
	{
		var result:String = "";
		
		if (special == 4)
		{
			result += "ignore,";
		}
		
		switch (type)
		{
			case 0:
				result += "rgba,";
			case 1:
				result += "dxt1,";
			case 2:
				result += "dxt5,";
		} 
		switch (dimension)
		{
			case 0:
				result += "2d,";
			case 1:
				result += "cube,";
			case 2:
				result += "3d,";
		} 
		switch (wrap)
		{
			case 0:
				result += "clamp,";
			case 1:
				result += "wrap,";
			case 2:
				result += "clamp_u_repeat_v,";
			case 3:
				result += "repeat_u_clamp_v,";
		} 
		switch (mipmap)
		{
			case 0:
				result += "nomip,";
			case 1:
				result += "mipnearest,";
			case 2:
				result += "miplinear,";
		} 
		switch (filter)
		{
			case 0:
				result += "nearest";
			case 1:
				result += "linear";
			case 2:
				result += "anisotropic2x";
			case 3:
				result += "anisotropic4x";
			case 4:
				result += "anisotropic8x";
			case 5:
				result += "anisotropic16x";
		} 
		return result;
	}
}

