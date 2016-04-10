package com.bulletphysics.collision.dispatch;
import com.bulletphysics.collision.broadphase.CollisionAlgorithm;
import com.bulletphysics.collision.broadphase.CollisionAlgorithmConstructionInfo;

/**
 * Used by the CollisionDispatcher to register and create instances for CollisionAlgorithm.
 
 */
class CollisionAlgorithmCreateFunc
{
	public var swapped:Bool;

	public function new() 
	{
		
	}
	
	public function createCollisionAlgorithm(ci:CollisionAlgorithmConstructionInfo, body0:CollisionObject, body1:CollisionObject):CollisionAlgorithm
	{
		return null;
	}
	
	public function releaseCollisionAlgorithm(algo:CollisionAlgorithm):Void
	{
		
	}
}