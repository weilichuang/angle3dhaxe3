package com.bulletphysics.collision.broadphase;
import com.vecmath.Vector3f;

/**
 * ...
 * @author weilichuang
 */
class SimpleBroadphaseProxy extends BroadphaseProxy
{
	public var min:Vector3f = new Vector3f();
	public var max:Vector3f = new Vector3f();
	
	
	public function new(minpt:Vector3f, maxpt:Vector3f, shapeType:BroadphaseNativeType, userPtr:Dynamic, collisionFilterGroup:Int, collisionFilterMask:Int, multiSapParentProxy:Dynamic = null) 
	{
		super();
		
		this.init(userPtr, collisionFilterGroup, collisionFilterMask, multiSapParentProxy);
		this.min.fromVector3f(minpt);
		this.max.fromVector3f(maxpt);
	}
	
}