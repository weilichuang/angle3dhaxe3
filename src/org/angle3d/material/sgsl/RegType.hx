package org.angle3d.material.sgsl;

@:enum abstract RegType(Int)  
{
	var NONE = -1;
	var ATTRIBUTE = 0;
	var UNIFORM = 1;
	var VARYING = 2;
	var TEMP = 3;
	var OUTPUT = 4;
	var DEPTH = 5;
	
	inline function new(v:Int)
        this = v;

    inline public function toInt():Int
    	return this; 
	
	public static function getRegTypeBy(name:String):RegType
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
			default:
				return NONE;
		}
	}
	
	public static function getRegNameBy(type:RegType):String
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
			default:
				return "";
		}
	}
}

