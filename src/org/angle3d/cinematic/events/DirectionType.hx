package org.angle3d.cinematic.events;


/**
 * Enum for the different type of target_direction behavior
 */
@:enum abstract DirectionType(Int)   
{
	/**
	 * the target_stay in the starting direction
	 */
	var None:DirectionType = 0;
	/**
	 * The target_rotates with the direction of the path
	 */
	var Path:DirectionType = 1;
	/**
	 * The target_rotates with the direction of the path but with the additon of a rtotation
	 * you need to use the setRotation mathod when using this Direction
	 */
	var PathAndRotation:DirectionType = 2;
	/**
	 * The target_rotates with the given rotation
	 */
	var Rotation:DirectionType = 3;
	/**
	 * The target_looks at a point
	 * You need to use the setLookAt method when using this direction
	 */
	var LookAt:DirectionType = 4;
}

