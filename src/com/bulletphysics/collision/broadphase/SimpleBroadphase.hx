package com.bulletphysics.collision.broadphase;
import com.bulletphysics.util.Assert;
import com.bulletphysics.util.ObjectArrayList;
import vecmath.Vector3f;

/**
 * SimpleBroadphase is just a unit-test for {@link AxisSweep3}, {@link AxisSweep3_32},
 * or {@link DbvtBroadphase}, so use those classes instead. It is a brute force AABB
 * culling broadphase based on O(n^2) AABB checks.
 *
 * @author weilichuang
 */
class SimpleBroadphase extends BroadphaseInterface
{
	private var handles:ObjectArrayList<SimpleBroadphaseProxy> = new ObjectArrayList<SimpleBroadphaseProxy>();
	private var pairCache:OverlappingPairCache;

	public function new(maxProxies:Int = 16384, overlappingPairCache:OverlappingPairCache = null) 
	{
		super();
		
		this.pairCache = overlappingPairCache;
		
		if (overlappingPairCache == null)
		{
			pairCache = new HashedOverlappingPairCache();
		}
	}
	
	override public function createProxy(aabbMin:Vector3f, aabbMax:Vector3f, shapeType:BroadphaseNativeType, userPtr:Dynamic,
	collisionFilterGroup:Int, collisionFilterMask:Int, dispatcher:Dispatcher, multiSapProxy:Dynamic):BroadphaseProxy
	{
		Assert.assert (aabbMin.x <= aabbMax.x && aabbMin.y <= aabbMax.y && aabbMin.z <= aabbMax.z);

        var proxy:SimpleBroadphaseProxy = new SimpleBroadphaseProxy(aabbMin, aabbMax, shapeType, userPtr, collisionFilterGroup, collisionFilterMask, multiSapProxy);
        proxy.uniqueId = handles.size();
        handles.add(proxy);
        return proxy;
	}
	
	override public function destroyProxy(proxyOrg:BroadphaseProxy, dispatcher:Dispatcher):Void
	{
		handles.removeObject(cast proxyOrg);
		
		pairCache.removeOverlappingPairsContainingProxy(proxyOrg, dispatcher);
	}
	
	override public function setAabb(proxy:BroadphaseProxy, aabbMin:Vector3f, aabbMax:Vector3f, dispatcher:Dispatcher):Void
	{
        var sbp:SimpleBroadphaseProxy = cast proxy;
        sbp.min.fromVector3f(aabbMin);
        sbp.max.fromVector3f(aabbMax);
    }

    private static function aabbOverlap(proxy0:SimpleBroadphaseProxy, proxy1:SimpleBroadphaseProxy):Bool 
	{
        return proxy0.min.x <= proxy1.max.x && proxy1.min.x <= proxy0.max.x &&
                proxy0.min.y <= proxy1.max.y && proxy1.min.y <= proxy0.max.y &&
                proxy0.min.z <= proxy1.max.z && proxy1.min.z <= proxy0.max.z;
    }

    override public function calculateOverlappingPairs(dispatcher:Dispatcher):Void
	{
        for (i in 0...handles.size())
		{
            var proxy0:SimpleBroadphaseProxy = handles.getQuick(i);
            for (j in 0...handles.size()) 
			{
                var proxy1:SimpleBroadphaseProxy = handles.getQuick(j);
                if (proxy0 == proxy1) continue;

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

    override public function getOverlappingPairCache():OverlappingPairCache
	{
        return pairCache;
    }

    override public function getBroadphaseAabb(aabbMin:Vector3f, aabbMax:Vector3f):Void
	{
        aabbMin.setTo(-1e30, -1e30, -1e30);
        aabbMax.setTo(1e30, 1e30, 1e30);
    }

    override public function printStats():Void 
	{
//		System.out.printf("btSimpleBroadphase.h\n");
//		System.out.printf("numHandles = %d, maxHandles = %d\n", /*numHandles*/ handles.size(), maxHandles);
    }
}