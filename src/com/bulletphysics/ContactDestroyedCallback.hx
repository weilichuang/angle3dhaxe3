package com.bulletphysics;

/**
 * Called when contact has been destroyed between two collision objects.
 * @author weilichuang
 */
class ContactDestroyedCallback
{
	public function new()
	{
		
	}

	public function contactDestroyed(userPersistentData:Dynamic):Bool
	{
		return false;
	}
	
}