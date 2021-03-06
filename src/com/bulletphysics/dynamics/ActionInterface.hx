package com.bulletphysics.dynamics;
import com.bulletphysics.collision.dispatch.CollisionWorld;
import com.bulletphysics.linearmath.IDebugDraw;

/**
 * Basic interface to allow actions such as vehicles and characters to be
 * updated inside a {DynamicsWorld}.
 * 
 
 */
interface ActionInterface
{
	function updateAction(collisionWorld:CollisionWorld, deltaTimeStep:Float):Void;

    function debugDraw(debugDrawer:IDebugDraw):Void;
}