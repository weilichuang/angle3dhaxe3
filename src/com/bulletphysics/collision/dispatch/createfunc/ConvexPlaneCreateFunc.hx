package com.bulletphysics.collision.dispatch.createfunc;
import com.bulletphysics.collision.broadphase.CollisionAlgorithm;
import com.bulletphysics.collision.broadphase.CollisionAlgorithmConstructionInfo;
import com.bulletphysics.util.ObjectPool;

/**
 * ...
 
 */
class ConvexPlaneCreateFunc extends CollisionAlgorithmCreateFunc 
{
	private var pool:ObjectPool<ConvexPlaneCollisionAlgorithm> = ObjectPool.getPool(ConvexPlaneCollisionAlgorithm);
	
	override public function createCollisionAlgorithm(ci:CollisionAlgorithmConstructionInfo, body0:CollisionObject, body1:CollisionObject):CollisionAlgorithm 
	{
		var algo:ConvexPlaneCollisionAlgorithm = pool.get();
		if (!swapped) 
		{
			algo.init(null, ci, body0, body1, false);
		} 
		else
		{
			algo.init(null, ci, body0, body1, true);
		}
		return algo;
	}

	override public function releaseCollisionAlgorithm(algo:CollisionAlgorithm):Void 
	{
		pool.release(cast algo);
	}
}