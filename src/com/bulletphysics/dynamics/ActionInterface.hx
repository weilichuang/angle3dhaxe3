package com.bulletphysics.dynamics;
import com.bulletphysics.collision.dispatch.CollisionWorld;
import com.bulletphysics.linearmath.IDebugDraw;

/**
 * Basic interface to allow actions such as vehicles and characters to be
 * updated inside a {@link DynamicsWorld}.
 * 
 * @author weilichuang
 */
class ActionInterface
{

	public function new() 
	{
		
	}
	
	public function updateAction(collisionWorld:CollisionWorld, deltaTimeStep:Float):Void
	{
		
	}

    public function debugDraw(debugDrawer:IDebugDraw):Void
	{
		
	}
}