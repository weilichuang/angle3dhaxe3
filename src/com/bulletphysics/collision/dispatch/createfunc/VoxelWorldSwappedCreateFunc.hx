package com.bulletphysics.collision.dispatch.createfunc;
import com.bulletphysics.collision.broadphase.CollisionAlgorithm;
import com.bulletphysics.collision.broadphase.CollisionAlgorithmConstructionInfo;
import com.bulletphysics.util.ObjectPool;

/**
 * ...
 * @author weilichuang
 */
class VoxelWorldSwappedCreateFunc extends CollisionAlgorithmCreateFunc 
{
	private var pool:ObjectPool<VoxelWorldCollisionAlgorithm> = ObjectPool.getPool(VoxelWorldCollisionAlgorithm);

	override public function createCollisionAlgorithm(ci:CollisionAlgorithmConstructionInfo, body0:CollisionObject, body1:CollisionObject):CollisionAlgorithm 
	{
		var algo:VoxelWorldCollisionAlgorithm = pool.get();
		algo.init2(ci, body0, body1, true);
		return algo;
	}
	
	override public function releaseCollisionAlgorithm(algo:CollisionAlgorithm):Void 
	{
		pool.release(cast algo);
	}
}