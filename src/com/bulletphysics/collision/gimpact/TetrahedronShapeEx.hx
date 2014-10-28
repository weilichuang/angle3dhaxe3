
package com.bulletphysics.collision.gimpact ;

import com.bulletphysics.collision.shapes.BU_Simplex1to4;
import vecmath.Vector3f;


/**
 * Helper class for tetrahedrons.
 *
 * @author weilichuang
 */
class TetrahedronShapeEx extends BU_Simplex1to4 
{

    public function new()
	{
		super();
		
        numVertices = 4;
        for (i in 0...numVertices)
		{
            vertices[i] = new Vector3f();
        }
    }

    public function setVertices(v0:Vector3f, v1:Vector3f, v2:Vector3f, v3:Vector3f):Void
	{
        vertices[0].fromVector3f(v0);
        vertices[1].fromVector3f(v1);
        vertices[2].fromVector3f(v2);
        vertices[3].fromVector3f(v3);
        recalcLocalAabb();
    }

}
