package com.bulletphysics.collision.dispatch;
import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.bulletphysics.collision.broadphase.BroadphasePair;
import com.bulletphysics.collision.broadphase.CollisionAlgorithm;
import com.bulletphysics.collision.broadphase.CollisionAlgorithmConstructionInfo;
import com.bulletphysics.collision.broadphase.Dispatcher;
import com.bulletphysics.collision.broadphase.DispatcherInfo;
import com.bulletphysics.collision.broadphase.OverlapCallback;
import com.bulletphysics.collision.broadphase.OverlappingPairCache;
import com.bulletphysics.collision.dispatch.CollisionObject;
import com.bulletphysics.collision.narrowphase.PersistentManifold;
import com.bulletphysics.util.ObjectArrayList;
import com.bulletphysics.util.ObjectPool;
import angle3d.error.Assert;
import angle3d.utils.Logger;


/**
 * ...
 
 */
class CollisionDispatcher implements Dispatcher
{
	private var manifoldsPool:ObjectPool<PersistentManifold> = ObjectPool.getPool(PersistentManifold);
	
	private static var MAX_BROADPHASE_COLLISION_TYPES:Int = BroadphaseNativeType.MAX_BROADPHASE_COLLISION_TYPES.toInt();
	
	private var count:Int = 0;
	private var manifoldsPtr:ObjectArrayList<PersistentManifold> = new ObjectArrayList<PersistentManifold>();
	private var useIslands:Bool = true;
	private var staticWarningReported:Bool = false;
	private var defaultManifoldResult:ManifoldResult;
	private var nearCallback:NearCallback;
	private var doubleDispatch:Array<Array<CollisionAlgorithmCreateFunc>>;
	private var collisionConfiguration:CollisionConfiguration;

	private var tmpCI:CollisionAlgorithmConstructionInfo = new CollisionAlgorithmConstructionInfo();
	
	public function new(collisionConfiguration:CollisionConfiguration) 
	{
		this.collisionConfiguration = collisionConfiguration;

        setNearCallback(new DefaultNearCallback());

        //m_collisionAlgorithmPoolAllocator = collisionConfiguration->getCollisionAlgorithmPool();
        //m_persistentManifoldPoolAllocator = collisionConfiguration->getPersistentManifoldPool();

		doubleDispatch = [];
		
		var max:Int = MAX_BROADPHASE_COLLISION_TYPES;
        for (i in 0...max) 
		{
			doubleDispatch[i] = [];
			
			var type0:BroadphaseNativeType = new BroadphaseNativeType(i);
			
            for (j in 0...max)
			{
                doubleDispatch[i][j] = collisionConfiguration.getCollisionAlgorithmCreateFunc(type0, new BroadphaseNativeType(j));
				
				#if debug
                Assert.assert (doubleDispatch[i][j] != null);
				#end
            }
        }
	}
	
	public function registerCollisionCreateFunc(proxyType0:Int, proxyType1:Int, createFunc:CollisionAlgorithmCreateFunc):Void
	{
		doubleDispatch[proxyType0][proxyType1] = createFunc;
	}
	
	public inline function getNearCallback():NearCallback
	{
		return nearCallback;
	}
	
	public function setNearCallback(nearCallback:NearCallback):Void
	{
		this.nearCallback = nearCallback;
	}
	
	public inline function getCollisionConfiguration():CollisionConfiguration
	{
		return collisionConfiguration;
	}
	
	public function setCollisionConfiguration(collisionConfiguration:CollisionConfiguration):Void
	{
		this.collisionConfiguration = collisionConfiguration;
	}
	
	public function findAlgorithm(body0:CollisionObject, body1:CollisionObject, sharedManifold:PersistentManifold = null):CollisionAlgorithm 
	{
		var ci:CollisionAlgorithmConstructionInfo = tmpCI;
        ci.dispatcher1 = this;
        ci.manifold = sharedManifold;
        var createFunc:CollisionAlgorithmCreateFunc = getCreateFunc(body0.getCollisionShape().shapeType,body1.getCollisionShape().shapeType);
        var algo:CollisionAlgorithm = createFunc.createCollisionAlgorithm(ci, body0, body1);
        algo.internalSetCreateFunc(createFunc);

        return algo;
	}
	
	private function getCreateFunc(type0:BroadphaseNativeType, type1:BroadphaseNativeType):CollisionAlgorithmCreateFunc
	{
		var index0:Int = type0.toInt();
		var index1:Int = type1.toInt();
		var createFunc = doubleDispatch[index0][index1];
		if (createFunc == null)
		{
			trace('cant find ${type0} ${type1} createFunc');
		}
		return createFunc;
	}
	
	public function freeCollisionAlgorithm(algo:CollisionAlgorithm):Void 
	{
		var createFunc:CollisionAlgorithmCreateFunc = algo.internalGetCreateFunc();
        algo.internalSetCreateFunc(null);
		if(createFunc != null)
			createFunc.releaseCollisionAlgorithm(algo);
        algo.destroy();
	}
	
	public function getNewManifold(body0:Dynamic, body1:Dynamic):PersistentManifold 
	{
		//gNumManifold++;

        //btAssert(gNumManifold < 65535);

        var body0:CollisionObject = cast body0;
        var body1:CollisionObject = cast body1;

		/*
        void* mem = 0;

		if (m_persistentManifoldPoolAllocator->getFreeCount())
		{
			mem = m_persistentManifoldPoolAllocator->allocate(sizeof(btPersistentManifold));
		} else
		{
			mem = btAlignedAlloc(sizeof(btPersistentManifold),16);

		}
		btPersistentManifold* manifold = new(mem) btPersistentManifold (body0,body1,0);
		manifold->m_index1a = m_manifoldsPtr.size();
		m_manifoldsPtr.push_back(manifold);
		*/

        var manifold:PersistentManifold = manifoldsPool.get();
        manifold.init(body0, body1, 0);

        manifold.index1a = manifoldsPtr.size();
        manifoldsPtr.add(manifold);

        return manifold;
	}
	
	public function releaseManifold(manifold:PersistentManifold):Void 
	{
		//gNumManifold--;

        //printf("releaseManifold: gNumManifold %d\n",gNumManifold);
        clearManifold(manifold);

        // TODO: optimize
        var findIndex:Int = manifold.index1a;
		
		#if debug
        Assert.assert (findIndex < manifoldsPtr.size());
		#end
		
		var findManifold:PersistentManifold = manifoldsPtr.getQuick(findIndex);
		manifoldsPtr.setQuick(findIndex, manifoldsPtr.getQuick(manifoldsPtr.size() - 1));
		manifoldsPtr.setQuick(manifoldsPtr.size() - 1, findManifold);

        manifoldsPtr.getQuick(findIndex).index1a = findIndex;
        manifoldsPtr.removeQuick(manifoldsPtr.size() - 1);

        manifoldsPool.release(manifold);
        /*
		manifold->~btPersistentManifold();
		if (m_persistentManifoldPoolAllocator->validPtr(manifold))
		{
			m_persistentManifoldPoolAllocator->freeMemory(manifold);
		} else
		{
			btAlignedFree(manifold);
		}
		*/
	}
	
	public function clearManifold(manifold:PersistentManifold):Void 
	{
		manifold.clearManifold();
	}
	
	public inline function needsCollision(body0:CollisionObject, body1:CollisionObject):Bool 
	{
		#if debug
		Assert.assert (body0 != null);
        Assert.assert (body1 != null);

        if (!staticWarningReported) 
		{
            // broadphase filtering already deals with this
            if ((body0.isStaticObject() || body0.isKinematicObject()) &&
                    (body1.isStaticObject() || body1.isKinematicObject())) 
			{
                staticWarningReported = true;
				
                Logger.log("warning CollisionDispatcher.needsCollision: static-static collision!");
				
            }
        }
        #end
		
		var needsCollision:Bool = true;

        if (!body0.isActive() && !body1.isActive()) 
		{
            needsCollision = false;
        } 
		else if (!body0.checkCollideWith(body1)) 
		{
            needsCollision = false;
        }

        return needsCollision;
	}
	
	public function needsResponse(body0:CollisionObject, body1:CollisionObject):Bool 
	{
		//here you can do filtering
        var hasResponse:Bool = (body0.hasContactResponse() && body1.hasContactResponse());
        //no response between two static/kinematic bodies:
        hasResponse = hasResponse && ((!body0.isStaticOrKinematicObject()) || (!body1.isStaticOrKinematicObject()));
        return hasResponse;
	}
	
	private var collisionPairCallback:CollisionPairCallback = new CollisionPairCallback();
	
	public function dispatchAllCollisionPairs(pairCache:OverlappingPairCache, dispatchInfo:DispatcherInfo, dispatcher:Dispatcher):Void 
	{
		//m_blockedForChanges = true;
        collisionPairCallback.init(dispatchInfo, this);
        pairCache.processAllOverlappingPairs(collisionPairCallback, dispatcher);
        //m_blockedForChanges = false;
	}
	
	public function getNumManifolds():Int 
	{
		return manifoldsPtr.size();
	}
	
	public function getManifoldByIndexInternal(index:Int):PersistentManifold 
	{
		return manifoldsPtr.getQuick(index);
	}
	
	public function getInternalManifoldPointer():ObjectArrayList<PersistentManifold> 
	{
		return manifoldsPtr;
	}
	
}