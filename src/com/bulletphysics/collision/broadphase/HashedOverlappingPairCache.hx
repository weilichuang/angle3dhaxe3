package com.bulletphysics.collision.broadphase;
import com.bulletphysics.collision.broadphase.BroadphasePair;
import com.bulletphysics.collision.broadphase.BroadphaseProxy;
import com.bulletphysics.collision.broadphase.Dispatcher;
import com.bulletphysics.collision.broadphase.OverlapCallback;
import com.bulletphysics.collision.broadphase.OverlapFilterCallback;
import com.bulletphysics.collision.shapes.StaticPlaneShape;
import com.bulletphysics.linearmath.MiscUtil;
import com.bulletphysics.util.Assert;
import com.bulletphysics.util.IntArrayList;
import com.bulletphysics.util.ObjectArrayList;
import com.bulletphysics.util.ObjectPool;

/**
 * Hash-space based {@link OverlappingPairCache}.
 * @author weilichuang
 */
class HashedOverlappingPairCache extends OverlappingPairCache
{
	private static inline var NULL_PAIR:Int = 0xFFFFFFFF;
	
	private var overlappingPairArray:ObjectArrayList<BroadphasePair> = new ObjectArrayList<BroadphasePair>();
	private var overlapFilterCallback:OverlapFilterCallback;

	private var hashTable:IntArrayList = new IntArrayList();
	private var next:IntArrayList = new IntArrayList();
	private var ghostPairCallback:OverlappingPairCallback;

	public function new() 
	{
		super();
		growTables();
	}
	
	/**
     * Add a pair and return the new pair. If the pair already exists,
     * no new pair is created and the old one is returned.
     */
	override public function addOverlappingPair(proxy0:BroadphaseProxy, proxy1:BroadphaseProxy):BroadphasePair
	{
		BulletStats.gAddedPairs++;
		
		if (!needsBroadphaseCollision(proxy0, proxy1))
		{
			return null;
		}
		
		return internalAddPair(proxy0, proxy1);
	}
	
	override public function removeOverlappingPair(proxy0:BroadphaseProxy, proxy1:BroadphaseProxy, dispatcher:Dispatcher):Dynamic
	{
		BulletStats.gRemovePairs++;
		
		if (proxy0.getUid() > proxy1.getUid())
		{
			var tmp:BroadphaseProxy = proxy0;
			proxy0 = proxy1;
			proxy1 = tmp;
		}
		
		var proxyId1:Int = proxy0.getUid();
		var proxyId2:Int = proxy1.getUid();
		
		
		var hash:Int = getHash(proxyId1, proxyId2) & (overlappingPairArray.capacity() - 1);

        var pair:BroadphasePair = internalFindPair(proxy0, proxy1, hash);
        if (pair == null) 
		{
            return null;
        }

        cleanOverlappingPair(pair, dispatcher);

        var userData:Dynamic = pair.userInfo;

        //assert (pair.pProxy0.getUid() == proxyId1);
        //assert (pair.pProxy1.getUid() == proxyId2);

        // JAVA TODO: optimize
        //int pairIndex = int(pair - &m_overlappingPairArray[0]);
        var pairIndex:Int = overlappingPairArray.indexOf(pair);
        //assert (pairIndex != -1);

        //assert (pairIndex < overlappingPairArray.size());

        // Remove the pair from the hash table.
        var index:Int = hashTable.get(hash);
        //assert (index != NULL_PAIR);

        var previous:Int = NULL_PAIR;
        while (index != pairIndex)
		{
            previous = index;
            index = next.get(index);
        }

        if (previous != NULL_PAIR) 
		{
            //assert (next.get(previous) == pairIndex);
            next.set(previous, next.get(pairIndex));
        } 
		else 
		{
            hashTable.set(hash, next.get(pairIndex));
        }

        // We now move the last pair into spot of the
        // pair being removed. We need to fix the hash
        // table indices to support the move.

        var lastPairIndex:Int = overlappingPairArray.size() - 1;

        if (ghostPairCallback != null)
		{
            ghostPairCallback.removeOverlappingPair(proxy0, proxy1, dispatcher);
        }

        // If the removed pair is the last pair, we are done.
        if (lastPairIndex == pairIndex) 
		{
            overlappingPairArray.removeQuick(overlappingPairArray.size() - 1);
            return userData;
        }

        // Remove the last pair from the hash table.
        var last:BroadphasePair = overlappingPairArray.getQuick(lastPairIndex);
        /* missing swap here too, Nat. */
        var lastHash:Int = getHash(last.pProxy0.getUid(), last.pProxy1.getUid()) & (overlappingPairArray.capacity() - 1);

        index = hashTable.get(lastHash);
        //assert (index != NULL_PAIR);

        previous = NULL_PAIR;
        while (index != lastPairIndex)
		{
            previous = index;
            index = next.get(index);
        }

        if (previous != NULL_PAIR)
		{
            Assert.assert (next.get(previous) == lastPairIndex);
            next.set(previous, next.get(lastPairIndex));
        } 
		else 
		{
            hashTable.set(lastHash, next.get(lastPairIndex));
        }

        // Copy the last pair into the remove pair's spot.
        overlappingPairArray.getQuick(pairIndex).fromBroadphasePair(overlappingPairArray.getQuick(lastPairIndex));

        // Insert the last pair into the hash table
        next.set(pairIndex, hashTable.get(lastHash));
        hashTable.set(lastHash, pairIndex);

        overlappingPairArray.removeQuick(overlappingPairArray.size() - 1);

        return userData;
	}
	
	public function needsBroadphaseCollision(proxy0:BroadphaseProxy, proxy1:BroadphaseProxy):Bool
	{
		if (overlapFilterCallback != null)
		{
			return overlapFilterCallback.needBroadphaseCollision(proxy0, proxy1);
		}
		
		var collides:Bool = (proxy0.collisionFilterGroup & proxy1.collisionFilterMask) != 0;
		collides = collides && (proxy1.collisionFilterGroup & proxy0.collisionFilterMask) != 0;
		
		return collides;
	}
	
	override public function processAllOverlappingPairs(callback:OverlapCallback, dispatcher:Dispatcher):Void 
	{
		var i:Int = 0;
		while (i < overlappingPairArray.size())
		{
            var pair:BroadphasePair = overlappingPairArray.getQuick(i);
			
            if (callback.processOverlap(pair)) 
			{
                removeOverlappingPair(pair.pProxy0, pair.pProxy1, dispatcher);

                BulletStats.gOverlappingPairs--;
            } 
			else
			{
                i++;
            }
        }
	}
	
	override public function removeOverlappingPairsContainingProxy(proxy:BroadphaseProxy, dispatcher:Dispatcher):Void
	{
		processAllOverlappingPairs(new RemovePairCallback(proxy), dispatcher);
	}
		
	override public function cleanProxyFromPairs(proxy:BroadphaseProxy, dispatcher:Dispatcher):Void 
	{
		processAllOverlappingPairs(new CleanPairCallback(proxy, this, dispatcher), dispatcher);
	}
	
	override public function getOverlappingPairArray():ObjectArrayList<BroadphasePair> 
	{
		return overlappingPairArray;
	}
	
	override public function cleanOverlappingPair(pair:BroadphasePair, dispatcher:Dispatcher):Void 
	{
		if (pair.algorithm != null)
		{
            //pair.algorithm.destroy();
            dispatcher.freeCollisionAlgorithm(pair.algorithm);
            pair.algorithm = null;
        }
	}
	
	override public function findPair(proxy0:BroadphaseProxy, proxy1:BroadphaseProxy):BroadphasePair 
	{
		BulletStats.gFindPairs++;
		
        if (proxy0.getUid() > proxy1.getUid()) 
		{
            var tmp:BroadphaseProxy = proxy0;
            proxy0 = proxy1;
            proxy1 = tmp;
        }
		
        var proxyId1:Int = proxy0.getUid();
        var proxyId2:Int = proxy1.getUid();

		/*if (proxyId1 > proxyId2) 
			btSwap(proxyId1, proxyId2);*/

        var hash:Int = getHash(proxyId1, proxyId2) & (overlappingPairArray.capacity() - 1);

        if (hash >= hashTable.size())
		{
            return null;
        }

        var index:Int = hashTable.get(hash);
        while (index != NULL_PAIR && 
			equalsPair(overlappingPairArray.getQuick(index), proxyId1, proxyId2) == false)
		{
            index = next.get(index);
        }

        if (index == NULL_PAIR)
		{
            return null;
        }

        //assert (index < overlappingPairArray.size());

        return overlappingPairArray.getQuick(index);
	}
	
	public function getCount():Int
	{
		return overlappingPairArray.size();
	}
	
	public function getOverlapFilterCallback():OverlapFilterCallback
	{
		return overlapFilterCallback;
	}
	
	override public function setOverlapFilterCallback(overlapFilterCallback:OverlapFilterCallback):Void 
	{
		this.overlapFilterCallback = overlapFilterCallback;
	}
	
	override public function getNumOverlappingPairs():Int 
	{
		return overlappingPairArray.size();
	}
	
	override public function hasDeferredRemoval():Bool 
	{
		return false;
	}
	
	private function internalAddPair(proxy0:BroadphaseProxy, proxy1:BroadphaseProxy):BroadphasePair
	{
        if (proxy0.getUid() > proxy1.getUid()) 
		{
            var tmp:BroadphaseProxy = proxy0;
            proxy0 = proxy1;
            proxy1 = tmp;
        }
		
        var proxyId1:Int = proxy0.getUid();
        var proxyId2:Int = proxy1.getUid();

		/*if (proxyId1 > proxyId2) 
		btSwap(proxyId1, proxyId2);*/

        var hash:Int = getHash(proxyId1, proxyId2) & (overlappingPairArray.capacity() - 1); // New hash value with new mask

        var pair:BroadphasePair = internalFindPair(proxy0, proxy1, hash);
        if (pair != null)
		{
            return pair;
        }
		/*for(int i=0;i<m_overlappingPairArray.size();++i)
		{
		if(	(m_overlappingPairArray[i].m_pProxy0==proxy0)&&
		(m_overlappingPairArray[i].m_pProxy1==proxy1))
		{
		printf("Adding duplicated %u<>%u\r\n",proxyId1,proxyId2);
		internalFindPair(proxy0, proxy1, hash);
		}
		}*/
        var count:Int = overlappingPairArray.size();
        var oldCapacity:Int = overlappingPairArray.capacity();
        overlappingPairArray.add(null);

        // this is where we add an actual pair, so also call the 'ghost'
        if (ghostPairCallback != null)
		{
            ghostPairCallback.addOverlappingPair(proxy0, proxy1);
        }

        var newCapacity:Int = overlappingPairArray.capacity();

        if (oldCapacity < newCapacity)
		{
            growTables();
            // hash with new capacity
            hash = getHash(proxyId1, proxyId2) & (overlappingPairArray.capacity() - 1);
        }

        pair = new BroadphasePair(proxy0, proxy1);
        pair.algorithm = null;
        pair.userInfo = null;

        overlappingPairArray.setQuick(overlappingPairArray.size() - 1, pair);

        next.set(count, hashTable.get(hash));
        hashTable.set(hash, count);

        return pair;
    }

    private function growTables():Void
	{
        var newCapacity:Int = overlappingPairArray.capacity();

        if (hashTable.size() < newCapacity)
		{
            // grow hashtable and next table
            var curHashtableSize:Int = hashTable.size();

            MiscUtil.resizeIntArrayList(hashTable, newCapacity, 0);
            MiscUtil.resizeIntArrayList(next, newCapacity, 0);

            for (i in 0...newCapacity)
			{
                hashTable.set(i, NULL_PAIR);
            }
			
            for (i in 0...newCapacity) 
			{
                next.set(i, NULL_PAIR);
            }

            for (i in 0...curHashtableSize)
			{

                var pair:BroadphasePair = overlappingPairArray.getQuick(i);
                var proxyId1:Int = pair.pProxy0.getUid();
                var proxyId2:Int = pair.pProxy1.getUid();
				/*if (proxyId1 > proxyId2) 
				btSwap(proxyId1, proxyId2);*/
                var hashValue:Int = getHash(proxyId1, proxyId2) & (overlappingPairArray.capacity() - 1); // New hash value with new mask
                next.set(i, hashTable.get(hashValue));
                hashTable.set(hashValue, i);
            }
        }
    }

    private function equalsPair(pair:BroadphasePair, proxyId1:Int, proxyId2:Int):Bool
	{
        return pair.pProxy0.getUid() == proxyId1 && pair.pProxy1.getUid() == proxyId2;
    }

    private function getHash(proxyId1:Int, proxyId2:Int):Int
	{
        var key:Int = (proxyId1) | (proxyId2 << 16);
        // Thomas Wang's hash

        key += ~(key << 15);
        key ^= (key >>> 10);
        key += (key << 3);
        key ^= (key >>> 6);
        key += ~(key << 11);
        key ^= (key >>> 16);
        return key;
    }

    private function internalFindPair(proxy0:BroadphaseProxy, proxy1:BroadphaseProxy, hash:Int):BroadphasePair
	{
        var proxyId1:Int = proxy0.getUid();
        var proxyId2:Int = proxy1.getUid();
        //#if 0 // wrong, 'equalsPair' use unsorted uids, copy-past devil striked again. Nat.
        //if (proxyId1 > proxyId2)
        //	btSwap(proxyId1, proxyId2);
        //#endif

        var index:Int = hashTable.get(hash);

        while (index != NULL_PAIR && equalsPair(overlappingPairArray.getQuick(index), proxyId1, proxyId2) == false) {
            index = next.get(index);
        }

        if (index == NULL_PAIR)
		{
            return null;
        }

        //assert (index < overlappingPairArray.size());

        return overlappingPairArray.getQuick(index);
    }

    override public function setInternalGhostPairCallback(ghostPairCallback:OverlappingPairCallback):Void
	{
        this.ghostPairCallback = ghostPairCallback;
    }
	
}

class RemovePairCallback extends OverlapCallback
{
	private var obsoleteProxy:BroadphaseProxy;
	
	public function new(obsoleteProxy:BroadphaseProxy)
	{
		super();
		this.obsoleteProxy = obsoleteProxy;
	}
	
	override public function processOverlap(pair:BroadphasePair):Bool
	{
		return (pair.pProxy0 == obsoleteProxy || pair.pProxy1 == obsoleteProxy);
	}
}

class CleanPairCallback extends OverlapCallback
{
	private var cleanProxy:BroadphaseProxy;
	private var pairCache:OverlappingPairCache;
	private var dispatcher:Dispatcher;
	
	public function new(cleanProxy:BroadphaseProxy, pairCache:OverlappingPairCache, dispatcher:Dispatcher)
	{
		super();
		this.cleanProxy = cleanProxy;
		this.pairCache = pairCache;
		this.dispatcher = dispatcher;
	}
	
	override public function processOverlap(pair:BroadphasePair):Bool
	{
		if ((pair.pProxy0 == cleanProxy) ||
                    (pair.pProxy1 == cleanProxy))
		{
			pairCache.cleanOverlappingPair(pair, dispatcher);
		}
		return false;
	}
}