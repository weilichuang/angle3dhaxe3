package com.bulletphysics.collision.dispatch.createfunc;
import com.bulletphysics.collision.broadphase.CollisionAlgorithmConstructionInfo;
import com.bulletphysics.collision.broadphase.CollisionAlgorithm;
import com.bulletphysics.util.ObjectPool;

/**
 * ...
 
 */
class CovexConcaveSwappedCreateFunc extends CollisionAlgorithmCreateFunc
{
	private var pool:ObjectPool<ConvexConcaveCollisionAlgorithm> = ObjectPool.getPool(ConvexConcaveCollisionAlgorithm);
	
	override public function createCollisionAlgorithm(ci:CollisionAlgorithmConstructionInfo, body0:CollisionObject, body1:CollisionObject):CollisionAlgorithm 
	{
		var algo:ConvexConcaveCollisionAlgorithm = pool.get();
		algo.init(ci, body0, body1, true);
		return algo;
	}

	override public function releaseCollisionAlgorithm(algo:CollisionAlgorithm):Void 
	{
		pool.release(cast algo);
	}
}