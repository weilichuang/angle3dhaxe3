package org.angle3d;

/**
 * ...
 * @author 
 */
class Angle3D
{
	inline static public var VERSION:String = "0.1.0";
	
	public static var materialFolder:String = "../assets/";
	
	public static var maxAgalVersion:Int = 1;
	
	public static var flashVersion(get, never):Float;
	
	private static var _flashVersion:Float = 0;
	private static function get_flashVersion():Float
	{
		if (_flashVersion == 0)
		{
			var v:Array<String> = flash.system.Capabilities.version.split(" ")[1].split(",");
			_flashVersion = Std.parseFloat(v[0] + "." + v[1]);
		}
		return _flashVersion;
	}
	
	
}