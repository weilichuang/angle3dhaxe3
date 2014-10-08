package com.bulletphysics.collision.broadphase;

/**
 * OverlappingPairCallback class is an additional optional broadphase user callback
 * for adding/removing overlapping pairs, similar interface to {@link OverlappingPairCache}.
 *
 * @author weilichuang
 */
class OverlappingPairCallback
{

	public function new() 
	{
		
	}
	
	public function addOverlappingPair(proxy0:BroadphaseProxy, proxy1:BroadphaseProxy):BroadphasePair
	{
		return null;
	}

    public function removeOverlappingPair(proxy0:BroadphaseProxy, proxy1:BroadphaseProxy, dispatcher:Dispatcher):Dynamic
	{
		return null;
	}

    public function removeOverlappingPairsContainingProxy(proxy0:BroadphaseProxy, dispatcher:Dispatcher):Void
	{
		
	}
}