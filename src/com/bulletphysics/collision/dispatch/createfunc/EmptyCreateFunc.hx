package com.bulletphysics.collision.dispatch.createfunc;
import com.bulletphysics.collision.broadphase.CollisionAlgorithm;
import com.bulletphysics.collision.broadphase.CollisionAlgorithmConstructionInfo;

/**
 * ...
 
 */
class EmptyCreateFunc extends CollisionAlgorithmCreateFunc
{
	override public function createCollisionAlgorithm(ci:CollisionAlgorithmConstructionInfo, body0:CollisionObject, body1:CollisionObject):CollisionAlgorithm 
	{
		return EmptyAlgorithm.INSTANCE;
	}
	
	override public function releaseCollisionAlgorithm(algo:CollisionAlgorithm):Void 
	{
		
	}
}