package org.angle3d.bullet.collision;
import org.angle3d.animation.Bone;

/**
 
 */

interface RagdollCollisionListener 
{
	function collide(bone:Bone, object:PhysicsCollisionObject, event:PhysicsCollisionEvent):Void;
}