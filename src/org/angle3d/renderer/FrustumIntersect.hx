package org.angle3d.renderer;


/**
 * The <code>FrustumIntersect</code> enum is returned as a result
 * of a culling check operation,
 * see {@link #contains(org.angle3d.bounding.BoundingVolume) }
 */
enum FrustumIntersect
{
	/**
	 * defines a constant assigned to spatials that are completely outside
	 * of this camera's view frustum.
	 */
	Outside;
	/**
	 * defines a constant assigned to spatials that are completely inside
	 * the camera's view frustum.
	 */
	Inside;
	/**
	 * defines a constant assigned to spatials that are intersecting one of
	 * the six planes that define the view frustum.
	 */
	Intersects;
}


