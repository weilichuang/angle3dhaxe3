package org.angle3d.cinematic.events;


/**
 * Enum for the different type of target_direction behavior
 */
class DirectionType
{
	/**
	 * the target_stay in the starting direction
	 */
	public static inline var None:Int = 0;
	/**
	 * The target_rotates with the direction of the path
	 */
	public static inline var Path:Int = 1;
	/**
	 * The target_rotates with the direction of the path but with the additon of a rtotation
	 * you need to use the setRotation mathod when using this Direction
	 */
	public static inline var PathAndRotation:Int = 2;
	/**
	 * The target_rotates with the given rotation
	 */
	public static inline var Rotation:Int = 3;
	/**
	 * The target_looks at a point
	 * You need to use the setLookAt method when using this direction
	 */
	public static inline var LookAt:Int = 4;
}

