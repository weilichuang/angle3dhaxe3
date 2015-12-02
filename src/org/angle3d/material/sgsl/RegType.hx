package org.angle3d.material.sgsl;

class RegType
{
	public static inline var ATTRIBUTE:Int = 0;
	public static inline var UNIFORM:Int = 1;
	public static inline var VARYING:Int = 2;
	public static inline var TEMP:Int = 3;
	public static inline var OUTPUT:Int = 4;
	public static inline var DEPTH:Int = 5;
	
	public static function getRegTypeBy(name:String):Int
	{
		switch(name)
		{
			case "attribute":
				return ATTRIBUTE;
			case "uniform":
				return UNIFORM;
			case "varying":
				return VARYING;
			case "temp":
				return TEMP;
			case "output":
				return OUTPUT;
			case "depth":
				return DEPTH;
		}
		return -1;
	}
	
	public static function getRegNameBy(type:Int):String
	{
		switch(type)
		{
			case ATTRIBUTE:
				return "attribute";
			case UNIFORM:
				return "uniform";
			case VARYING:
				return "varying";
			case TEMP:
				return "temp";
			case OUTPUT:
				return "output";
			case DEPTH:
				return "depth";
		}
		return "";
	}
}

