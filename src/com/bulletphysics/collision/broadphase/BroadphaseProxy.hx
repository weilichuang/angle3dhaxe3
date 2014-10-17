package com.bulletphysics.collision.broadphase;

/**
 * BroadphaseProxy is the main class that can be used with the Bullet broadphases.
 * It stores collision shape type information, collision filter information and
 * a client object, typically a {@link CollisionObject} or {@link RigidBody}.
 *
 * @author weilichuang
 */
class BroadphaseProxy
{
	// Usually the client CollisionObject or Rigidbody class
	public var clientObject:Dynamic;
	
	public var collisionFilterGroup:Int;
	public var collisionFilterMask:Int;
	
	public var multiSapParentProxy:Dynamic;
	
	// uniqueId is introduced for paircache. could get rid of this, by calculating the address offset etc.
	public var uniqueId:Int;
	
	public function new(userPtr:Dynamic, collisionFilterGroup:Int, collisionFilterMask:Int, multiSapParentProxy:Dynamic = null)
	{
		this.clientObject = userPtr;
		this.collisionFilterGroup = collisionFilterGroup;
		this.collisionFilterMask = collisionFilterMask;
		this.multiSapParentProxy = multiSapParentProxy;
	}
	
	public inline function getUid():Int
	{
		return uniqueId;
	}
	
}