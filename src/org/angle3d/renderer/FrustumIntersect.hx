package org.angle3d.renderer;


/**
 * The `FrustumIntersect` enum is returned as a result
 * of a culling check operation,
 */
@:enum abstract FrustumIntersect(Int)  
{
	/**
	 * defines a constant assigned to spatials that are completely outside
	 * of this camera's view frustum.
	 */
	var Outside = 0;
	/**
	 * defines a constant assigned to spatials that are completely inside
	 * the camera's view frustum.
	 */
	var Inside = 1;
	/**
	 * defines a constant assigned to spatials that are intersecting one of
	 * the six planes that define the view frustum.
	 */
	var Intersects = 2;
}


