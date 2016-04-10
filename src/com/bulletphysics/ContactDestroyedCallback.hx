package com.bulletphysics;

/**
 * Called when contact has been destroyed between two collision objects.
 
 */
interface ContactDestroyedCallback
{
	function contactDestroyed(userPersistentData:Dynamic):Bool;
}