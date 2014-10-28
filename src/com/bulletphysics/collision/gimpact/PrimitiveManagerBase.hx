
package com.bulletphysics.collision.gimpact ;

import com.bulletphysics.collision.gimpact.BoxCollision.AABB;

/**
 * Prototype Base class for primitive classification.<p>
 * <p/>
 * This class is a wrapper for primitive collections.<p>
 * <p/>
 * This tells relevant info for the Bounding Box set classes, which take care of space classification.<p>
 * <p/>
 * This class can manage Compound shapes and trimeshes, and if it is managing trimesh then the
 * Hierarchy Bounding Box classes will take advantage of primitive Vs Box overlapping tests for
 * getting optimal results and less Per Box compairisons.
 *
 * @author weilichuang
 */
class PrimitiveManagerBase 
{

    /**
     * Determines if this manager consist on only triangles, which special case will be optimized.
     */
    public function is_trimesh():Bool
	{
		return false;
	}

    public function get_primitive_count():Int
	{
		return 0;
	}

    public function get_primitive_box( prim_index:Int, primbox:AABB):Void
	{
		
	}

    /**
     * Retrieves only the points of the triangle, and the collision margin.
     */
    public function get_primitive_triangle( prim_index:Int, triangle:PrimitiveTriangle):Void
	{
		
	}

}
