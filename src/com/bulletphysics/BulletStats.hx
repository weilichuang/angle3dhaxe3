package com.bulletphysics;
import com.bulletphysics.linearmath.Clock;
import com.bulletphysics.linearmath.CProfileManager;
import vecmath.Vector3f;

/**
 * Bullet statistics and profile support.
 * @author weilichuang
 */
class BulletStats
{
	public static var gTotalContactPoints:Int;

    // GjkPairDetector
    // temp globals, to improve GJK/EPA/penetration calculations
    public static var gNumDeepPenetrationChecks:Int = 0;
    public static var gNumGjkChecks:Int = 0;
    public static var gNumSplitImpulseRecoveries:Int = 0;

    public static var gNumAlignedAllocs:Int;
    public static var gNumAlignedFree:Int;
    public static var gTotalBytesAlignedAllocs:Int;

    public static var gPickingConstraintId:Int = 0;
    public static var gOldPickingPos:Vector3f = new Vector3f();
    public static var gOldPickingDist:Float = 0.;

    public static var gOverlappingPairs:Int = 0;
    public static var gRemovePairs:Int = 0;
    public static var gAddedPairs:Int = 0;
    public static var gFindPairs:Int = 0;

    public static var gProfileClock:Clock = new Clock();

    // DiscreteDynamicsWorld:
    public static var gNumClampedCcdMotions:Int = 0;

    // JAVA NOTE: added for statistics in applet demo
    public static var stepSimulationTime:Int;
    public static var updateTime:Int;

    private static var enableProfile:Bool = false;

    ////////////////////////////////////////////////////////////////////////////

    public static inline function isProfileEnabled():Bool 
	{
        return enableProfile;
    }

    public static inline function setProfileEnabled(b:Bool):Void
	{
        enableProfile = b;
    }

    public static inline function profileGetTicks():Int 
	{
        var ticks:Int = gProfileClock.getTimeMilliseconds();
        return ticks;
    }

    public static inline function profileGetTickRate():Float
	{
        //return 1000000f;
        return 1000;
    }

    /**
     * Pushes profile node. Use try/finally block to call {@link #popProfile} method.
     *
     * @param name must be {@link String#intern interned} String (not needed for String literals)
     */
    public static inline function pushProfile(name:String):Void 
	{
        if (enableProfile)
		{
            CProfileManager.startProfile(name);
        }
    }

    /**
     * Pops profile node.
     */
    public static inline function popProfile():Void
	{
        if (enableProfile)
		{
            CProfileManager.stopProfile();
        }
    }

	public function new() 
	{
		
	}
	
}