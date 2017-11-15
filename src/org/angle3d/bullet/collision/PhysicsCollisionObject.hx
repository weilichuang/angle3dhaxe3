package org.angle3d.bullet.collision;
import org.angle3d.bullet.collision.shapes.CollisionShape;

/**
 * ...

 */
class PhysicsCollisionObject {
	public static inline var COLLISION_GROUP_NONE :Int = 0x00000000;
	public static inline var COLLISION_GROUP_01 :Int = 0x00000001;
	public static inline var COLLISION_GROUP_02 :Int = 0x00000002;
	public static inline var COLLISION_GROUP_03 :Int = 0x00000004;
	public static inline var COLLISION_GROUP_04 :Int = 0x00000008;
	public static inline var COLLISION_GROUP_05 :Int = 0x00000010;
	public static inline var COLLISION_GROUP_06 :Int = 0x00000020;
	public static inline var COLLISION_GROUP_07 :Int = 0x00000040;
	public static inline var COLLISION_GROUP_08 :Int = 0x00000080;
	public static inline var COLLISION_GROUP_09 :Int = 0x00000100;
	public static inline var COLLISION_GROUP_10 :Int = 0x00000200;
	public static inline var COLLISION_GROUP_11 :Int = 0x00000400;
	public static inline var COLLISION_GROUP_12 :Int = 0x00000800;
	public static inline var COLLISION_GROUP_13 :Int = 0x00001000;
	public static inline var COLLISION_GROUP_14 :Int = 0x00002000;
	public static inline var COLLISION_GROUP_15 :Int = 0x00004000;
	public static inline var COLLISION_GROUP_16 :Int = 0x00008000;

	private var collisionShape:CollisionShape;
	private var collisionGroup:Int = 0x00000001;
	private var collisionGroupsMask:Int = 0x00000001;
	private var userObject:Dynamic;

	public function new() {

	}

	/**
	 * Sets a CollisionShape to this physics object, note that the object should
	 * not be in the physics space when adding a new collision shape as it is rebuilt
	 * on the physics side.
	 * @param collisionShape the CollisionShape to set
	 */
	public function setCollisionShape(collisionShape:CollisionShape):Void {
		this.collisionShape = collisionShape;
	}

	/**
	 * @return the CollisionShape of this PhysicsNode, to be able to reuse it with
	 * other physics nodes (increases performance)
	 */
	public function getCollisionShape():CollisionShape {
		return collisionShape;
	}

	/**
	 * Returns the collision group for this collision shape
	 * @return
	 */
	public inline function getCollisionGroup():Int {
		return collisionGroup;
	}

	/**
	 * Sets the collision group number for this physics object. <br>
	 * The groups are integer bit masks and some pre-made variables are available in CollisionObject.
	 * All physics objects are by default in COLLISION_GROUP_01.<br>
	 * Two object will collide when <b>one</b> of the partys has the
	 * collisionGroup of the other in its collideWithGroups set.
	 * @param collisionGroup the collisionGroup to set
	 */
	public function setCollisionGroup(collisionGroup:Int):Void {
		this.collisionGroup = collisionGroup;
	}

	/**
	 * Add a group that this object will collide with.<br>
	 * Two object will collide when <b>one</b> of the partys has the
	 * collisionGroup of the other in its collideWithGroups set.<br>
	 * @param collisionGroup
	 */
	public function addCollideWithGroup(collisionGroup:Int):Void {
		this.collisionGroupsMask = this.collisionGroupsMask | collisionGroup;
	}

	/**
	 * Remove a group from the list this object collides with.
	 * @param collisionGroup
	 */
	public function removeCollideWithGroup(collisionGroup:Int):Void {
		this.collisionGroupsMask = this.collisionGroupsMask & ~collisionGroup;
	}

	/**
	 * Directly set the bitmask for collision groups that this object collides with.
	 * @param collisionGroups
	 */
	public function setCollideWithGroups(collisionGroups:Int):Void {
		this.collisionGroupsMask = collisionGroups;
	}

	/**
	 * Gets the bitmask of collision groups that this object collides with.
	 * @return
	 */
	public inline function getCollideWithGroups():Int {
		return collisionGroupsMask;
	}

	/**
	 * @return the userObject
	 */
	public inline function getUserObject():Dynamic {
		return userObject;
	}

	/**
	 * @param userObject the userObject to set
	 */
	public function setUserObject(userObject:Dynamic):Void {
		this.userObject = userObject;
	}

	public function toString():String {
		if (this.userObject != null)
			return Std.string(this.userObject);
		else
			return Std.string(PhysicsCollisionObject);
	}
}