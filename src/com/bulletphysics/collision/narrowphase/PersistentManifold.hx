package com.bulletphysics.collision.narrowphase;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.LinearMathUtil;
import angle3d.error.Assert;
import angle3d.math.Vector3f;
import angle3d.math.Vector4f;

/**
 * PersistentManifold is a contact point cache, it stays persistent as long as objects
 * are overlapping in the broadphase. Those contact points are created by the collision
 * narrow phase.<p>
 * <p/>
 * The cache can be empty, or hold 1, 2, 3 or 4 points. Some collision algorithms (GJK)
 * might only add one point at a time, updates/refreshes old contact points, and throw
 * them away if necessary (distance becomes too large).<p>
 * <p/>
 * Reduces the cache to 4 points, when more then 4 points are added, using following rules:
 * the contact point with deepest penetration is always kept, and it tries to maximize the
 * area covered by the points.<p>
 * <p/>
 * Note that some pairs of objects might have more then one contact manifold.
 * 
 
 */
class PersistentManifold
{
	public static inline var MANIFOLD_CACHE_SIZE:Int = 4;

    private var pointCache:Array<ManifoldPoint>;
    /// this two body pointers can point to the physics rigidbody class.
    /// void* will allow any rigidbody class
    private var body0:Dynamic;
    private var body1:Dynamic;
    private var cachedPoints:Int;

    public var index1a:Int;

    public function new() 
	{
		pointCache =  new Array<ManifoldPoint>(MANIFOLD_CACHE_SIZE);
		for (i in 0...MANIFOLD_CACHE_SIZE)
		{
			pointCache[i] = new ManifoldPoint();
		}
	}

    public function init(body0:Dynamic, body1:Dynamic, bla:Int):Void 
	{
        this.body0 = body0;
        this.body1 = body1;
        cachedPoints = 0;
        index1a = 0;
    }

	var maxvec:Vector4f = new Vector4f();
	var a0:Vector3f = new Vector3f();
	var b0:Vector3f = new Vector3f();
	var cross:Vector3f = new Vector3f();
    /// sort cached points so most isolated points come first
    private inline function sortCachedPoints(pt:ManifoldPoint):Int
	{
        //calculate 4 possible cases areas, and take biggest area
        //also need to keep 'deepest'

        var maxPenetrationIndex:Int = -1;
//#define KEEP_DEEPEST_POINT 1
//#ifdef KEEP_DEEPEST_POINT
        var maxPenetration:Float = pt.getDistance();
        for (i in 0...4)
		{
            if (pointCache[i].getDistance() < maxPenetration)
			{
                maxPenetrationIndex = i;
                maxPenetration = pointCache[i].getDistance();
            }
        }
//#endif //KEEP_DEEPEST_POINT

        var res0:Float = 0, res1:Float = 0, res2:Float = 0, res3:Float = 0;
        if (maxPenetrationIndex != 0) 
		{
			a0.subtractBy(pt.localPointA, pointCache[1].localPointA);
			b0.subtractBy(pointCache[3].localPointA, pointCache[2].localPointA);
            
            cross.crossBy(a0, b0);
            res0 = cross.lengthSquared;
        }

        if (maxPenetrationIndex != 1)
		{
			a0.subtractBy(pt.localPointA, pointCache[0].localPointA);
			b0.subtractBy(pointCache[3].localPointA, pointCache[2].localPointA);

            cross.crossBy(a0, b0);
            res1 = cross.lengthSquared;
        }

        if (maxPenetrationIndex != 2)
		{
			a0.subtractBy(pt.localPointA, pointCache[0].localPointA);
			b0.subtractBy(pointCache[3].localPointA, pointCache[1].localPointA);

            cross.crossBy(a0, b0);
            res2 = cross.lengthSquared;
        }

        if (maxPenetrationIndex != 3) 
		{
			a0.subtractBy(pt.localPointA, pointCache[0].localPointA);
			b0.subtractBy(pointCache[2].localPointA, pointCache[1].localPointA);

            cross.crossBy(a0, b0);
            res3 = cross.lengthSquared;
        }

        maxvec.setTo(res0, res1, res2, res3);
        var biggestarea:Int = LinearMathUtil.closestAxis4(maxvec);
        return biggestarea;
    }

    //private int findContactPoint(ManifoldPoint unUsed, int numUnused, ManifoldPoint pt);

    public inline function getBody0():Dynamic
	{
        return body0;
    }

    public inline function getBody1():Dynamic 
	{
        return body1;
    }

    public function setBodies(body0:Dynamic, body1:Dynamic):Void
	{
        this.body0 = body0;
        this.body1 = body1;
    }

    public function clearUserCache(pt:ManifoldPoint):Void
	{
        var oldPtr:Dynamic = pt.userPersistentData;
        if (oldPtr != null)
		{
//#ifdef DEBUG_PERSISTENCY
//			int i;
//			int occurance = 0;
//			for (i = 0; i < cachedPoints; i++) {
//				if (pointCache[i].userPersistentData == oldPtr) {
//					occurance++;
//					if (occurance > 1) {
//						throw new InternalError();
//					}
//				}
//			}
//			assert (occurance <= 0);
//#endif //DEBUG_PERSISTENCY

            if (pt.userPersistentData != null && BulletGlobals.getContactDestroyedCallback() != null)
			{
                BulletGlobals.getContactDestroyedCallback().contactDestroyed(pt.userPersistentData);
                pt.userPersistentData = null;
            }

//#ifdef DEBUG_PERSISTENCY
//			DebugPersistency();
//#endif
        }
    }

    public inline function getNumContacts():Int
	{
        return cachedPoints;
    }

    public inline function getContactPoint(index:Int):ManifoldPoint
	{
        return pointCache[index];
    }

    // todo: get this margin from the current physics / collision environment
    public inline function getContactBreakingThreshold():Float
	{
        return BulletGlobals.contactBreakingThreshold;
    }
	
    public inline function getCacheEntry(newPoint:ManifoldPoint):Int
	{
        var shortestDist:Float = getContactBreakingThreshold() * getContactBreakingThreshold();
        var size:Int = getNumContacts();
        var nearestPoint:Int = -1;
        for (i in 0...size)
		{
            var mp:ManifoldPoint = pointCache[i];

			//var diffA:Vector3f = new Vector3f();
            //diffA.sub2(mp.localPointA, newPoint.localPointA);
			
			//var distToManiPoint:Float = diffA.dot(diffA);
			
			var diffAX:Float = mp.localPointA.x - newPoint.localPointA.x;
			var diffAY:Float = mp.localPointA.y - newPoint.localPointA.y;
			var diffAZ:Float = mp.localPointA.z - newPoint.localPointA.z;

			var distToManiPoint:Float = diffAX * diffAX + diffAY * diffAY + diffAZ * diffAZ;
            if (distToManiPoint < shortestDist)
			{
                shortestDist = distToManiPoint;
                nearestPoint = i;
            }
        }
        return nearestPoint;
    }

    public function addManifoldPoint(newPoint:ManifoldPoint):Int
	{
		#if debug
        Assert.assert (validContactDistance(newPoint));
		#end

        var insertIndex:Int = getNumContacts();
        if (insertIndex == MANIFOLD_CACHE_SIZE)
		{
            //#if MANIFOLD_CACHE_SIZE >= 4
            if (MANIFOLD_CACHE_SIZE >= 4) 
			{
                //sort cache so best points come first, based on area
                insertIndex = sortCachedPoints(newPoint);
            } 
			else 
			{
                //#else
                insertIndex = 0;
            }
            //#endif

            clearUserCache(pointCache[insertIndex]);
        } 
		else
		{
            cachedPoints++;
        }
		
		#if debug
        Assert.assert (pointCache[insertIndex].userPersistentData == null);
		#end
		
        pointCache[insertIndex].set(newPoint);
        return insertIndex;
    }

    public function removeContactPoint(index:Int):Void
	{
        clearUserCache(pointCache[index]);

        var lastUsedIndex:Int = getNumContacts() - 1;
//		m_pointCache[index] = m_pointCache[lastUsedIndex];
        if (index != lastUsedIndex) 
		{
            // TODO: possible bug
            pointCache[index].set(pointCache[lastUsedIndex]);
            //get rid of duplicated userPersistentData pointer
            pointCache[lastUsedIndex].userPersistentData = null;
            pointCache[lastUsedIndex].appliedImpulse = 0;
            pointCache[lastUsedIndex].lateralFrictionInitialized = false;
            pointCache[lastUsedIndex].appliedImpulseLateral1 = 0;
            pointCache[lastUsedIndex].appliedImpulseLateral2 = 0;
            pointCache[lastUsedIndex].lifeTime = 0;
        }

        Assert.assert (pointCache[lastUsedIndex].userPersistentData == null);
        cachedPoints--;
    }

    public function replaceContactPoint(newPoint:ManifoldPoint, insertIndex:Int):Void
	{
		#if debug
        Assert.assert (validContactDistance(newPoint));
		#end

		var insertPoint:ManifoldPoint = pointCache[insertIndex];

        var lifeTime:Int = insertPoint.getLifeTime();
        var appliedImpulse:Float = insertPoint.appliedImpulse;
        var appliedLateralImpulse1:Float = insertPoint.appliedImpulseLateral1;
        var appliedLateralImpulse2:Float = insertPoint.appliedImpulseLateral2;

		#if debug
        Assert.assert (lifeTime >= 0);
		#end
		
        var cache:Dynamic = insertPoint.userPersistentData;

        insertPoint.set(newPoint);

        insertPoint.userPersistentData = cache;
        insertPoint.appliedImpulse = appliedImpulse;
        insertPoint.appliedImpulseLateral1 = appliedLateralImpulse1;
        insertPoint.appliedImpulseLateral2 = appliedLateralImpulse2;

        insertPoint.lifeTime = lifeTime;
    }

    private inline function validContactDistance(pt:ManifoldPoint):Bool
	{
        return pt.distance1 <= getContactBreakingThreshold();
    }

    /** 
	 * calculated new worldspace coordinates and depth, and reject points that exceed the collision margin 
	 */
    public function refreshContactPoints(trA:Transform, trB:Transform):Void
	{
		var i:Int = getNumContacts() - 1; 
        while (i >= 0)
		{
            var manifoldPoint:ManifoldPoint = pointCache[i];
			var worldA:Vector3f = manifoldPoint.positionWorldOnA;
			var worldB:Vector3f = manifoldPoint.positionWorldOnB;
			var normalWorldB:Vector3f = manifoldPoint.normalWorldOnB;

            worldA.copyFrom(manifoldPoint.localPointA);
            trA.transform(worldA);

            worldB.copyFrom(manifoldPoint.localPointB);
            trB.transform(worldB);

			//var tmp:Vector3f = new Vector3f();
            //tmp.fromVector3f(manifoldPoint.positionWorldOnA);
            //tmp.sub(manifoldPoint.positionWorldOnB);
            //manifoldPoint.distance1 = tmp.dot(manifoldPoint.normalWorldOnB);
			
			//optimize code
			var tx:Float = worldA.x - worldB.x;
			var ty:Float = worldA.y - worldB.y;
			var tz:Float = worldA.z - worldB.z;
			manifoldPoint.distance1 = tx * normalWorldB.x + ty * normalWorldB.y + tz * normalWorldB.z;

            manifoldPoint.lifeTime++;
			
			i--;
        }

        // then
        var distance2d:Float;
		
		var BreakingThresholdSqrt:Float = getContactBreakingThreshold() * getContactBreakingThreshold();
		var callback:ContactProcessedCallback = BulletGlobals.getContactProcessedCallback();
        
		i = getNumContacts() - 1;
        while ( i >= 0)
		{
            var manifoldPoint:ManifoldPoint = pointCache[i];
            // contact becomes invalid when signed distance exceeds margin (projected on contactnormal direction)
            if (!validContactDistance(manifoldPoint))
			{
                removeContactPoint(i);
            } 
			else
			{
				var worldA:Vector3f = manifoldPoint.positionWorldOnA;
				var worldB:Vector3f = manifoldPoint.positionWorldOnB;
				var normalWorldB:Vector3f = manifoldPoint.normalWorldOnB;
				var dis:Float = manifoldPoint.distance1;
			
                // contact also becomes invalid when relative movement orthogonal to normal exceeds margin
				
				//var tmpProjectedDifference:Vector3f = new Vector3f();
				//var tmpProjectedPoint:Vector3f = new Vector3f();
                //tmp.scale2(manifoldPoint.distance1, manifoldPoint.normalWorldOnB);
                //tmpProjectedPoint.sub2(manifoldPoint.positionWorldOnA, tmp);
				//tmpProjectedDifference.sub2(manifoldPoint.positionWorldOnB, tmpProjectedPoint);
				//distance2d = tmpProjectedDifference.dot(tmpProjectedDifference);
				
				var differenceX:Float = worldB.x - (worldA.x - dis * normalWorldB.x);
				var differenceY:Float = worldB.y - (worldA.y - dis * normalWorldB.y);
				var differenceZ:Float = worldB.z - (worldA.z - dis * normalWorldB.z);
				
				distance2d = differenceX * differenceX + differenceY * differenceY + differenceZ * differenceZ;
                if (distance2d > BreakingThresholdSqrt) 
				{
                    removeContactPoint(i);
                }
				else
				{
                    // contact point processed callback
                    if (callback != null)
					{
                        callback.contactProcessed(manifoldPoint, body0, body1);
                    }
                }
            }
			
			i--;
        }
    }

    public function clearManifold():Void
	{
        for (i in 0...cachedPoints) 
		{
            clearUserCache(pointCache[i]);
        }
        cachedPoints = 0;
    }
	
}