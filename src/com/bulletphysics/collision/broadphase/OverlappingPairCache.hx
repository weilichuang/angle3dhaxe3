package com.bulletphysics.collision.broadphase;
import com.bulletphysics.util.ObjectArrayList;

/**
 * OverlappingPairCache provides an interface for overlapping pair management (add,
 * remove, storage), used by the {@link BroadphaseInterface} broadphases.
 *
 * @author weilichuang
 */
class OverlappingPairCache extends OverlappingPairCallback
{

	public function new() 
	{
		super();
	}
	
	public function getOverlappingPairArray():ObjectArrayList<BroadphasePair>
	{
		return null;
	}

    public function cleanOverlappingPair(pair:BroadphasePair, dispatcher:Dispatcher):Void
	{
		
	}

    public function getNumOverlappingPairs():Int
	{
		return 0;
	}

    public function cleanProxyFromPairs(proxy:BroadphaseProxy, dispatcher:Dispatcher):Void
	{
		
	}

    public function setOverlapFilterCallback(overlapFilterCallback:OverlapFilterCallback):Void
	{
		
	}

    public function processAllOverlappingPairs(callback:OverlapCallback, dispatcher:Dispatcher):Void
	{
		
	}

    public function findPair(proxy0:BroadphaseProxy, proxy1:BroadphaseProxy):BroadphasePair
	{
		return null;
	}

    public function hasDeferredRemoval():Bool
	{
		return false;
	}

    public function setInternalGhostPairCallback(ghostPairCallback:OverlappingPairCallback):Void
	{
		
	}
	
}