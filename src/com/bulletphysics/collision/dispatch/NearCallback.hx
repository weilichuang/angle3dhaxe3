package com.bulletphysics.collision.dispatch;
import com.bulletphysics.collision.broadphase.BroadphasePair;
import com.bulletphysics.collision.broadphase.DispatcherInfo;

/**
 * Callback for overriding collision filtering and more fine-grained control over
 * collision detection.
 * @author weilichuang
 */
interface NearCallback
{
	function handleCollision(collisionPair:BroadphasePair, dispatcher:CollisionDispatcher, dispatchInfo:DispatcherInfo):Void;
}