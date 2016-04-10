package com.bulletphysics.collision.dispatch;
import com.bulletphysics.collision.broadphase.BroadphasePair;
import com.bulletphysics.collision.broadphase.DispatcherInfo;
import com.bulletphysics.collision.broadphase.OverlapCallback;

/**
 * ...
 
 */
class CollisionPairCallback implements OverlapCallback
{

	private var dispatchInfo:DispatcherInfo;
	private var dispatcher:CollisionDispatcher;
	
	public function new()
	{
	}
	
	public inline function init(dispatchInfo:DispatcherInfo, dispatcher:CollisionDispatcher):Void
	{
		this.dispatchInfo = dispatchInfo;
		this.dispatcher = dispatcher;
	}
	
	public inline function processOverlap(pair:BroadphasePair):Bool
	{
		dispatcher.getNearCallback().handleCollision(pair, dispatcher, dispatchInfo);
		return false;
	}
	
}