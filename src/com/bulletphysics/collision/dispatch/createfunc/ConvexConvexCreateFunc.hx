package com.bulletphysics.collision.dispatch.createfunc;
import com.bulletphysics.collision.broadphase.CollisionAlgorithm;
import com.bulletphysics.collision.broadphase.CollisionAlgorithmConstructionInfo;
import com.bulletphysics.collision.narrowphase.ConvexPenetrationDepthSolver;
import com.bulletphysics.collision.narrowphase.SimplexSolverInterface;
import com.bulletphysics.util.ObjectPool;

/**
 * ...
 * @author weilichuang
 */
class ConvexConvexCreateFunc extends CollisionAlgorithmCreateFunc
{
	private var pool:ObjectPool<ConvexConvexAlgorithm> = ObjectPool.getPool(ConvexConvexAlgorithm);

	public var pdSolver:ConvexPenetrationDepthSolver;
	public var simplexSolver:SimplexSolverInterface;

	public function new(simplexSolver:SimplexSolverInterface, pdSolver:ConvexPenetrationDepthSolver)
	{
		super();
		this.simplexSolver = simplexSolver;
		this.pdSolver = pdSolver;
	}
	
	override public function createCollisionAlgorithm(ci:CollisionAlgorithmConstructionInfo, body0:CollisionObject, body1:CollisionObject):CollisionAlgorithm 
	{
		var algo:ConvexConvexAlgorithm = pool.get();
		algo.init(ci.manifold, ci, body0, body1, simplexSolver, pdSolver);
		return algo;
	}

	override public function releaseCollisionAlgorithm(algo:CollisionAlgorithm):Void 
	{
		pool.release(cast algo);
	}
}