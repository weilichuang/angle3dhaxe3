package org.angle3d.scene;

/**
 * Specifies if this spatial should be batched
 * @author weilichuang
 */

enum BatchHint 
{
	/** 
	 * Do whatever our parent does. If no parent, default to {@link #Always}.
	 */
	Inherit;
	/** 
	 * This spatial will always be batched when attached to a BatchNode.
	 */
	Always;
	/** 
	 * This spatial will never be batched when attached to a BatchNode.
	 */
	Never;
}