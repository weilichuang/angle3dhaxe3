package com.bulletphysics.collision.broadphase;
import vecmath.Vector3f;

/**
 * BroadphaseInterface for AABB overlapping object pairs.
 * @author weilichuang
 */
class BroadphaseInterface
{

	public function new() 
	{
		
	}
	
	public function createProxy( aabbMin:Vector3f, aabbMax:Vector3f, shapeType:BroadphaseNativeType, userPtr:Dynamic, collisionFilterGroup:Int, collisionFilterMask:Int, dispatcher:Dispatcher, multiSapProxy:Dynamic):BroadphaseProxy
	{
		return null;
	}

    public function destroyProxy(proxy:BroadphaseProxy,dispatcher:Dispatcher):Void
	{
		
	}

    public function setAabb(proxy:BroadphaseProxy, aabbMin:Vector3f, aabbMax:Vector3f, dispatcher:Dispatcher):Void
	{
		
	}

    ///calculateOverlappingPairs is optional: incremental algorithms (sweep and prune) might do it during the set aabb
    public function calculateOverlappingPairs(dispatcher:Dispatcher):Void
	{
		
	}

    public function getOverlappingPairCache():OverlappingPairCache
	{
		return null;
	}

    ///getAabb returns the axis aligned bounding box in the 'global' coordinate frame
    ///will add some transform later
    public function getBroadphaseAabb(aabbMin:Vector3f, aabbMax:Vector3f):Void
	{
		
	}

    public function printStats():Void
	{
		
	}
	
}