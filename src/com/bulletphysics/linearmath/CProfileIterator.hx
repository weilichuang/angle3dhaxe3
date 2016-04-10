package com.bulletphysics.linearmath;

/***************************************************************************************************
 **
 ** Real-Time Hierarchical Profiling for Game Programming Gems 3
 **
 ** by Greg Hjelstrom & Byon Garrabrant
 **
 ***************************************************************************************************/
/**
 * Iterator to navigate through profile tree.
 
 */
class CProfileIterator
{

	private var currentParent:CProfileNode;
    private var currentChild:CProfileNode;

    public function new(start:CProfileNode)
	{
        currentParent = start;
        currentChild = currentParent.getChild();
    }

    // Access all the children of the current parent

    public function first():Void
	{
        currentChild = currentParent.getChild();
    }

    public function next():Void 
	{
        currentChild = currentChild.getSibling();
    }

    public function isDone():Bool
	{
        return (currentChild == null);
    }

    public function isRoot():Bool
	{
        return (currentParent.getParent() == null);
    }

    /**
     * Make the given child the new parent.
     */
    public function enterChild(index:Int):Void 
	{
        currentChild = currentParent.getChild();
        while ((currentChild != null) && (index != 0)) 
		{
            index--;
            currentChild = currentChild.getSibling();
        }

        if (currentChild != null)
		{
            currentParent = currentChild;
            currentChild = currentParent.getChild();
        }
    }

    //public void enterLargestChild(); // Make the largest child the new parent

    /**
     * Make the current parent's parent the new parent.
     */
    public function enterParent():Void
	{
        if (currentParent.getParent() != null)
		{
            currentParent = currentParent.getParent();
        }
        currentChild = currentParent.getChild();
    }

    // Access the current child

    public function getCurrentName():String
	{
        return currentChild.getName();
    }

    public function getCurrentTotalCalls():Int
	{
        return currentChild.getTotalCalls();
    }

    public function getCurrentTotalTime():Float
	{
        return currentChild.getTotalTime();
    }

    // Access the current parent

    public function getCurrentParentName():String
	{
        return currentParent.getName();
    }

    public function getCurrentParentTotalCalls():Int
	{
        return currentParent.getTotalCalls();
    }

    public function getCurrentParentTotalTime():Float
	{
        return currentParent.getTotalTime();
    }
	
}