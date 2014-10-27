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
interface Dispatcher
{
	function findAlgorithm(body0:CollisionObject, body1:CollisionObject, sharedManifold:PersistentManifold = null):CollisionAlgorithm;
	
	function getNewManifold(body0:Dynamic, body1:Dynamic):PersistentManifold;
	
	function releaseManifold(manifold:PersistentManifold):Void;
	
	function clearManifold(manifold:PersistentManifold):Void;
	
	function needsCollision(body0:CollisionObject, body1:CollisionObject):Bool;
	
	function needsResponse(body0:CollisionObject, body1:CollisionObject):Bool;
	
	function dispatchAllCollisionPairs(pairCache:OverlappingPairCache, dispatchInfo:DispatcherInfo, dispatcher:Dispatcher):Void;
	
	function getNumManifolds():Int;
	
	function getManifoldByIndexInternal(index:Int):PersistentManifold;
	
	function getInternalManifoldPointer():ObjectArrayList<PersistentManifold>;
	
	function freeCollisionAlgorithm(algo:CollisionAlgorithm):Void;
}