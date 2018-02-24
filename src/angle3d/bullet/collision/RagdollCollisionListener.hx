package angle3d.bullet.collision;
import angle3d.animation.Bone;

/**
 */
interface RagdollCollisionListener {
	function collide(bone:Bone, object:PhysicsCollisionObject, event:PhysicsCollisionEvent):Void;
}