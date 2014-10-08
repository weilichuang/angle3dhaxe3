package com.bulletphysics.collision.broadphase;
import com.bulletphysics.collision.dispatch.CollisionObject;
import com.bulletphysics.collision.narrowphase.PersistentManifold;
import com.bulletphysics.util.ObjectArrayList;

/**
 * Dispatcher abstract class can be used in combination with broadphase to dispatch
 * calculations for overlapping pairs. For example for pairwise collision detection,
 * calculating contact points stored in {@link PersistentManifold} or user callbacks
 * (game logic).
 *
 * @author weilichuang
 */
class Dispatcher
{

	public function new() 
	{
		
	}
	
	public function findAlgorithm(body0:CollisionObject, body1:CollisionObject, sharedManifold:PersistentManifold = null):CollisionAlgorithm
	{
		return null;
	}
	
	public function getNewManifold(body0:Dynamic, body1:Dynamic):PersistentManifold
	{
		return null;
	}
	
	public function releaseManifold(manifold:PersistentManifold):Void
	{
		
	}
	
	public function clearManifold(manifold:PersistentManifold):Void
	{
		
	}
	
	public function needsCollision(body0:CollisionObject, body1:CollisionObject):Bool
	{
		return false;
	}
	
	public function needsResponse(body0:CollisionObject, body1:CollisionObject):Bool
	{
		return false;
	}
	
	public function dispatchAllCollisionPairs(pairCache:OverlappingPairCache, dispatchInfo:DispatcherInfo, dispatcher:Dispatcher):Void
	{
		
	}
	
	public function getNumManifolds():Int
	{
		return 0;
	}
	
	public function getManifoldByIndexInternal(index:Int):PersistentManifold
	{
		return null;
	}
	
	public function getInternalManifoldPointer():ObjectArrayList<PersistentManifold>
	{
		return null;
	}
	
	public function freeCollisionAlgorithm(algo:CollisionAlgorithm):Void
	{
		
	}
}