package com.bulletphysics.collision.dispatch.createfunc;
import com.bulletphysics.collision.broadphase.CollisionAlgorithmConstructionInfo;
import com.bulletphysics.collision.broadphase.CollisionAlgorithm;
import com.bulletphysics.util.ObjectPool;

/**
 * ...
 * @author weilichuang
 */
class SphereSphereCreateFunc extends CollisionAlgorithmCreateFunc 
{
	private var pool:ObjectPool<SphereSphereCollisionAlgorithm> = ObjectPool.getPool(SphereSphereCollisionAlgorithm);
	
	override public function createCollisionAlgorithm(ci:CollisionAlgorithmConstructionInfo, body0:CollisionObject, body1:CollisionObject):CollisionAlgorithm 
	{
		var algo:SphereSphereCollisionAlgorithm = pool.get();
		algo.init(null, ci, body0, body1);
		return algo;
	}

	override public function releaseCollisionAlgorithm(algo:CollisionAlgorithm):Void 
	{
		pool.release(cast algo);
	}
}