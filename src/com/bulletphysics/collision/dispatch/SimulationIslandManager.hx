package com.bulletphysics.collision.dispatch;
import com.bulletphysics.collision.broadphase.BroadphasePair;
import com.bulletphysics.collision.broadphase.Dispatcher;
import com.bulletphysics.collision.narrowphase.PersistentManifold;
import com.bulletphysics.linearmath.MiscUtil;
import de.polygonal.ds.error.Assert;
import com.bulletphysics.util.ObjectArrayList;

/**
 * SimulationIslandManager creates and handles simulation islands, using {UnionFind}.
 * @author weilichuang
 */
class SimulationIslandManager
{
	private var unionFind:UnionFind = new UnionFind();

    private var islandmanifold:ObjectArrayList<PersistentManifold> = new ObjectArrayList<PersistentManifold>();
    private var islandBodies:ObjectArrayList<CollisionObject> = new ObjectArrayList<CollisionObject>();
	
	public function new()
	{
		
	}

    public inline function initUnionFind(n:Int):Void
	{
        unionFind.reset(n);
    }

    public inline function getUnionFind():UnionFind
	{
        return unionFind;
    }

    public function findUnions(dispatcher:Dispatcher, colWorld:CollisionWorld):Void
	{
        var pairPtr:ObjectArrayList<BroadphasePair> = colWorld.getPairCache().getOverlappingPairArray();
        for (i in 0...pairPtr.size()) 
		{
            var collisionPair:BroadphasePair = pairPtr.getQuick(i);

            var colObj0:CollisionObject = cast collisionPair.pProxy0.clientObject;
            var colObj1:CollisionObject = cast collisionPair.pProxy1.clientObject;

            if (((colObj0 != null) && colObj0.mergesSimulationIslands()) &&
				((colObj1 != null) && colObj1.mergesSimulationIslands()))
			{
                unionFind.unite(colObj0.getIslandTag(), colObj1.getIslandTag());
            }
        }
    }

    public function updateActivationState(colWorld:CollisionWorld, dispatcher:Dispatcher):Void
	{
		var arrayList:ObjectArrayList<CollisionObject> = colWorld.getCollisionObjectArray();
		
        initUnionFind(arrayList.size());

        // put the index into m_controllers into m_tag
        {
            var index:Int = 0;
            for (i in 0...arrayList.size()) 
			{
                var collisionObject:CollisionObject = arrayList.getQuick(i);
                collisionObject.setIslandTag(index);
                collisionObject.setCompanionId(-1);
                collisionObject.setHitFraction(1);
                index++;
            }
        }
        // do the union find

        findUnions(dispatcher, colWorld);
    }

    public function storeIslandActivationState(colWorld:CollisionWorld):Void
	{
        // put the islandId ('find' value) into m_tag
        {
			var objects:ObjectArrayList<CollisionObject> = colWorld.getCollisionObjectArray();
            var index:Int = 0;
            for (i in 0...objects.size()) 
			{
                var collisionObject:CollisionObject = objects.getQuick(i);
                if (!collisionObject.isStaticOrKinematicObject())
				{
                    collisionObject.setIslandTag(unionFind.find(index));
                    collisionObject.setCompanionId(-1);
                } 
				else 
				{
                    collisionObject.setIslandTag(-1);
                    collisionObject.setCompanionId(-2);
                }
                index++;
            }
        }
    }

    private inline function getIslandId(lhs:PersistentManifold):Int
	{
        var rcolObj0:CollisionObject = cast lhs.getBody0();
        var rcolObj1:CollisionObject = cast lhs.getBody1();
        return rcolObj0.getIslandTag() >= 0 ? rcolObj0.getIslandTag() : rcolObj1.getIslandTag();
    }

    public function buildIslands(dispatcher:Dispatcher, collisionObjects:ObjectArrayList<CollisionObject>):Void
	{
        BulletStats.pushProfile("islandUnionFindAndQuickSort");

		islandmanifold.clear();

		// we are going to sort the unionfind array, and store the element id in the size
		// afterwards, we clean unionfind, to make sure no-one uses it anymore

		getUnionFind().sortIslands();
		var numElem:Int = getUnionFind().getNumElements();

		var endIslandIndex:Int = 1;
		var startIslandIndex:Int;

		// update the sleeping state for bodies, if all are sleeping
		
		startIslandIndex = 0;
		while ( startIslandIndex < numElem) 
		{
			var islandId:Int = getUnionFind().getElement(startIslandIndex).id;
			
			endIslandIndex = startIslandIndex + 1;
			while ( (endIslandIndex < numElem) && (getUnionFind().getElement(endIslandIndex).id == islandId))
			{
				endIslandIndex++;
			}

			//int numSleeping = 0;

			var allSleeping:Bool = true;

			var idx:Int;
			for (idx in startIslandIndex...endIslandIndex) 
			{
				var i:Int = getUnionFind().getElement(idx).sz;

				var colObj0:CollisionObject = collisionObjects.getQuick(i);
				if ((colObj0.getIslandTag() != islandId) && (colObj0.getIslandTag() != -1))
				{
					//System.err.println("error in island management\n");
				}

				Assert.assert ((colObj0.getIslandTag() == islandId) || (colObj0.getIslandTag() == -1));
				if (colObj0.getIslandTag() == islandId)
				{
					if (colObj0.getActivationState() == CollisionObject.ACTIVE_TAG)
					{
						allSleeping = false;
					}
					if (colObj0.getActivationState() == CollisionObject.DISABLE_DEACTIVATION)
					{
						allSleeping = false;
					}
				}
			}


			if (allSleeping) 
			{
				//int idx;
				for (idx in startIslandIndex...endIslandIndex)
				{
					var i:Int = getUnionFind().getElement(idx).sz;
					var colObj0:CollisionObject = collisionObjects.getQuick(i);
					if ((colObj0.getIslandTag() != islandId) && (colObj0.getIslandTag() != -1))
					{
						//System.err.println("error in island management\n");
					}

					Assert.assert ((colObj0.getIslandTag() == islandId) || (colObj0.getIslandTag() == -1));

					if (colObj0.getIslandTag() == islandId)
					{
						colObj0.setActivationState(CollisionObject.ISLAND_SLEEPING);
					}
				}
			} 
			else
			{

				//int idx;
				for (idx in startIslandIndex...endIslandIndex)
				{
					var i:Int = getUnionFind().getElement(idx).sz;

					var colObj0:CollisionObject = collisionObjects.getQuick(i);
					if ((colObj0.getIslandTag() != islandId) && (colObj0.getIslandTag() != -1))
					{
						//System.err.println("error in island management\n");
					}

					Assert.assert ((colObj0.getIslandTag() == islandId) || (colObj0.getIslandTag() == -1));

					if (colObj0.getIslandTag() == islandId) 
					{
						if (colObj0.getActivationState() == CollisionObject.ISLAND_SLEEPING)
						{
							colObj0.setActivationState(CollisionObject.WANTS_DEACTIVATION);
						}
					}
				}
			}
			
			startIslandIndex = endIslandIndex;
		}


		var maxNumManifolds:Int = dispatcher.getNumManifolds();

		//#define SPLIT_ISLANDS 1
		//#ifdef SPLIT_ISLANDS
		//#endif //SPLIT_ISLANDS

		for (i in 0...maxNumManifolds)
		{
			var manifold:PersistentManifold = dispatcher.getManifoldByIndexInternal(i);

			var colObj0:CollisionObject = cast manifold.getBody0();
			var colObj1:CollisionObject = cast manifold.getBody1();

			// todo: check sleeping conditions!
			if (((colObj0 != null) && colObj0.getActivationState() != CollisionObject.ISLAND_SLEEPING) ||
				((colObj1 != null) && colObj1.getActivationState() != CollisionObject.ISLAND_SLEEPING)) 
			{

				// kinematic objects don't merge islands, but wake up all connected objects
				if (colObj0.isKinematicObject() && colObj0.getActivationState() != CollisionObject.ISLAND_SLEEPING) 
				{
					colObj1.activate();
				}
				if (colObj1.isKinematicObject() && colObj1.getActivationState() != CollisionObject.ISLAND_SLEEPING) 
				{
					colObj0.activate();
				}
				//#ifdef SPLIT_ISLANDS
				//filtering for response
				if (dispatcher.needsResponse(colObj0, colObj1)) 
				{
					islandmanifold.add(manifold);
				}
				//#endif //SPLIT_ISLANDS
			}
		}

        BulletStats.popProfile();
    }

    public function buildAndProcessIslands(dispatcher:Dispatcher, collisionObjects:ObjectArrayList<CollisionObject>, callback:IslandCallback):Void
	{
        buildIslands(dispatcher, collisionObjects);

        var endIslandIndex:Int = 1;
        var startIslandIndex:Int;
        var numElem:Int = getUnionFind().getNumElements();

        BulletStats.pushProfile("processIslands");

		//#ifndef SPLIT_ISLANDS
		//btPersistentManifold** manifold = dispatcher->getInternalManifoldPointer();
		//
		//callback->ProcessIsland(&collisionObjects[0],collisionObjects.size(),manifold,maxNumManifolds, -1);
		//#else
		// Sort manifolds, based on islands
		// Sort the vector using predicate and std::sort
		//std::sort(islandmanifold.begin(), islandmanifold.end(), btPersistentManifoldSortPredicate);

		var numManifolds:Int = islandmanifold.size();

		// we should do radix sort, it it much faster (O(n) instead of O (n log2(n))
		//islandmanifold.heapSort(btPersistentManifoldSortPredicate());

		// JAVA NOTE: memory optimized sorting with caching of temporary array
		//Collections.sort(islandmanifold, persistentManifoldComparator);
		islandmanifold.quickSort(persistentManifoldComparator);

		// now process all active islands (sets of manifolds for now)

		var startManifoldIndex:Int = 0;
		var endManifoldIndex:Int = 1;

		//int islandId;

		//printf("Start Islands\n");

		// traverse the simulation islands, and call the solver, unless all objects are sleeping/deactivated
		startIslandIndex = 0; 
		while (startIslandIndex < numElem) 
		{
			var islandId:Int = getUnionFind().getElement(startIslandIndex).id;
			var islandSleeping:Bool = false;

			endIslandIndex = startIslandIndex; 
			while ((endIslandIndex < numElem) && (getUnionFind().getElement(endIslandIndex).id == islandId))
			{
				var i:Int = getUnionFind().getElement(endIslandIndex).sz;
				var colObj0:CollisionObject = collisionObjects.getQuick(i);
				islandBodies.add(colObj0);
				if (!colObj0.isActive())
				{
					islandSleeping = true;
				}
				
				endIslandIndex++;
			}


			// find the accompanying contact manifold for this islandId
			var numIslandManifolds:Int = 0;
			//ObjectArrayList<PersistentManifold> startManifold = null;
			var startManifold_idx:Int = -1;

			if (startManifoldIndex < numManifolds)
			{
				var curIslandId:Int = getIslandId(islandmanifold.getQuick(startManifoldIndex));
				if (curIslandId == islandId) 
				{
					//startManifold = &m_islandmanifold[startManifoldIndex];
					//startManifold = islandmanifold.subList(startManifoldIndex, islandmanifold.size());
					startManifold_idx = startManifoldIndex;

					endManifoldIndex = startManifoldIndex + 1; 
					while ((endManifoldIndex < numManifolds) && (islandId == getIslandId(islandmanifold.getQuick(endManifoldIndex)))) 
					{
						endManifoldIndex++;
					}
					// Process the actual simulation, only if not sleeping/deactivated
					numIslandManifolds = endManifoldIndex - startManifoldIndex;
				}

			}

			if (!islandSleeping)
			{
				callback.processIsland(islandBodies, islandBodies.size(), islandmanifold, startManifold_idx, numIslandManifolds, islandId);
				//printf("Island callback of size:%d bodies, %d manifolds\n",islandBodies.size(),numIslandManifolds);
			}

			if (numIslandManifolds != 0)
			{
				startManifoldIndex = endManifoldIndex;
			}

			islandBodies.clear();
			
			startIslandIndex = endIslandIndex;
		}
		//#endif //SPLIT_ISLANDS

        BulletStats.popProfile();
    }

    private function persistentManifoldComparator(lhs:PersistentManifold,rhs:PersistentManifold):Int
	{
        return getIslandId(lhs) < getIslandId(rhs) ? -1 : 1;
    }
}