
package com.bulletphysics.collision.gimpact ;

import com.bulletphysics.collision.shapes.BU_Simplex1to4;
import angle3d.math.Vector3f;


/**
 * Helper class for tetrahedrons.
 *
 
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
        vertices[0].copyFrom(v0);
        vertices[1].copyFrom(v1);
        vertices[2].copyFrom(v2);
        vertices[3].copyFrom(v3);
        recalcLocalAabb();
    }

}
