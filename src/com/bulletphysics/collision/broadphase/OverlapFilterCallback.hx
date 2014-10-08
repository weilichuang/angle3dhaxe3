package com.bulletphysics.collision.broadphase;

/**
 * Callback for filtering broadphase collisions.
 * @author weilichuang
 */
class OverlapFilterCallback
{

	public function new() 
	{
		
	}
	
	/**
     * Checks if given pair of collision objects needs collision.
     *
     * @param proxy0 first object
     * @param proxy1 second object
     * @return true when pairs need collision
     */
    public function needBroadphaseCollision(proxy0:BroadphaseProxy, proxy1:BroadphaseProxy):Bool
	{
		return false;
	}
}