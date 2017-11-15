package org.angle3d.bullet;

/**

 */

@:enum abstract BroadphaseType(Int) {
	/**
	 * basic Broadphase
	 */
	var SIMPLE = 0;
	/**
	 * better Broadphase, needs worldBounds , max Object number = 16384
	 */
	var AXIS_SWEEP_3 = 1;
	/**
	 * better Broadphase, needs worldBounds , max Object number = 65536
	 */
	var AXIS_SWEEP_3_32 = 2;
	/**
	 * Broadphase allowing quicker adding/removing of physics objects
	 */
	var DBVT = 3;
}