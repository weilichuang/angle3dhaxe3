package com.bulletphysics.collision.dispatch;
import com.bulletphysics.collision.broadphase.BroadphaseNativeType;

/**
 * ...
 * @author weilichuang
 */
class CollisionConfiguration
{

	public function new() 
	{
		
	}
	
	public function getCollisionAlgorithmCreateFunc(proxyType0:BroadphaseNativeType, proxyType1:BroadphaseNativeType):CollisionAlgorithmCreateFunc
	{
		return null;
	}
	
}