package org.angle3d.bullet.collision;
import org.angle3d.math.Vector3f;

/**
 * Contains the results of a PhysicsSpace rayTest

 */
class PhysicsSweepTestResult {
	private var collisionObject:PhysicsCollisionObject;
	private var hitNormalLocal:Vector3f;
	private var hitFraction:Float;
	private var normalInWorldSpace:Bool;

	public function new(collisionObject:PhysicsCollisionObject, hitNormalLocal:Vector3f,
						hitFraction:Float,normalInWorldSpace:Bool) {
		this.collisionObject = collisionObject;
		this.hitNormalLocal = hitNormalLocal;
		this.hitFraction = hitFraction;
		this.normalInWorldSpace = normalInWorldSpace;
	}

	/**
	 * @return the PhysicsObject the ray collided with
	 */
	public function getCollisionObject():PhysicsCollisionObject {
		return collisionObject;
	}

	/**
	 * @return the normal of the collision in the objects local space
	 */
	public function getHitNormalLocal():Vector3f {
		return hitNormalLocal;
	}

	/**
	 * The hitFraction is the fraction of the ray length (yeah, I know) at which the collision occurred.
	 * If e.g. the raytest was from 0,0,0 to 0,6,0 and the hitFraction is 0.5 then the collision occurred at 0,3,0
	 * @return the hitFraction
	 */
	public function getHitFraction():Float {
		return hitFraction;
	}

	/**
	 * @return the normalInWorldSpace
	 */
	public function isNormalInWorldSpace():Bool {
		return normalInWorldSpace;
	}

	public function fill(collisionObject:PhysicsCollisionObject, hitNormalLocal:Vector3f,
						 hitFraction:Float, normalInWorldSpace:Bool):Void {
		this.collisionObject = collisionObject;
		this.hitNormalLocal = hitNormalLocal;
		this.hitFraction = hitFraction;
		this.normalInWorldSpace = normalInWorldSpace;
	}
}