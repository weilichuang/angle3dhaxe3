package com.bulletphysics.collision.dispatch;
import com.bulletphysics.collision.narrowphase.PersistentManifold;
import com.bulletphysics.util.ObjectArrayList;

/**
 
 */
interface IslandCallback 
{
	function processIsland( bodies:ObjectArrayList<CollisionObject>, numBodies:Int, 
									manifolds:ObjectArrayList<PersistentManifold>, manifolds_offset:Int, 
									numManifolds:Int, islandId:Int):Void;
}