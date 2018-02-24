package com.bulletphysics.collision.dispatch;
import com.bulletphysics.collision.broadphase.BroadphaseProxy;
import com.bulletphysics.collision.broadphase.Dispatcher;
import com.bulletphysics.collision.broadphase.HashedOverlappingPairCache;
import angle3d.error.Assert;

/**
 * ...
 
 */
class PairCachingGhostObject extends GhostObject
{

	private var  hashPairCache:HashedOverlappingPairCache = new HashedOverlappingPairCache();

    /**
     * This method is mainly for expert/internal use only.
     */
	override public function addOverlappingObjectInternal(otherProxy:BroadphaseProxy, thisProxy:BroadphaseProxy):Void 
	{
		var actualThisProxy:BroadphaseProxy = thisProxy != null ? thisProxy : getBroadphaseHandle();
        Assert.assert (actualThisProxy != null);

        var otherObject :CollisionObject= cast otherProxy.clientObject;
        Assert.assert (otherObject != null);

        // if this linearSearch becomes too slow (too many overlapping objects) we should add a more appropriate data structure
        var index:Int = overlappingObjects.indexOf(otherObject);
        if (index == -1) {
            overlappingObjects.add(otherObject);
            hashPairCache.addOverlappingPair(actualThisProxy, otherProxy);
        }
	}
	
	override public function removeOverlappingObjectInternal(otherProxy:BroadphaseProxy, dispatcher:Dispatcher, thisProxy:BroadphaseProxy):Void 
	{
		var otherObject:CollisionObject = cast otherProxy.clientObject;
        var actualThisProxy:BroadphaseProxy = thisProxy != null ? thisProxy : getBroadphaseHandle();
        Assert.assert (actualThisProxy != null);
        Assert.assert (otherObject != null);
		
        var index:Int = overlappingObjects.indexOf(otherObject);
        if (index != -1) 
		{
            overlappingObjects.setQuick(index, overlappingObjects.getQuick(overlappingObjects.size() - 1));
            overlappingObjects.removeQuick(overlappingObjects.size() - 1);
            hashPairCache.removeOverlappingPair(actualThisProxy, otherProxy, dispatcher);
        }
	}

    public function getOverlappingPairCache():HashedOverlappingPairCache
	{
        return hashPairCache;
    }
}