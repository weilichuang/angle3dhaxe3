package org.angle3d.bullet.collision;

/**

 */

interface PhysicsCollisionGroupListener {
	/**
	 * Called when two physics objects of the registered group are about to collide, <i>called from physics thread</i>.<br>
	 * This is only called when the collision will happen based on the collisionGroup and collideWithGroups
	 * settings in the PhysicsCollisionObject. That is the case when <b>one</b> of the partys has the
	 * collisionGroup of the other in its collideWithGroups set.<br>
	 * @param nodeA CollisionObject #1
	 * @param nodeB CollisionObject #2
	 * @return true if the collision should happen, false otherwise
	 */
	function collide(nodeA:PhysicsCollisionObject, nodeB:PhysicsCollisionObject):Bool;
}