package com.bulletphysics.collision.broadphase;
import com.vecmath.Vector3f;

/**
 * BroadphaseInterface for AABB overlapping object pairs.
 * @author weilichuang
 */
interface BroadphaseInterface
{
	function createProxy( aabbMin:Vector3f, aabbMax:Vector3f, shapeType:BroadphaseNativeType, userPtr:Dynamic, collisionFilterGroup:Int, collisionFilterMask:Int, dispatcher:Dispatcher, multiSapProxy:Dynamic):BroadphaseProxy;

    function destroyProxy(proxy:BroadphaseProxy, dispatcher:Dispatcher):Void;

    function setAabb(proxy:BroadphaseProxy, aabbMin:Vector3f, aabbMax:Vector3f, dispatcher:Dispatcher):Void;

    ///calculateOverlappingPairs is optional: incremental algorithms (sweep and prune) might do it during the set aabb
    function calculateOverlappingPairs(dispatcher:Dispatcher):Void;

    function getOverlappingPairCache():OverlappingPairCache;

    ///getAabb returns the axis aligned bounding box in the 'global' coordinate frame
    ///will add some transform later
    function getBroadphaseAabb(aabbMin:Vector3f, aabbMax:Vector3f):Void;

    function printStats():Void;
}