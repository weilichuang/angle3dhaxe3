package com.bulletphysics.linearmath;

/**
 * Debug draw modes, used by demo framework.
 * @author weilichuang
 */
class DebugDrawModes
{
	public static inline var NO_DEBUG:Int = 0;
    public static inline var DRAW_WIREFRAME:Int = 1;
    public static inline var DRAW_AABB:Int = 2;
    public static inline var DRAW_FEATURES_TEXT:Int = 4;
    public static inline var DRAW_CONTACT_POINTS:Int = 8;
    public static inline var NO_DEACTIVATION:Int = 16;
    public static inline var NO_HELP_TEXT:Int = 32;
    public static inline var DRAW_TEXT:Int = 64;
    public static inline var PROFILE_TIMINGS:Int = 128;
    public static inline var ENABLE_SAT_COMPARISON:Int = 256;
    public static inline var DISABLE_BULLET_LCP:Int = 512;
    public static inline var ENABLE_CCD:Int = 1024;
    public static inline var MAX_DEBUG_DRAW_MODE:Int = 1025;
}