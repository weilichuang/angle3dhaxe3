package com.bulletphysics.linearmath;

/**
 * A node in the Profile Hierarchy Tree.
 * @author weilichuang
 */
class CProfileNode
{

	private var name:String;
    private var totalCalls:Int;
    private var totalTime:Float;
    private var startTime:Int;
    private var recursionCounter:Int;

    private var parent:CProfileNode;
    private var child:CProfileNode;
    private var sibling:CProfileNode;

    public function new(name:String, parent:CProfileNode) 
	{
        this.name = name;
        this.totalCalls = 0;
        this.totalTime = 0;
        this.startTime = 0;
        this.recursionCounter = 0;
        this.parent = parent;
        this.child = null;
        this.sibling = null;

        reset();
    }

    public function getSubNode(name:String):CProfileNode 
	{
        // Try to find this sub node
        var child:CProfileNode = this.child;
        while (child != null)
		{
            if (child.name == name)
			{
                return child;
            }
            child = child.sibling;
        }

        // We didn't find it, so add it

        var node:CProfileNode = new CProfileNode(name, this);
        node.sibling = this.child;
        this.child = node;
        return node;
    }

    public function getParent():CProfileNode
	{
        return parent;
    }

    public function getSibling():CProfileNode
	{
        return sibling;
    }

    public function getChild():CProfileNode
	{
        return child;
    }

    public function cleanupMemory():Void 
	{
        child = null;
        sibling = null;
    }

    public function reset():Void
	{
        totalCalls = 0;
        totalTime = 0.0;
        BulletStats.gProfileClock.reset();

        if (child != null)
		{
            child.reset();
        }
        if (sibling != null) 
		{
            sibling.reset();
        }
    }

    public function call():Void
	{
        totalCalls++;
        if (recursionCounter++ == 0) 
		{
            startTime = BulletStats.profileGetTicks();
        }
    }

    public function Return():Bool 
	{
        if (--recursionCounter == 0 && totalCalls != 0)
		{
            var time:Int = BulletStats.profileGetTicks();
            time -= startTime;
            totalTime += time / BulletStats.profileGetTickRate();
        }
        return (recursionCounter == 0);
    }

    public function getName():String 
	{
        return name;
    }

    public function getTotalCalls():Int
	{
        return totalCalls;
    }

    public function getTotalTime():Float 
	{
        return totalTime;
    }
	
}