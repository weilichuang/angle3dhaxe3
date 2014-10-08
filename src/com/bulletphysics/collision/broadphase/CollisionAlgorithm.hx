package com.bulletphysics.collision.broadphase;
import com.bulletphysics.collision.dispatch.CollisionAlgorithmCreateFunc;
import com.bulletphysics.collision.dispatch.CollisionObject;
import com.bulletphysics.collision.dispatch.ManifoldResult;
import com.bulletphysics.collision.narrowphase.PersistentManifold;
import com.bulletphysics.util.ObjectArrayList;

/**
 * Collision algorithm for handling narrowphase or midphase collision detection
 * between two collision object types.
 * @author weilichuang
 */
class CollisionAlgorithm
{
	private var createFunc:CollisionAlgorithmCreateFunc;
	
	private var dispatcher:Dispatcher;

	public function new() 
	{
		
	}
	
	public function setConstructionInfo(ci:CollisionAlgorithmConstructionInfo):Void
	{
		dispatcher = ci.dispatcher1;
	}
	
	public function destroy():Void
	{
		
	}
	
	public function processCollision(body0:CollisionObject, body1:CollisionObject, dispatchInfo:DispatcherInfo, resultOut:ManifoldResult):Void
	{
		
	}
	
	public function calculateTimeOfImpact(body0:CollisionObject, body1:CollisionObject, dispatchInfo:DispatcherInfo,
	resultOut:ManifoldResult):Float
	{
		return 0;
	}
	
	public function getAllContactManifolds(manifoldArray:ObjectArrayList<PersistentManifold>):Void
	{
		
	}
	
	public function internalSetCreateFunc(func:CollisionAlgorithmCreateFunc):Void
	{
		createFunc = func;
	}
	
	public function internalGetCreateFunc():CollisionAlgorithmCreateFunc
	{
		return createFunc;
	}
	
	
}