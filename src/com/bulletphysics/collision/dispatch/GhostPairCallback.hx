package com.bulletphysics.collision.dispatch;

import com.bulletphysics.collision.broadphase.BroadphasePair;
import com.bulletphysics.collision.broadphase.BroadphaseProxy;
import com.bulletphysics.collision.broadphase.Dispatcher;
import com.bulletphysics.collision.broadphase.OverlappingPairCallback;
import de.polygonal.ds.error.Assert;

/**
 * GhostPairCallback interfaces and forwards adding and removal of overlapping
 * pairs from the {@link BroadphaseInterface} to {@link GhostObject}.
 * @author weilichuang
 */
class GhostPairCallback extends OverlappingPairCallback
{

	public function new() 
	{
		super();
		
	}
	
	override public function addOverlappingPair(proxy0:BroadphaseProxy, proxy1:BroadphaseProxy):BroadphasePair
	{
        var colObj0:CollisionObject = cast proxy0.clientObject;
        var colObj1:CollisionObject = cast proxy1.clientObject;
        var ghost0:GhostObject = GhostObject.upcast(colObj0);
        var ghost1:GhostObject = GhostObject.upcast(colObj1);

        if (ghost0 != null)
		{
            ghost0.addOverlappingObjectInternal(proxy1, proxy0);
        }
        if (ghost1 != null) 
		{
            ghost1.addOverlappingObjectInternal(proxy0, proxy1);
        }
        return null;
    }

    override public function removeOverlappingPair(proxy0:BroadphaseProxy, proxy1:BroadphaseProxy, dispatcher:Dispatcher):Dynamic
	{
        var colObj0:CollisionObject = cast proxy0.clientObject;
        var colObj1:CollisionObject = cast proxy1.clientObject;
        var ghost0:GhostObject = GhostObject.upcast(colObj0);
        var ghost1:GhostObject = GhostObject.upcast(colObj1);

        if (ghost0 != null)
		{
            ghost0.removeOverlappingObjectInternal(proxy1, dispatcher, proxy0);
        }
        if (ghost1 != null)
		{
            ghost1.removeOverlappingObjectInternal(proxy0, dispatcher, proxy1);
        }
        return null;
    }

    override public function removeOverlappingPairsContainingProxy(proxy0:BroadphaseProxy, dispatcher:Dispatcher):Void
	{
        Assert.assert (false);

        // need to keep track of all ghost objects and call them here
        // hashPairCache.removeOverlappingPairsContainingProxy(proxy0, dispatcher);
    }
}