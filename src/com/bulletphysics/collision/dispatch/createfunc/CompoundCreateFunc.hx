package com.bulletphysics.collision.dispatch.createfunc;
import com.bulletphysics.collision.broadphase.CollisionAlgorithm;
import com.bulletphysics.collision.broadphase.CollisionAlgorithmConstructionInfo;
import com.bulletphysics.util.ObjectPool;

/**
 * ...
 * @author weilichuang
 */
class CompoundCreateFunc extends CollisionAlgorithmCreateFunc 
{
	private var pool:ObjectPool<CompoundCollisionAlgorithm> = ObjectPool.getPool(CompoundCollisionAlgorithm);
	
	override public function createCollisionAlgorithm(ci:CollisionAlgorithmConstructionInfo, body0:CollisionObject, body1:CollisionObject):CollisionAlgorithm 
	{
		var algo:CompoundCollisionAlgorithm = pool.get();
		algo.init(ci, body0, body1, false);
		return algo;
	}

	override public function releaseCollisionAlgorithm(algo:CollisionAlgorithm):Void 
	{
		pool.release(cast algo);
	}
}
