package org.angle3d;
import org.angle3d.material.shader.ShaderProfile;

/**
 * ...
 * @author 
 */
class Angle3D
{
	inline static public var VERSION:String = "0.1.0";
	
	public static var materialFolder:String = "../assets/";
	
	public static var totalTriangle:Int = 0;
	public static var renderTriangle:Int = 0;
	public static var drawCount:Int = 0;
	
	public static var maxAgalVersion:Int = 1;
	
	public static var supportSetSamplerState:Bool = false;
	public static var ignoreSamplerFlag:Bool = false;
	
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
	
	public static function getAgalVersion(profile:ShaderProfile):Int
	{
		var agalVersion:Int;
		switch(cast profile)
		{
			case "standardExtended":
				agalVersion = 3;
			case "standard","standardConstrained":
				agalVersion = 2;
			default:
				agalVersion = 1;
		}
		
		if (agalVersion > maxAgalVersion)
		{
			agalVersion = maxAgalVersion;
		}
		return agalVersion;
	}
	
	
}