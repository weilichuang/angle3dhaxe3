package com.bulletphysics.collision.dispatch;

@:enum abstract CollisionFlags(Int) 
{
	/**
     * Sets this collision object as static.
     */
    var STATIC_OBJECT = 1 << 0;

    /**
     * Sets this collision object as kinematic.
     */
    var KINEMATIC_OBJECT = 1 << 1;

    /**
     * Disables contact response.
     */
    var NO_CONTACT_RESPONSE = 1 << 2;

    /**
     * Enables calling {ContactAddedCallback} for collision objects. This
     * allows per-triangle material (friction/restitution).
     */
    var CUSTOM_MATERIAL_CALLBACK = 1 << 3;

    var CHARACTER_OBJECT = 1 << 4;
	
	var KINEMATIC_STATIC_OBJECT =  1 << 0 | 1 << 1;
	
	public inline function new(v:Int)
        this = v;

    public inline function toInt():Int
    	return this;
	
	inline public function remove(mask:CollisionFlags):CollisionFlags
	{
		return new CollisionFlags(this & ~mask.toInt());
	}
    
	inline public function add(mask:CollisionFlags):CollisionFlags
	{
		return new CollisionFlags(this | mask.toInt());
	}
    
	inline public function contains(mask:CollisionFlags):Bool
	{
		return this & mask.toInt() != 0;
	}
}