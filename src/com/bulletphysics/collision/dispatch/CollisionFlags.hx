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
    public static inline var STATIC_OBJECT:Int = 0x01;

    /**
     * Sets this collision object as kinematic.
     */
    public static inline var KINEMATIC_OBJECT:Int = 0x10;

    /**
     * Disables contact response.
     */
    public static inline var NO_CONTACT_RESPONSE:Int = 0x100;

    /**
     * Enables calling {@link ContactAddedCallback} for collision objects. This
     * allows per-triangle material (friction/restitution).
     */
    public static inline var CUSTOM_MATERIAL_CALLBACK:Int = 0x1000;

    public static inline var CHARACTER_OBJECT:Int = 0x10000;
	
	
	public static inline var KINEMATIC_STATIC_OBJECT:Int =  0x11;
}