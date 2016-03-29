package com.bulletphysics.collision.dispatch;

/**
 * ...
 * @author weilichuang
 */
@:enum abstract CollisionObjectType(Int)    
{
	var COLLISION_OBJECT = 0; // =1
    var RIGID_BODY = 1;
    // CO_GHOST_OBJECT keeps track of all objects overlapping its AABB and that pass its collision filter
    // It is useful for collision sensors, explosion objects, character controller etc.
    var GHOST_OBJECT = 2;
    var SOFT_BODY = 3;
}