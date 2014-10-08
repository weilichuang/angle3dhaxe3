package com.bulletphysics.collision.dispatch;

/**
 * ...
 * @author weilichuang
 */
class CollisionFlags
{
	/**
     * Sets this collision object as static.
     */
    public static inline var STATIC_OBJECT:Int = 1;

    /**
     * Sets this collision object as kinematic.
     */
    public static inline var KINEMATIC_OBJECT:Int = 2;

    /**
     * Disables contact response.
     */
    public static inline var NO_CONTACT_RESPONSE:Int = 4;

    /**
     * Enables calling {@link ContactAddedCallback} for collision objects. This
     * allows per-triangle material (friction/restitution).
     */
    public static inline var CUSTOM_MATERIAL_CALLBACK:Int = 8;

    public static inline var CHARACTER_OBJECT:Int = 16;
}