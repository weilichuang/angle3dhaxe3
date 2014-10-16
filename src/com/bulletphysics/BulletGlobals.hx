package com.bulletphysics;

/**
 * ...
 * @author weilichuang
 */
class BulletGlobals
{
	public static var DEBUG:Bool = false;

    public static var CONVEX_DISTANCE_MARGIN:Float = 0.04;
    public static var FLT_EPSILON:Float = 1.19209290e-07;
    public static var SIMD_EPSILON:Float = FLT_EPSILON;

    public static inline var SIMD_2_PI:Float = 6.283185307179586232;
    public static inline var SIMD_PI:Float = 3.141592653589793116;// SIMD_2_PI * 0.5;
    public static inline var SIMD_HALF_PI:Float = 1.570796326794896558;// SIMD_2_PI * 0.25;
    public static inline var SIMD_RADS_PER_DEG:Float = 0.01745329251994329508888888888889;// SIMD_2_PI / 360;
    public static inline var SIMD_DEGS_PER_RAD:Float = 57.295779513082323110248951135514;// 360 / SIMD_2_PI;
	
    public static var SIMD_INFINITY(get, never):Float;
	
	private static inline function get_SIMD_INFINITY():Float
	{
		//不能使用Math.POSITIVE_INFINITY，否则对其四则运算时结果始终是Math.POSITIVE_INFINITY
		//TODO 选择一个较好的最大值
		return 1.79e308;// Math.POSITIVE_INFINITY;
	}
	
	private static var gContactDestroyedCallback:ContactDestroyedCallback;
    private static var gContactAddedCallback:ContactAddedCallback;
    private static var gContactProcessedCallback:ContactProcessedCallback;
	
	public static function getContactAddedCallback():ContactAddedCallback
	{
        return gContactAddedCallback;
    }

    public static function setContactAddedCallback(callback:ContactAddedCallback)
	{
        gContactAddedCallback = callback;
    }

    public static function getContactDestroyedCallback():ContactDestroyedCallback 
	{
        return gContactDestroyedCallback;
    }

    public static function setContactDestroyedCallback(callback:ContactDestroyedCallback) 
	{
        gContactDestroyedCallback = callback;
    }

    public static function getContactProcessedCallback():ContactProcessedCallback 
	{
        return gContactProcessedCallback;
    }

    public static function setContactProcessedCallback(callback:ContactProcessedCallback):Void
	{
        gContactProcessedCallback = callback;
    }

    public static var contactBreakingThreshold:Float = 0.02;
    // RigidBody
    public static var deactivationTime:Float = 2;
    public static var disableDeactivation:Bool = false;

	public static inline function getDeactivationTime():Float
	{
        return deactivationTime;
    }

    public static function setDeactivationTime(time:Float):Void
	{
        deactivationTime = time;
    }

    public static inline function isDeactivationDisabled():Bool
	{
        return disableDeactivation;
    }

    public static function setDeactivationDisabled(disable:Bool):Void
	{
        disableDeactivation = disable;
    }
}