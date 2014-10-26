package com.bulletphysics;

/**
 * Called when contact has been destroyed between two collision objects.
 * @author weilichuang
 */
interface ContactDestroyedCallback
{
	function contactDestroyed(userPersistentData:Dynamic):Bool;
}