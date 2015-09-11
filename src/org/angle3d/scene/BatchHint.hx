package org.angle3d.scene;

/**
 * Specifies if this spatial should be batched
 * @author weilichuang
 */

@:final class BatchHint 
{
	/** 
	 * Do whatever our parent does. If no parent, default to {@link #Always}.
	 */
	public static inline var Inherit:Int = 0;
	/** 
	 * This spatial will always be batched when attached to a BatchNode.
	 */
	public static inline var Always:Int = 1;
	/** 
	 * This spatial will never be batched when attached to a BatchNode.
	 */
	public static inline var Never:Int = 2;
}