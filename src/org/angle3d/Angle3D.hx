package org.angle3d;
import flash.display3D.Context3D;
import org.angle3d.material.shader.ShaderProfile;

class Angle3D
{
	inline static public var VERSION:String = "0.1.0";
	
	public static var materialFolder:String = "../assets/";
	
	public static var maxAgalVersion:Int = 1;
	
	public static var ignoreSamplerFlag:Bool = false;
	
	private static var _supportSetSamplerState:Bool = false;
	public static var supportSetSamplerState(get, never):Bool;
	private static inline function get_supportSetSamplerState():Bool
	{
		return _supportSetSamplerState;
	}
	
	public static var setSamplerStateAt:Int->String->String->String->Void;
	
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
	
	public static function checkSupportSamplerState(context3D:Context3D):Void
	{
		_supportSetSamplerState = Reflect.hasField(context3D, "setSamplerStateAt");
		if (_supportSetSamplerState)
			setSamplerStateAt = untyped context3D["setSamplerStateAt"];
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