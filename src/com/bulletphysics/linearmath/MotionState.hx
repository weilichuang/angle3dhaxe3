package com.bulletphysics.linearmath;

/**
 * MotionState allows the dynamics world to synchronize the updated world transforms
 * with graphics. For optimizations, potentially only moving objects get synchronized
 * (using {@link #setWorldTransform setWorldTransform} method).
 * @author weilichuang
 */
class MotionState
{

	public function new() 
	{
		
	}
	
	/**
     * Returns world transform.
     */
	public function getWorldTransform(out:Transform):Transform
	{
		return out;
	}
	
	/**
     * Sets world transform. This method is called by JBullet whenever an active
     * object represented by this MotionState is moved or rotated.
     */
	public function setWorldTransform(worldTrans:Transform):Void
	{
		
	}
	
}