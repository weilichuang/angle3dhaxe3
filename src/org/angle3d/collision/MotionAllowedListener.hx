package org.angle3d.collision;

import org.angle3d.math.Vector3f;

/**
 * andy
 
 */

interface MotionAllowedListener
{

	/**
	 * Check if motion allowed. Modify position and velocity vectors
	 * appropriately if not allowed..
	 *
	 * @param position
	 * @param velocity
	 */
	function checkMotionAllowed(position:Vector3f, velocity:Vector3f):Void;

}

