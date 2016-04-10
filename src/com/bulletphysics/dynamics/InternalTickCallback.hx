package com.bulletphysics.dynamics;

/**
 * ...
 
 */
interface InternalTickCallback
{
	function internalTick(world:DynamicsWorld, timeStep:Float):Void;
}