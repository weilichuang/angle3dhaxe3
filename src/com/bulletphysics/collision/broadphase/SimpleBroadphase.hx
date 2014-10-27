package com.bulletphysics.collision.broadphase;
import de.polygonal.ds.error.Assert;
import com.bulletphysics.util.ObjectArrayList;
import vecmath.Vector3f;

/**
 * SimpleBroadphase is just a unit-test for {@link AxisSweep3}, {@link AxisSweep3_32},
 * or {@link DbvtBroadphase}, so use those classes instead. It is a brute force AABB
 * culling broadphase based on O(n^2) AABB checks.
 *
 * @author weilichuang
 */
class SimpleBroadphase implements BroadphaseInterface
{
	private var handles:ObjectArrayList<SimpleBroadphaseProxy> = new ObjectArrayList<SimpleBroadphaseProxy>();
	private var pairCache:OverlappingPairCache;

	public function new(maxProxies:Int = 16384, overlappingPairCache:OverlappingPairCache = null) 
	{
		this.pairCache = overlappingPairCache;
		
		if (overlappingPairCache == null)
		{
			pairCache = new HashedOverlappingPairCache();
		}
	}
	
	public function createProxy(aabbMin:Vector3f, aabbMax:Vector3f, shapeType:BroadphaseNativeType, userPtr:Dynamic,
	collisionFilterGroup:Int, collisionFilterMask:Int, dispatcher:Dispatcher, multiSapProxy:Dynamic):BroadphaseProxy
	{
		Assert.assert (aabbMin.x <= aabbMax.x && aabbMin.y <= aabbMax.y && aabbMin.z <= aabbMax.z);

        var proxy:SimpleBroadphaseProxy = new SimpleBroadphaseProxy(aabbMin, aabbMax, shapeType, userPtr, collisionFilterGroup, collisionFilterMask, multiSapProxy);
        proxy.uniqueId = handles.size();
        handles.add(proxy);
        return proxy;
	}
	
	public function destroyProxy(proxyOrg:BroadphaseProxy, dispatcher:Dispatcher):Void
	{
		handles.removeObject(cast proxyOrg);
		
		pairCache.removeOverlappingPairsContainingProxy(proxyOrg, dispatcher);
	}
	
	public function setAabb(proxy:BroadphaseProxy, aabbMin:Vector3f, aabbMax:Vector3f, dispatcher:Dispatcher):Void
	{
        var sbp:SimpleBroadphaseProxy = cast proxy;
        sbp.min.fromVector3f(aabbMin);
        sbp.max.fromVector3f(aabbMax);
    }

    private static inline function aabbOverlap(proxy0:SimpleBroadphaseProxy, proxy1:SimpleBroadphaseProxy):Bool 
	{
		var min0:Vector3f = proxy0.min;
		var max0:Vector3f = proxy0.max;
		var min1:Vector3f = proxy1.min;
		var max1:Vector3f = proxy1.max;
        return min0.x <= max1.x && min1.x <= max0.x &&
               min0.y <= max1.y && min1.y <= max0.y &&
               min0.z <= max1.z && min1.z <= max0.z;
    }

    public function calculateOverlappingPairs(dispatcher:Dispatcher):Void
	{
		var size:Int = handles.size();
        for (i in 0...size)
		{
            var proxy0:SimpleBroadphaseProxy = handles.getQuick(i);
            for (j in 0...size) 
			{
                var proxy1:SimpleBroadphaseProxy = handles.getQuick(j);
                if (proxy0 == proxy1) 
					continue;

                if (aabbOverlap(proxy0, proxy1))
				{
                    if (pairCache.findPair(proxy0, proxy1) == null) 
					{
                        pairCache.addOverlappingPair(proxy0, proxy1);
                    }
                } 
				else
				{
                    // JAVA NOTE: pairCache.hasDeferredRemoval() = true is not implemented

                    if (!pairCache.hasDeferredRemoval())
					{
                        if (pairCache.findPair(proxy0, proxy1) != null) 
						{
                            pairCache.removeOverlappingPair(proxy0, proxy1, dispatcher);
                        }
                    }
                }
            }
        }
    }

    public function getOverlappingPairCache():OverlappingPairCache
	{
        return pairCache;
    }

    public function getBroadphaseAabb(aabbMin:Vector3f, aabbMax:Vector3f):Void
	{
        aabbMin.setTo(-1e30, -1e30, -1e30);
        aabbMax.setTo(1e30, 1e30, 1e30);
    }

    public function printStats():Void 
	{
//		System.out.printf("btSimpleBroadphase.h\n");
//		System.out.printf("numHandles = %d, maxHandles = %d\n", /*numHandles*/ handles.size(), maxHandles);
    }
}