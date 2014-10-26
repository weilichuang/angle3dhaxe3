package com.bulletphysics.collision.broadphase;

/**
 * Callback for filtering broadphase collisions.
 * @author weilichuang
 */
interface OverlapFilterCallback
{
	/**
     * Checks if given pair of collision objects needs collision.
     *
     * @param proxy0 first object
     * @param proxy1 second object
     * @return true when pairs need collision
     */
    function needBroadphaseCollision(proxy0:BroadphaseProxy, proxy1:BroadphaseProxy):Bool;
}