package com.bulletphysics.collision.broadphase;
import com.bulletphysics.util.ObjectArrayList;

/**
 * OverlappingPairCache provides an interface for overlapping pair management (add,
 * remove, storage), used by the {@link BroadphaseInterface} broadphases.
 *
 * @author weilichuang
 */
interface OverlappingPairCache extends OverlappingPairCallback
{
	
	function getOverlappingPairArray():ObjectArrayList<BroadphasePair>;

    function cleanOverlappingPair(pair:BroadphasePair, dispatcher:Dispatcher):Void;

    function getNumOverlappingPairs():Int;

    function cleanProxyFromPairs(proxy:BroadphaseProxy, dispatcher:Dispatcher):Void;

    function setOverlapFilterCallback(overlapFilterCallback:OverlapFilterCallback):Void;

    function processAllOverlappingPairs(callback:OverlapCallback, dispatcher:Dispatcher):Void;

    function findPair(proxy0:BroadphaseProxy, proxy1:BroadphaseProxy):BroadphasePair;

    function hasDeferredRemoval():Bool;

    function setInternalGhostPairCallback(ghostPairCallback:OverlappingPairCallback):Void;
}