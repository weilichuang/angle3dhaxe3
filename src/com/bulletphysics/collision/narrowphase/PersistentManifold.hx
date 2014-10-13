package com.bulletphysics.collision.narrowphase;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.VectorUtil;
import com.bulletphysics.util.Assert;
import vecmath.Vector3f;
import vecmath.Vector4f;

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
 * @author weilichuang
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
		pointCache = [];
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

    /// sort cached points so most isolated points come first
    private function sortCachedPoints(pt:ManifoldPoint):Int
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
            var a0:Vector3f = pt.localPointA.clone();
            a0.sub(pointCache[1].localPointA);

            var b0:Vector3f = pointCache[3].localPointA.clone();
            b0.sub(pointCache[2].localPointA);

            var cross:Vector3f = new Vector3f();
            cross.cross(a0, b0);

            res0 = cross.lengthSquared();
        }

        if (maxPenetrationIndex != 1)
		{
            var a1:Vector3f = pt.localPointA.clone();
            a1.sub(pointCache[0].localPointA);

            var b1:Vector3f = pointCache[3].localPointA.clone();
            b1.sub(pointCache[2].localPointA);

            var cross:Vector3f = new Vector3f();
            cross.cross(a1, b1);
            res1 = cross.lengthSquared();
        }

        if (maxPenetrationIndex != 2)
		{
            var a2:Vector3f = pt.localPointA.clone();
            a2.sub(pointCache[0].localPointA);

            var b2:Vector3f = pointCache[3].localPointA.clone();
            b2.sub(pointCache[1].localPointA);

            var cross:Vector3f = new Vector3f();
            cross.cross(a2, b2);

            res2 = cross.lengthSquared();
        }

        if (maxPenetrationIndex != 3) 
		{
            var a3:Vector3f = pt.localPointA.clone();
            a3.sub(pointCache[0].localPointA);

            var b3:Vector3f = pointCache[2].localPointA.clone();
            b3.sub(pointCache[1].localPointA);

            var cross:Vector3f = new Vector3f();
            cross.cross(a3, b3);
            res3 = cross.lengthSquared();
        }

        var maxvec:Vector4f = new Vector4f();
        maxvec.setTo(res0, res1, res2, res3);
        var biggestarea:Int = VectorUtil.closestAxis4(maxvec);
        return biggestarea;
    }

    //private int findContactPoint(ManifoldPoint unUsed, int numUnused, ManifoldPoint pt);

    public function getBody0():Dynamic
	{
        return body0;
    }

    public function getBody1():Dynamic 
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

            if (pt.userPersistentData != null && BulletGlobals.gContactDestroyedCallback != null)
			{
                BulletGlobals.gContactDestroyedCallback.contactDestroyed(pt.userPersistentData);
                pt.userPersistentData = null;
            }

//#ifdef DEBUG_PERSISTENCY
//			DebugPersistency();
//#endif
        }
    }

    public function getNumContacts():Int
	{
        return cachedPoints;
    }

    public function getContactPoint(index:Int):ManifoldPoint
	{
        return pointCache[index];
    }

    // todo: get this margin from the current physics / collision environment
    public function getContactBreakingThreshold():Float
	{
        return BulletGlobals.contactBreakingThreshold;
    }

    public function getCacheEntry(newPoint:ManifoldPoint):Int
	{
        var shortestDist:Float = getContactBreakingThreshold() * getContactBreakingThreshold();
        var size:Int = getNumContacts();
        var nearestPoint:Int = -1;
        var diffA:Vector3f = new Vector3f();
        for (i in 0...size)
		{
            var mp:ManifoldPoint = pointCache[i];

            diffA.sub(mp.localPointA, newPoint.localPointA);

            var distToManiPoint:Float = diffA.dot(diffA);
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
        Assert.assert (validContactDistance(newPoint));

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
        Assert.assert (pointCache[insertIndex].userPersistentData == null);
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
        Assert.assert (validContactDistance(newPoint));

//#define MAINTAIN_PERSISTENCY 1
//#ifdef MAINTAIN_PERSISTENCY
        var lifeTime:Int = pointCache[insertIndex].getLifeTime();
        var appliedImpulse:Float = pointCache[insertIndex].appliedImpulse;
        var appliedLateralImpulse1:Float = pointCache[insertIndex].appliedImpulseLateral1;
        var appliedLateralImpulse2:Float = pointCache[insertIndex].appliedImpulseLateral2;

        Assert.assert (lifeTime >= 0);
        var cache:Dynamic = pointCache[insertIndex].userPersistentData;

        pointCache[insertIndex].set(newPoint);

        pointCache[insertIndex].userPersistentData = cache;
        pointCache[insertIndex].appliedImpulse = appliedImpulse;
        pointCache[insertIndex].appliedImpulseLateral1 = appliedLateralImpulse1;
        pointCache[insertIndex].appliedImpulseLateral2 = appliedLateralImpulse2;

        pointCache[insertIndex].lifeTime = lifeTime;
//#else
//		clearUserCache(m_pointCache[insertIndex]);
//		m_pointCache[insertIndex] = newPoint;
//#endif
    }

    private function validContactDistance(pt:ManifoldPoint):Bool
	{
        return pt.distance1 <= getContactBreakingThreshold();
    }

    /// calculated new worldspace coordinates and depth, and reject points that exceed the collision margin
    public function refreshContactPoints(trA:Transform, trB:Transform):Void
	{
        var tmp:Vector3f = new Vector3f();
        var i:Int;
//#ifdef DEBUG_PERSISTENCY
//	printf("refreshContactPoints posA = (%f,%f,%f) posB = (%f,%f,%f)\n",
//		trA.getOrigin().getX(),
//		trA.getOrigin().getY(),
//		trA.getOrigin().getZ(),
//		trB.getOrigin().getX(),
//		trB.getOrigin().getY(),
//		trB.getOrigin().getZ());
//#endif //DEBUG_PERSISTENCY
        // first refresh worldspace positions and distance
		
		i = getNumContacts() - 1; 
        while (i >= 0)
		{
            var manifoldPoint:ManifoldPoint = pointCache[i];

            manifoldPoint.positionWorldOnA.fromVector3f(manifoldPoint.localPointA);
            trA.transform(manifoldPoint.positionWorldOnA);

            manifoldPoint.positionWorldOnB.fromVector3f(manifoldPoint.localPointB);
            trB.transform(manifoldPoint.positionWorldOnB);

            tmp.fromVector3f(manifoldPoint.positionWorldOnA);
            tmp.sub(manifoldPoint.positionWorldOnB);
            manifoldPoint.distance1 = tmp.dot(manifoldPoint.normalWorldOnB);

            manifoldPoint.lifeTime++;
			
			i--;
        }

        // then
        var distance2d:Float;
        var projectedDifference:Vector3f = new Vector3f();
		var projectedPoint:Vector3f = new Vector3f();

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
                // contact also becomes invalid when relative movement orthogonal to normal exceeds margin
                tmp.scale(manifoldPoint.distance1, manifoldPoint.normalWorldOnB);
                projectedPoint.sub(manifoldPoint.positionWorldOnA, tmp);
                projectedDifference.sub(manifoldPoint.positionWorldOnB, projectedPoint);
                distance2d = projectedDifference.dot(projectedDifference);
                if (distance2d > getContactBreakingThreshold() * getContactBreakingThreshold()) 
				{
                    removeContactPoint(i);
                }
				else
				{
                    // contact point processed callback
                    if (BulletGlobals.gContactProcessedCallback != null) {
                        BulletGlobals.gContactProcessedCallback.contactProcessed(manifoldPoint, body0, body1);
                    }
                }
            }
			
			i--;
        }
//#ifdef DEBUG_PERSISTENCY
//	DebugPersistency();
//#endif //
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