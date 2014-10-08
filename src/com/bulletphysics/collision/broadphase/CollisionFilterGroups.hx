package com.bulletphysics.collision.broadphase;

/**
 * Common collision filter groups.
 * @author weilichuang
 */
class CollisionFilterGroups
{
	public static inline var DEFAULT_FILTER:Int = 1;
    public static inline var STATIC_FILTER:Int = 2;
    public static inline var KINEMATIC_FILTER:Int = 4;
    public static inline var DEBRIS_FILTER:Int = 8;
    public static inline var SENSOR_TRIGGER:Int = 16;
    public static inline var CHARACTER_FILTER:Int = 32;
    public static inline var ALL_FILTER:Int = -1; // all bits sets: DefaultFilter | StaticFilter | KinematicFilter | DebrisFilter | SensorTrigger

	public function new() 
	{
		
	}
	
}