package org.angle3d.renderer;


/**
 * The <code>FrustumIntersect</code> enum is returned as a result
 * of a culling check operation,
 * see {@link #contains(org.angle3d.bounding.BoundingVolume) }
 */
@:final class FrustumIntersect
{
	/**
	 * defines a constant assigned to spatials that are completely outside
	 * of this camera's view frustum.
	 */
	public static inline var Outside:Int = 0;
	/**
	 * defines a constant assigned to spatials that are completely inside
	 * the camera's view frustum.
	 */
	public static inline var Inside:Int = 1;
	/**
	 * defines a constant assigned to spatials that are intersecting one of
	 * the six planes that define the view frustum.
	 */
	public static inline var Intersects:Int = 2;
}


