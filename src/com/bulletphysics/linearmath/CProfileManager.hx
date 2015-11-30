package com.bulletphysics.linearmath;

/**
 * Manager for the profile system.
 * @author weilichuang
 */
class CProfileManager
{

	private static var root:CProfileNode = new CProfileNode("Root", null);
    private static var currentNode:CProfileNode = root;
    private static var frameCounter:Int = 0;
    private static var resetTime:Int = 0;

    /**
     * @param name must be {String#intern interned} String (not needed for String literals)
     */
    public static function startProfile(name:String):Void
	{
        if (name != currentNode.getName())
		{
            currentNode = currentNode.getSubNode(name);
        }

        currentNode.call();
    }

    public static function stopProfile():Void
	{
        // Return will indicate whether we should back up to our parent (we may
        // be profiling a recursive function)
        if (currentNode.Return())
		{
            currentNode = currentNode.getParent();
        }
    }

    public static function cleanupMemory():Void
	{
        root.cleanupMemory();
    }

    public static function reset():Void
	{
        root.reset();
        root.call();
        frameCounter = 0;
        resetTime = BulletStats.profileGetTicks();
    }

    public static function incrementFrameCounter():Void
	{
        frameCounter++;
    }

    public static function getFrameCountSinceReset():Int
	{
        return frameCounter;
    }

    public static function getTimeSinceReset():Float
	{
        var time:Int = BulletStats.profileGetTicks();
        time -= resetTime;
        return time / BulletStats.profileGetTickRate();
    }

    public static function getIterator():CProfileIterator
	{
        return new CProfileIterator(root);
    }

    public static function releaseIterator(iterator:CProfileIterator):Void
	{
        /*delete ( iterator);*/
    }
	
}