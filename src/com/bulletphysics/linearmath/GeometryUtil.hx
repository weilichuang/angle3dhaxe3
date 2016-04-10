package com.bulletphysics.linearmath;
import com.bulletphysics.util.ObjectArrayList;
import org.angle3d.math.Vector3f;
import org.angle3d.math.Vector4f;

/**
 * GeometryUtil helper class provides a few methods to convert between plane
 * equations and vertices.
 
 */
class GeometryUtil
{

	public static function isPointInsidePlanes(planeEquations:ObjectArrayList<Vector4f>, point:Vector3f, margin:Float):Bool
	{
        var numbrushes:Int = planeEquations.size();
        for (i in 0...numbrushes)
		{
            var N1:Vector4f = planeEquations.getQuick(i);
            var dist:Float = LinearMathUtil.dot3(N1, point) + N1.w - margin;
            if (dist > 0)
			{
                return false;
            }
        }
        return true;
    }

    public static function areVerticesBehindPlane(planeNormal:Vector4f, vertices:ObjectArrayList<Vector3f>, margin:Float):Bool
	{
        var numvertices:Int = vertices.size();
        for (i in 0...numvertices)
		{
            var N1:Vector3f = vertices.getQuick(i);
            var dist:Float = LinearMathUtil.dot3(planeNormal, N1) + planeNormal.w - margin;
            if (dist > 0)
			{
                return false;
            }
        }
        return true;
    }

    private static function notExist(planeEquation:Vector4f, planeEquations:ObjectArrayList<Vector4f>):Bool
	{
        var numbrushes:Int = planeEquations.size();
        for (i in 0...numbrushes)
		{
            var N1:Vector4f = planeEquations.getQuick(i);
            if (LinearMathUtil.dot3(planeEquation, N1) > 0.999)
			{
                return false;
            }
        }
        return true;
    }

    public static function getPlaneEquationsFromVertices(vertices:ObjectArrayList<Vector3f>, planeEquationsOut:ObjectArrayList<Vector4f>):Void
	{
        var planeEquation:Vector4f = new Vector4f();
        var edge0:Vector3f = new Vector3f();
		var edge1:Vector3f = new Vector3f();
        var tmp:Vector3f = new Vector3f();

        var numvertices:Int = vertices.size();
        // brute force:
        for (i in 0...numvertices)
		{
            var N1:Vector3f = vertices.getQuick(i);

            for (j in i + 1...numvertices)
			{
                var N2:Vector3f = vertices.getQuick(j);

                for (k in j + 1...numvertices) 
				{
                    var N3:Vector3f = vertices.getQuick(k);

                    edge0.subtractBy(N2, N1);
                    edge1.subtractBy(N3, N1);
                    var normalSign:Float = 1;
                    for (ww in 0...2) 
					{
                        tmp.crossBy(edge0, edge1);
                        planeEquation.x = normalSign * tmp.x;
                        planeEquation.y = normalSign * tmp.y;
                        planeEquation.z = normalSign * tmp.z;

                        if (LinearMathUtil.lengthSquared3(planeEquation) > 0.0001)
						{
                            LinearMathUtil.normalize3(planeEquation);
							
                            if (notExist(planeEquation, planeEquationsOut)) 
							{
                                planeEquation.w = -LinearMathUtil.dot3(planeEquation, N1);

                                // check if inside, and replace supportingVertexOut if needed
                                if (areVerticesBehindPlane(planeEquation, vertices, 0.01))
								{
                                    planeEquationsOut.add(planeEquation.clone());
                                }
                            }
                        }
                        normalSign = -1;
                    }
                }
            }
        }
    }

    public static function getVerticesFromPlaneEquations(planeEquations:ObjectArrayList<Vector4f>, verticesOut:ObjectArrayList<Vector3f>):Void
	{
        var n2n3:Vector3f = new Vector3f();
        var n3n1:Vector3f = new Vector3f();
        var n1n2:Vector3f = new Vector3f();
        var potentialVertex:Vector3f = new Vector3f();

        var numbrushes:Int = planeEquations.size();
        // brute force:
        for (i in 0...numbrushes) 
		{
            var N1:Vector4f = planeEquations.getQuick(i);

            for (j in i + 1...numbrushes) 
			{
                var N2:Vector4f = planeEquations.getQuick(j);

                for (k in j + 1...numbrushes) 
				{
                    var N3:Vector4f = planeEquations.getQuick(k);

                    LinearMathUtil.cross3(n2n3, N2, N3);
                    LinearMathUtil.cross3(n3n1, N3, N1);
                    LinearMathUtil.cross3(n1n2, N1, N2);

                    if ((n2n3.lengthSquared > 0.0001) &&
						(n3n1.lengthSquared > 0.0001) &&
						(n1n2.lengthSquared > 0.0001))
					{
                        // point P out of 3 plane equations:

                        // 	     d1 ( N2 * N3 ) + d2 ( N3 * N1 ) + d3 ( N1 * N2 )
                        // P =  -------------------------------------------------------------------------
                        //    N1 . ( N2 * N3 )

                        var quotient:Float = LinearMathUtil.dot3(N1, n2n3);
                        if (Math.abs(quotient) > 0.000001)
						{
                            quotient = -1 / quotient;
                            n2n3.scaleLocal(N1.w);
                            n3n1.scaleLocal(N2.w);
                            n1n2.scaleLocal(N3.w);
                            potentialVertex.copyFrom(n2n3);
                            potentialVertex.addLocal(n3n1);
                            potentialVertex.addLocal(n1n2);
                            potentialVertex.scaleLocal(quotient);

                            // check if inside, and replace supportingVertexOut if needed
                            if (isPointInsidePlanes(planeEquations, potentialVertex, 0.01))
							{
                                verticesOut.add(potentialVertex.clone());
                            }
                        }
                    }
                }
            }
        }
    }
	
}