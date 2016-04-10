package org.angle3d.scene;

/**
 * Specifies if this spatial should be batched
 
 */
@:enum abstract BatchHint(Int)  
{
	/** 
	 * Do whatever our parent does. If no parent, default to {#Always}.
	 */
	var Inherit = 0;
	/** 
	 * This spatial will always be batched when attached to a BatchNode.
	 */
	var Always = 1;
	/** 
	 * This spatial will never be batched when attached to a BatchNode.
	 */
	var Never = 2;
	
	inline function new(v:Int)
        this = v;

    public inline function toInt():Int
    	return this;
}