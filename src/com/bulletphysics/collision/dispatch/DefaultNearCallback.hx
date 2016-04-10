package com.bulletphysics.collision.dispatch;
import com.bulletphysics.collision.broadphase.BroadphasePair;
import com.bulletphysics.collision.broadphase.DispatcherInfo;
import com.bulletphysics.collision.broadphase.DispatchFunc;

/**
 * Default implementation of {NearCallback}.
 
 */
class DefaultNearCallback implements NearCallback
{
	private var contactPointResult:ManifoldResult = new ManifoldResult();
	
	public function new()
	{
		
	}

    public inline function handleCollision(collisionPair:BroadphasePair, dispatcher:CollisionDispatcher, dispatchInfo:DispatcherInfo):Void
	{
        var colObj0:CollisionObject = cast collisionPair.pProxy0.clientObject;
        var colObj1:CollisionObject = cast collisionPair.pProxy1.clientObject;

        if (dispatcher.needsCollision(colObj0, colObj1)) 
		{
            // dispatcher will keep algorithms persistent in the collision pair
            if (collisionPair.algorithm == null) 
			{
                collisionPair.algorithm = dispatcher.findAlgorithm(colObj0, colObj1);
            }

            if (collisionPair.algorithm != null)
			{
                //ManifoldResult contactPointResult = new ManifoldResult(colObj0, colObj1);
                contactPointResult.init(colObj0, colObj1);

                if (dispatchInfo.dispatchFunc == DispatchFunc.DISPATCH_DISCRETE) 
				{
                    // discrete collision detection query
                    collisionPair.algorithm.processCollision(colObj0, colObj1, dispatchInfo, contactPointResult);
                } 
				else
				{
                    // continuous collision detection query, time of impact (toi)
                    var toi:Float = collisionPair.algorithm.calculateTimeOfImpact(colObj0, colObj1, dispatchInfo, contactPointResult);
                    if (dispatchInfo.timeOfImpact > toi) 
					{
                        dispatchInfo.timeOfImpact = toi;
                    }
                }
            }
        }
    }
	
}