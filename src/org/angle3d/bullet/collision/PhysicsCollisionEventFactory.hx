package org.angle3d.bullet.collision;
import com.bulletphysics.collision.narrowphase.ManifoldPoint;

/**
 * ...
 * @author weilichuang
 */
class PhysicsCollisionEventFactory
{
	private var eventBuffer:Array<PhysicsCollisionEvent> = [];

	public function new() 
	{
		
	}
	
	public function getEvent(type:Int, source:PhysicsCollisionObject, nodeB:PhysicsCollisionObject, cp:ManifoldPoint):PhysicsCollisionEvent
	{
		var event:PhysicsCollisionEvent;
		if (eventBuffer.length > 0)
		{
			event = eventBuffer.pop();
			event.refactor(type, source, nodeB, cp);
		}
		else
		{
			event = new PhysicsCollisionEvent(type, source, nodeB, cp);
		}
		
		return event;
	}
	
	public function recycle(event:PhysicsCollisionEvent):Void
	{
		event.clean();
		eventBuffer.push(event);
	}
	
}