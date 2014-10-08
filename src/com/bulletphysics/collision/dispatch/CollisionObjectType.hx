package com.bulletphysics.collision.dispatch;

/**
 * ...
 * @author weilichuang
 */
enum CollisionObjectType
{
	COLLISION_OBJECT; // =1
    RIGID_BODY;
    // CO_GHOST_OBJECT keeps track of all objects overlapping its AABB and that pass its collision filter
    // It is useful for collision sensors, explosion objects, character controller etc.
    GHOST_OBJECT;
    SOFT_BODY;
}