package org.angle3d.bullet;

/**
 * @author weilichuang
 */

enum BroadphaseType 
{
	/**
	 * basic Broadphase
	 */
	SIMPLE;
	/**
	 * better Broadphase, needs worldBounds , max Object number = 16384
	 */
	AXIS_SWEEP_3;
	/**
	 * better Broadphase, needs worldBounds , max Object number = 65536
	 */
	AXIS_SWEEP_3_32;
	/**
	 * Broadphase allowing quicker adding/removing of physics objects
	 */
	DBVT;
}