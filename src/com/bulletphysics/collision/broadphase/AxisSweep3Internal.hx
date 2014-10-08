package com.bulletphysics.collision.broadphase;
import com.bulletphysics.linearmath.MiscUtil;
import com.bulletphysics.linearmath.VectorUtil;
import com.bulletphysics.util.ObjectArrayList;
import com.vecmath.Vector3f;

/**
 * AxisSweep3Internal is an internal base class that implements sweep and prune.
 * Use concrete implementation {@link AxisSweep3} or {@link AxisSweep3_32}.
 * @author weilichuang
 */
class AxisSweep3Internal extends BroadphaseInterface
{
	private var bpHandleMask:Int;
    private var handleSentinel:Int;

    private var worldAabbMin:Vector3f = new Vector3f(); // overall system bounds
    private var worldAabbMax:Vector3f = new Vector3f(); // overall system bounds

    private var _quantize:Vector3f = new Vector3f();     // scaling factor for quantization

    private var numHandles:Int;                               // number of active handles
    private var maxHandles:Int;                               // max number of handles
    private var pHandles:Array<Handle>;                            // handles pool
    private var firstFreeHandle:Int;                            // free handles list

	// edge arrays for the 3 axes (each array has m_maxHandles * 2 + 2 sentinel entries)
    private var pEdges:Array<EdgeArray> = [];//[3];      

    private var pairCache:OverlappingPairCache;

    // OverlappingPairCallback is an additional optional user callback for adding/removing overlapping pairs, similar interface to OverlappingPairCache.
    private var userPairCallback:OverlappingPairCallback = null;

    private var ownsPairCache:Bool = false;

    private var invalidPair:Int = 0;

    // JAVA NOTE: added
    private var mask:Int;

    public function new(worldAabbMin:Vector3f, worldAabbMax:Vector3f, handleMask:Int, handleSentinel:Int, userMaxHandles:Int/* = 16384*/, pairCache:OverlappingPairCache/*=0*/)
	{
		super();
		
        this.bpHandleMask = handleMask;
        this.handleSentinel = handleSentinel;
        this.pairCache = pairCache;

        var maxHandles:Int = userMaxHandles + 1; // need to add one sentinel handle

        if (this.pairCache == null) 
		{
            this.pairCache = new HashedOverlappingPairCache();
            ownsPairCache = true;
        }

        //assert(bounds.HasVolume());

        // init bounds
        this.worldAabbMin.fromVector3f(worldAabbMin);
        this.worldAabbMax.fromVector3f(worldAabbMax);

        var aabbSize:Vector3f = new Vector3f();
        aabbSize.sub(this.worldAabbMax, this.worldAabbMin);

        var maxInt:Int = this.handleSentinel;

        _quantize.setTo(maxInt / aabbSize.x, maxInt / aabbSize.y, maxInt / aabbSize.z);

        // allocate handles buffer and put all handles on free list
        pHandles = new Array();
        for (i in 0...maxHandles)
		{
            pHandles[i] = createHandle();
        }
        this.maxHandles = maxHandles;
        this.numHandles = 0;

        // handle 0 is reserved as the null index, and is also used as the sentinel
        firstFreeHandle = 1;
        {
            for (i in firstFreeHandle...maxHandles) 
			{
                pHandles[i].setNextFree(i + 1);
            }
            pHandles[maxHandles - 1].setNextFree(0);
        }

        {
            // allocate edge buffers
            for (i in 0...3)
			{
                pEdges[i] = createEdgeArray(maxHandles * 2);
            }
        }
        //removed overlap management

        // make boundary sentinels

        pHandles[0].clientObject = null;

        for (axis in 0...3)
		{
            pHandles[0].setMinEdges(axis, 0);
            pHandles[0].setMaxEdges(axis, 1);

            pEdges[axis].setPos(0, 0);
            pEdges[axis].setHandle(0, 0);
            pEdges[axis].setPos(1, handleSentinel);
            pEdges[axis].setHandle(1, 0);
            //#ifdef DEBUG_BROADPHASE
            //debugPrintAxis(axis);
            //#endif //DEBUG_BROADPHASE
        }

        // JAVA NOTE: added
        mask = getMask();
    }

    // allocation/deallocation
    private function allocHandle():Int
	{
        //assert (firstFreeHandle != 0);

        var handle:Int = firstFreeHandle;
        firstFreeHandle = getHandle(handle).getNextFree();
        numHandles++;

        return handle;
    }

    private function freeHandle(handle:Int):Void
	{
        //assert (handle > 0 && handle < maxHandles);

        getHandle(handle).setNextFree(firstFreeHandle);
        firstFreeHandle = handle;

        numHandles--;
    }

    private function testOverlap(ignoreAxis:Int, pHandleA:Handle, pHandleB:Handle):Bool
	{
        // optimization 1: check the array index (memory address), instead of the m_pos

        for (axis in 0...3)
		{
            if (axis != ignoreAxis) 
			{
                if (pHandleA.getMaxEdges(axis) < pHandleB.getMinEdges(axis) ||
                        pHandleB.getMaxEdges(axis) < pHandleA.getMinEdges(axis))
				{
                    return false;
                }
            }
        }

        //optimization 2: only 2 axis need to be tested (conflicts with 'delayed removal' optimization)

		/*for (int axis = 0; axis < 3; axis++)
        {
		if (m_pEdges[axis][pHandleA->m_maxEdges[axis]].m_pos < m_pEdges[axis][pHandleB->m_minEdges[axis]].m_pos ||
		m_pEdges[axis][pHandleB->m_maxEdges[axis]].m_pos < m_pEdges[axis][pHandleA->m_minEdges[axis]].m_pos)
		{
		return false;
		}
		}
		*/

        return true;
    }

    //#ifdef DEBUG_BROADPHASE
    //void debugPrintAxis(int axis,bool checkCardinality=true);
    //#endif //DEBUG_BROADPHASE

    private function quantize(out:Array<Int>, point:Vector3f, isMax:Int):Void
	{
        var clampedPoint:Vector3f = point.clone();

        VectorUtil.setMax(clampedPoint, worldAabbMin);
        VectorUtil.setMin(clampedPoint, worldAabbMax);

        var v:Vector3f = new Vector3f();
        v.sub(clampedPoint, worldAabbMin);
        VectorUtil.mul(v, v, _quantize);

        out[0] = ((Std.int(v.x) & bpHandleMask) | isMax) & mask;
        out[1] = ((Std.int(v.y) & bpHandleMask) | isMax) & mask;
        out[2] = ((Std.int(v.z) & bpHandleMask) | isMax) & mask;
    }

    // sorting a min edge downwards can only ever *add* overlaps
    private function sortMinDown(axis:Int, edge:Int, dispatcher:Dispatcher, updateOverlaps:Bool):Void
	{
        var edgeArray:EdgeArray = pEdges[axis];
        var pEdge_idx:Int = edge;
        var pPrev_idx:Int = pEdge_idx - 1;

        var pHandleEdge:Handle = getHandle(edgeArray.getHandle(pEdge_idx));

        while (edgeArray.getPos(pEdge_idx) < edgeArray.getPos(pPrev_idx))
		{
            var pHandlePrev:Handle = getHandle(edgeArray.getHandle(pPrev_idx));

            if (edgeArray.isMax(pPrev_idx) != 0)
			{
                // if previous edge is a maximum check the bounds and add an overlap if necessary
                if (updateOverlaps && testOverlap(axis, pHandleEdge, pHandlePrev))
				{
                    pairCache.addOverlappingPair(pHandleEdge, pHandlePrev);
                    if (userPairCallback != null) 
					{
                        userPairCallback.addOverlappingPair(pHandleEdge, pHandlePrev);
                        //AddOverlap(pEdge->m_handle, pPrev->m_handle);
                    }
                }

                // update edge reference in other handle
                pHandlePrev.incMaxEdges(axis);
            } 
			else
			{
                pHandlePrev.incMinEdges(axis);
            }
            pHandleEdge.decMinEdges(axis);

            // swap the edges
            edgeArray.swap(pEdge_idx, pPrev_idx);

            // decrement
            pEdge_idx--;
            pPrev_idx--;
        }

        //#ifdef DEBUG_BROADPHASE
        //debugPrintAxis(axis);
        //#endif //DEBUG_BROADPHASE
    }

    // sorting a min edge upwards can only ever *remove* overlaps
    private function sortMinUp(axis:Int, edge:Int, dispatcher:Dispatcher, updateOverlaps:Bool):Void
	{
        var edgeArray:EdgeArray = pEdges[axis];
        var pEdge_idx:Int = edge;
        var pNext_idx:Int = pEdge_idx + 1;
        var pHandleEdge:Handle = getHandle(edgeArray.getHandle(pEdge_idx));

        while (edgeArray.getHandle(pNext_idx) != 0 && 
			(edgeArray.getPos(pEdge_idx) >= edgeArray.getPos(pNext_idx)))
		{
            var pHandleNext:Handle = getHandle(edgeArray.getHandle(pNext_idx));

            if (edgeArray.isMax(pNext_idx) != 0)
			{
                // if next edge is maximum remove any overlap between the two handles
                if (updateOverlaps) 
				{
                    var handle0:Handle = getHandle(edgeArray.getHandle(pEdge_idx));
                    var handle1:Handle = getHandle(edgeArray.getHandle(pNext_idx));

                    pairCache.removeOverlappingPair(handle0, handle1, dispatcher);
                    if (userPairCallback != null)
					{
                        userPairCallback.removeOverlappingPair(handle0, handle1, dispatcher);
                    }
                }

                // update edge reference in other handle
                pHandleNext.decMaxEdges(axis);
            } 
			else 
			{
                pHandleNext.decMinEdges(axis);
            }
            pHandleEdge.incMinEdges(axis);

            // swap the edges
            edgeArray.swap(pEdge_idx, pNext_idx);

            // increment
            pEdge_idx++;
            pNext_idx++;
        }
    }

    // sorting a max edge downwards can only ever *remove* overlaps
    private function sortMaxDown(axis:Int, edge:Int, dispatcher:Dispatcher, updateOverlaps:Bool):Void
	{
        var edgeArray:EdgeArray = pEdges[axis];
        var pEdge_idx:Int = edge;
        var pPrev_idx:Int = pEdge_idx - 1;
        var pHandleEdge:Handle = getHandle(edgeArray.getHandle(pEdge_idx));

        while (edgeArray.getPos(pEdge_idx) < edgeArray.getPos(pPrev_idx)) 
		{
            var pHandlePrev:Handle = getHandle(edgeArray.getHandle(pPrev_idx));

            if (edgeArray.isMax(pPrev_idx) == 0)
			{
                // if previous edge was a minimum remove any overlap between the two handles
                if (updateOverlaps)
				{
                    // this is done during the overlappingpairarray iteration/narrowphase collision
                    var handle0:Handle = getHandle(edgeArray.getHandle(pEdge_idx));
                    var handle1:Handle = getHandle(edgeArray.getHandle(pPrev_idx));
                    pairCache.removeOverlappingPair(handle0, handle1, dispatcher);
                    if (userPairCallback != null)
					{
                        userPairCallback.removeOverlappingPair(handle0, handle1, dispatcher);
                    }
                }

                // update edge reference in other handle
                pHandlePrev.incMinEdges(axis);
            } 
			else 
			{
                pHandlePrev.incMaxEdges(axis);
            }
            pHandleEdge.decMaxEdges(axis);

            // swap the edges
            edgeArray.swap(pEdge_idx, pPrev_idx);

            // decrement
            pEdge_idx--;
            pPrev_idx--;
        }

        //#ifdef DEBUG_BROADPHASE
        //debugPrintAxis(axis);
        //#endif //DEBUG_BROADPHASE
    }

    // sorting a max edge upwards can only ever *add* overlaps
    private function sortMaxUp(axis:Int, edge:Int, dispatcher:Dispatcher, updateOverlaps:Bool):Void
	{
        var edgeArray:EdgeArray = pEdges[axis];
        var pEdge_idx:Int = edge;
        var pNext_idx:Int = pEdge_idx + 1;
        var pHandleEdge:Handle = getHandle(edgeArray.getHandle(pEdge_idx));

        while (edgeArray.getHandle(pNext_idx) != 0 && 
				(edgeArray.getPos(pEdge_idx) >= edgeArray.getPos(pNext_idx)))
		{
            var pHandleNext:Handle = getHandle(edgeArray.getHandle(pNext_idx));

            if (edgeArray.isMax(pNext_idx) == 0) 
			{
                // if next edge is a minimum check the bounds and add an overlap if necessary
                if (updateOverlaps && testOverlap(axis, pHandleEdge, pHandleNext)) 
				{
                    var handle0:Handle = getHandle(edgeArray.getHandle(pEdge_idx));
                    var handle1:Handle = getHandle(edgeArray.getHandle(pNext_idx));
                    pairCache.addOverlappingPair(handle0, handle1);
                    if (userPairCallback != null)
					{
                        userPairCallback.addOverlappingPair(handle0, handle1);
                    }
                }

                // update edge reference in other handle
                pHandleNext.decMinEdges(axis);
            } 
			else 
			{
                pHandleNext.decMaxEdges(axis);
            }
            pHandleEdge.incMaxEdges(axis);

            // swap the edges
            edgeArray.swap(pEdge_idx, pNext_idx);

            // increment
            pEdge_idx++;
            pNext_idx++;
        }
    }

    public function getNumHandles():Int
	{
        return numHandles;
    }

    override public function calculateOverlappingPairs(dispatcher:Dispatcher):Void
	{
        if (pairCache.hasDeferredRemoval())
		{
            var overlappingPairArray:ObjectArrayList<BroadphasePair> = pairCache.getOverlappingPairArray();

            // perform a sort, to find duplicates and to sort 'invalid' pairs to the end
            overlappingPairArray.quickSort(BroadphasePair.broadphasePairSortPredicate);

            overlappingPairArray.resize(overlappingPairArray.size() - invalidPair, BroadphasePair);
            invalidPair = 0;

            var previousPair:BroadphasePair = new BroadphasePair();
            previousPair.pProxy0 = null;
            previousPair.pProxy1 = null;
            previousPair.algorithm = null;

            for (i in 0...overlappingPairArray.size()) 
			{
                var pair:BroadphasePair = overlappingPairArray.getQuick(i);

                var isDuplicate:Bool = (pair.equals(previousPair));

                previousPair.fromBroadphasePair(pair);

                var needsRemoval:Bool = false;

                if (!isDuplicate)
				{
                    var hasOverlap:Bool = testAabbOverlap(pair.pProxy0, pair.pProxy1);

                    if (hasOverlap) 
					{
                        needsRemoval = false;//callback->processOverlap(pair);
                    } 
					else 
					{
                        needsRemoval = true;
                    }
                } 
				else 
				{
                    // remove duplicate
                    needsRemoval = true;
                    // should have no algorithm
                    //assert (pair.algorithm == null);
                }

                if (needsRemoval)
				{
                    pairCache.cleanOverlappingPair(pair, dispatcher);

                    //		m_overlappingPairArray.swap(i,m_overlappingPairArray.size()-1);
                    //		m_overlappingPairArray.pop_back();
                    pair.pProxy0 = null;
                    pair.pProxy1 = null;
                    invalidPair++;
                    BulletStats.gOverlappingPairs--;
                }

            }

            // if you don't like to skip the invalid pairs in the array, execute following code:
            //#define CLEAN_INVALID_PAIRS 1
            //#ifdef CLEAN_INVALID_PAIRS

            // perform a sort, to sort 'invalid' pairs to the end
            overlappingPairArray.quickSort(BroadphasePair.broadphasePairSortPredicate);

            overlappingPairArray.resize(overlappingPairArray.size() - invalidPair, BroadphasePair);
            invalidPair = 0;
            //#endif//CLEAN_INVALID_PAIRS

            //printf("overlappingPairArray.size()=%d\n",overlappingPairArray.size());
        }
    }

    public function addHandle(aabbMin:Vector3f, aabbMax:Vector3f, pOwner:Dynamic, 
							collisionFilterGroup:Int, collisionFilterMask:Int, 
							dispatcher:Dispatcher, multiSapProxy:Dynamic):Int
	{
        // quantize the bounds
        var min:Array<Int> = [];
		var max:Array<Int> = [];
        quantize(min, aabbMin, 0);
        quantize(max, aabbMax, 1);

        // allocate a handle
        var handle:Int = allocHandle();

        var pHandle:Handle = getHandle(handle);

        pHandle.uniqueId = handle;
        //pHandle->m_pOverlaps = 0;
        pHandle.clientObject = pOwner;
        pHandle.collisionFilterGroup = collisionFilterGroup;
        pHandle.collisionFilterMask = collisionFilterMask;
        pHandle.multiSapParentProxy = multiSapProxy;

        // compute current limit of edge arrays
        var limit:Int = numHandles * 2;

        // insert new edges just inside the max boundary edge
        for (axis in 0...3)
		{
            pHandles[0].setMaxEdges(axis, pHandles[0].getMaxEdges(axis) + 2);

            pEdges[axis].set(limit + 1, limit - 1);

            pEdges[axis].setPos(limit - 1, min[axis]);
            pEdges[axis].setHandle(limit - 1, handle);

            pEdges[axis].setPos(limit, max[axis]);
            pEdges[axis].setHandle(limit, handle);

            pHandle.setMinEdges(axis, limit - 1);
            pHandle.setMaxEdges(axis, limit);
        }

        // now sort the new edges to their correct position
        sortMinDown(0, pHandle.getMinEdges(0), dispatcher, false);
        sortMaxDown(0, pHandle.getMaxEdges(0), dispatcher, false);
        sortMinDown(1, pHandle.getMinEdges(1), dispatcher, false);
        sortMaxDown(1, pHandle.getMaxEdges(1), dispatcher, false);
        sortMinDown(2, pHandle.getMinEdges(2), dispatcher, true);
        sortMaxDown(2, pHandle.getMaxEdges(2), dispatcher, true);

        return handle;
    }

    public function removeHandle(handle:Int, dispatcher:Dispatcher):Void
	{
        var pHandle:Handle = getHandle(handle);

        // explicitly remove the pairs containing the proxy
        // we could do it also in the sortMinUp (passing true)
        // todo: compare performance
        if (!pairCache.hasDeferredRemoval())
		{
            pairCache.removeOverlappingPairsContainingProxy(pHandle, dispatcher);
        }

        // compute current limit of edge arrays
        var limit:Int = numHandles * 2;

        for (axis in 0...3)
		{
            pHandles[0].setMaxEdges(axis, pHandles[0].getMaxEdges(axis) - 2);
        }

        // remove the edges by sorting them up to the end of the list
        for (axis in 0...3)
		{
            var pEdges:EdgeArray = this.pEdges[axis];
            var max:Int = pHandle.getMaxEdges(axis);
            pEdges.setPos(max, handleSentinel);

            sortMaxUp(axis, max, dispatcher, false);

            var i:Int = pHandle.getMinEdges(axis);
            pEdges.setPos(i, handleSentinel);

            sortMinUp(axis, i, dispatcher, false);

            pEdges.setHandle(limit - 1, 0);
            pEdges.setPos(limit - 1, handleSentinel);

            //#ifdef DEBUG_BROADPHASE
            //debugPrintAxis(axis,false);
            //#endif //DEBUG_BROADPHASE
        }

        // free the handle
        freeHandle(handle);
    }

    public function updateHandle(handle:Int,aabbMin:Vector3f,aabbMax:Vector3f,dispatcher:Dispatcher):Void
	{
        var pHandle:Handle = getHandle(handle);

        // quantize the new bounds
        var min:Array<Int> = [];
		var max:Array<Int> = [];
        quantize(min, aabbMin, 0);
        quantize(max, aabbMax, 1);

        // update changed edges
        for (axis in 0...3)
		{
            var emin:Int = pHandle.getMinEdges(axis);
            var emax:Int = pHandle.getMaxEdges(axis);

            var dmin:Int = min[axis] - pEdges[axis].getPos(emin);
            var dmax:Int = max[axis] - pEdges[axis].getPos(emax);

            pEdges[axis].setPos(emin, min[axis]);
            pEdges[axis].setPos(emax, max[axis]);

            // expand (only adds overlaps)
            if (dmin < 0)
			{
                sortMinDown(axis, emin, dispatcher, true);
            }
            if (dmax > 0)
			{
                sortMaxUp(axis, emax, dispatcher, true); // shrink (only removes overlaps)
            }
            if (dmin > 0) 
			{
                sortMinUp(axis, emin, dispatcher, true);
            }
            if (dmax < 0)
			{
                sortMaxDown(axis, emax, dispatcher, true);
            }

            //#ifdef DEBUG_BROADPHASE
            //debugPrintAxis(axis);
            //#endif //DEBUG_BROADPHASE
        }
    }

    public function getHandle(index:Int):Handle
	{
        return pHandles[index];
    }

    //public void processAllOverlappingPairs(OverlapCallback callback) {
    //}

    override public function createProxy(aabbMin:Vector3f, aabbMax:Vector3f, shapeType:BroadphaseNativeType, userPtr:Dynamic,  							collisionFilterGroup:Int, collisionFilterMask:Int, 
								dispatcher:Dispatcher, multiSapProxy:Dynamic):BroadphaseProxy
	{
        var handleId:Int = addHandle(aabbMin, aabbMax, userPtr, collisionFilterGroup, collisionFilterMask, dispatcher, multiSapProxy);

        var handle:Handle = getHandle(handleId);

        return handle;
    }

    override public function destroyProxy(proxy:BroadphaseProxy, dispatcher:Dispatcher):Void
	{
        var handle:Handle = Std.instance(proxy,Handle);
        removeHandle(handle.uniqueId, dispatcher);
    }

    override public function setAabb(proxy:BroadphaseProxy, aabbMin:Vector3f, aabbMax:Vector3f, dispatcher:Dispatcher):Void
	{
        var handle:Handle = Std.instance(proxy,Handle);
        updateHandle(handle.uniqueId, aabbMin, aabbMax, dispatcher);
    }

    public function testAabbOverlap(proxy0:BroadphaseProxy, proxy1:BroadphaseProxy):Bool
	{
        var pHandleA:Handle = Std.instance(proxy0,Handle);
        var pHandleB:Handle = Std.instance(proxy1,Handle);

        // optimization 1: check the array index (memory address), instead of the m_pos

        for (axis in 0...3)
		{
            if (pHandleA.getMaxEdges(axis) < pHandleB.getMinEdges(axis) ||
                    pHandleB.getMaxEdges(axis) < pHandleA.getMinEdges(axis))
			{
                return false;
            }
        }
        return true;
    }

    override public function getOverlappingPairCache():OverlappingPairCache
	{
        return pairCache;
    }

    public function setOverlappingPairUserCallback(pairCallback:OverlappingPairCallback):Void
	{
        userPairCallback = pairCallback;
    }

    public function getOverlappingPairUserCallback():OverlappingPairCallback
	{
        return userPairCallback;
    }

    // getAabb returns the axis aligned bounding box in the 'global' coordinate frame
    // will add some transform later
    override public function getBroadphaseAabb(aabbMin:Vector3f, aabbMax:Vector3f):Void
	{
        aabbMin.fromVector3f(worldAabbMin);
        aabbMax.fromVector3f(worldAabbMax);
    }

    override public function printStats():Void
	{
        /*
		printf("btAxisSweep3.h\n");
		printf("numHandles = %d, maxHandles = %d\n",m_numHandles,m_maxHandles);
		printf("aabbMin=%f,%f,%f,aabbMax=%f,%f,%f\n",m_worldAabbMin.getX(),m_worldAabbMin.getY(),m_worldAabbMin.getZ(),
		m_worldAabbMax.getX(),m_worldAabbMax.getY(),m_worldAabbMax.getZ());
		*/
    }

    ////////////////////////////////////////////////////////////////////////////

    private function createEdgeArray(size:Int):EdgeArray
	{
		return null;
	}

    private function createHandle():Handle
	{
		return null;
	}

    private function getMask():Int
	{
		return 0;
	}
	
}

class EdgeArray
{
	public function swap(idx1:Int, idx2:Int):Void
	{
		
	}

	public function set(dest:Int, src:Int):Void
	{
		
	}

	public function getPos(index:Int):Int
	{
		return 0;
	}

	public function setPos(index:Int, value:Int):Void
	{
		
	}

	public function getHandle(index:Int):Int
	{
		return 0;
	}

	public function setHandle(index:Int, value:Int):Void
	{
		
	}

	public function isMax(offset:Int):Int
	{
		return (getPos(offset) & 1);
	}
}

class Handle extends BroadphaseProxy
{
	public function new()
	{
		super();
	}
	
	public function getMinEdges(edgeIndex:Int):Int
	{
		return 0;
	}

	public function setMinEdges(edgeIndex:Int, value:Int):Void
	{
		
	}

	public function getMaxEdges(edgeIndex:Int):Int
	{
		return 0;
	}

	public function setMaxEdges(edgeIndex:Int, value:Int):Void
	{
		
	}

	public function incMinEdges(edgeIndex:Int):Void
	{
		setMinEdges(edgeIndex, getMinEdges(edgeIndex) + 1);
	}

	public function incMaxEdges(edgeIndex:Int):Void
	{
		setMaxEdges(edgeIndex, getMaxEdges(edgeIndex) + 1);
	}

	public function decMinEdges(edgeIndex:Int):Void
	{
		setMinEdges(edgeIndex, getMinEdges(edgeIndex) - 1);
	}

	public function decMaxEdges(edgeIndex:Int):Void
	{
		setMaxEdges(edgeIndex, getMaxEdges(edgeIndex) - 1);
	}

	public function setNextFree(next:Int):Void
	{
		setMinEdges(0, next);
	}

	public function getNextFree():Int
	{
		return getMinEdges(0);
	}
}