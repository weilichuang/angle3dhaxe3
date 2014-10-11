package org.angle3d.bullet;

/**
 * Implement this interface to be called from the physics thread on a physics update.
 * @author weilichuang
 */

interface PhysicsTickListener 
{
	/**
     * Called before the physics is actually stepped, use to apply forces etc.
     * @param space the physics space
     * @param tpf the time per frame in seconds 
     */
    function prePhysicsTick(space:PhysicsSpace, tpf:Float):Void;

    /**
     * Called after the physics has been stepped, use to check for forces etc.
     * @param space the physics space
     * @param tpf the time per frame in seconds
     */
    function physicsTick(space:PhysicsSpace, tpf:Float):Void;
}