package org.angle3d.bullet.collision;
import com.bulletphysics.collision.narrowphase.ManifoldPoint;

/**
 * ...
 
 */
class PhysicsCollisionEventFactory
{
	private var eventBuffer:Array<PhysicsCollisionEvent> = [];
	private var size:Int = 0;

	public function new() 
	{
		
	}
	
	public inline function getEvent(type:Int, source:PhysicsCollisionObject, nodeB:PhysicsCollisionObject, cp:ManifoldPoint):PhysicsCollisionEvent
	{
		var event:PhysicsCollisionEvent;
		if (size > 0)
		{
			size--;
			event = eventBuffer[size];
			event.refactor(type, source, nodeB, cp);
		}
		else
		{
			event = new PhysicsCollisionEvent(type, source, nodeB, cp);
		}
		
		return event;
	}
	
	public inline function recycle(event:PhysicsCollisionEvent):Void
	{
		event.clean();
		eventBuffer[size] = event;
		size++;
	}
	
}