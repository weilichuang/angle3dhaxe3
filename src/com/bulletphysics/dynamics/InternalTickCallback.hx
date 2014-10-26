package com.bulletphysics.dynamics;

/**
 * ...
 * @author weilichuang
 */
interface InternalTickCallback
{
	function internalTick(world:DynamicsWorld, timeStep:Float):Void;
}