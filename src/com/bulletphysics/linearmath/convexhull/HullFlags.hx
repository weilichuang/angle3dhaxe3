package com.bulletphysics.linearmath.convexhull;

/**
 * Flags that affects convex hull generation, used in {@link HullDesc#flags}.
 * @author weilichuang
 */
class HullFlags
{
	public static inline var TRIANGLES:Int = 1; // report results as triangles, not polygons.
    public static inline var REVERSE_ORDER:Int = 2; // reverse order of the triangle indices.
    public static inline var DEFAULT:Int = 1;
}