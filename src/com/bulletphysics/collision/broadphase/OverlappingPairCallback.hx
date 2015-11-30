package com.bulletphysics.collision.broadphase;

/**
 * OverlappingPairCallback class is an additional optional broadphase user callback
 * for adding/removing overlapping pairs, similar interface to {OverlappingPairCache}.
 *
 * @author weilichuang
 */
interface OverlappingPairCallback
{
	function addOverlappingPair(proxy0:BroadphaseProxy, proxy1:BroadphaseProxy):BroadphasePair;

    function removeOverlappingPair(proxy0:BroadphaseProxy, proxy1:BroadphaseProxy, dispatcher:Dispatcher):Dynamic;

    function removeOverlappingPairsContainingProxy(proxy0:BroadphaseProxy, dispatcher:Dispatcher):Void;
}