package org.angle3d.bullet.collision;

/**
 * Interface for Objects that want to be informed about collision events in the physics space
 */
interface PhysicsCollisionListener {
	/**
	 * Called when a collision happened in the PhysicsSpace, <i>called from render thread</i>.
	 *
	 * Do not store the event object as it will be cleared after the method has finished.
	 * @param event the CollisionEvent
	 */
	function collision(event:PhysicsCollisionEvent):Void;
}