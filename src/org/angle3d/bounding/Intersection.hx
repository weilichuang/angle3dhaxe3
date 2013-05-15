package org.angle3d.bounding;

import org.angle3d.math.Vector3f;
import org.angle3d.math.FastMath;
import org.angle3d.math.Plane;
import org.angle3d.math.PlaneSide;

/**
 * This class includes some utility methods for computing intersection
 * between bounding volumes and triangles.
 * @author Kirill
 */
class Intersection
{
	private static function findMinMax(x0:Float, x1:Float, x2:Float, minMax:Vector3f):Void
	{
		minMax.setTo(x0, x0, 0);
		if (x1 < minMax.x)
			minMax.x = x1;
		if (x1 > minMax.y)
			minMax.y = x1;
		if (x2 < minMax.x)
			minMax.x = x2;
		if (x2 > minMax.y)
			minMax.y = x2;
	}

	public static function intersect(bbox:BoundingBox, v1:Vector3f, v2:Vector3f, v3:Vector3f):Bool
	{
		//  use separating axis theorem to test overlap between triangle and box
		//  need to test for overlap in these directions:
		//  1) the {x,y,z}-directions (actually, since we use the AABB of the triangle
		//     we do not even need to test these)
		//  2) normal of the triangle
		//  3) crossproduct(edge from tri, {x,y,z}-directin)
		//       this gives 3x3=9 more tests

		var tmp0:Vector3f;
		var tmp1:Vector3f;
		var tmp2:Vector3f;

		var e0:Vector3f;
		var e1:Vector3f;
		var e2:Vector3f;

		var center:Vector3f = bbox.getCenter();
		var extent:Vector3f = bbox.getExtent();

		//float min,max,p0,p1,p2,rad,fex,fey,fez;
		//float normal[3]

		// This is the fastest branch on Sun
		// move everything so that the boxcenter is in (0,0,0)
		tmp0 = v1.subtract(center);
		tmp1 = v2.subtract(center);
		tmp2 = v3.subtract(center);

		// compute triangle edges
		e0 = tmp1.subtract(tmp0); // tri edge 0
		e1 = tmp2.subtract(tmp1); // tri edge 1
		e2 = tmp0.subtract(tmp2); // tri edge 2

		// Bullet 3:
		// test the 9 tests first (this was faster)
		var min:Float, max:Float;
		var p0:Float, p1:Float, p2:Float, rad:Float;
		var fex:Float = FastMath.abs(e0.x);
		var fey:Float = FastMath.abs(e0.y);
		var fez:Float = FastMath.abs(e0.z);


		//AXISTEST_X01(e0[Z], e0[Y], fez, fey);
		p0 = e0.z * tmp0.y - e0.y * tmp0.z;
		p2 = e0.z * tmp2.y - e0.y * tmp2.z;
		min = FastMath.min(p0, p2);
		max = FastMath.max(p0, p2);
		rad = fez * extent.y + fey * extent.z;
		if (min > rad || max < -rad)
		{
			return false;
		}

		//   AXISTEST_Y02(e0[Z], e0[X], fez, fex);
		p0 = -e0.z * tmp0.x + e0.x * tmp0.z;
		p2 = -e0.z * tmp2.x + e0.x * tmp2.z;
		min = FastMath.min(p0, p2);
		max = FastMath.max(p0, p2);
		rad = fez * extent.x + fex * extent.z;
		if (min > rad || max < -rad)
		{
			return false;
		}

		// AXISTEST_Z12(e0[Y], e0[X], fey, fex);
		p1 = e0.y * tmp1.x - e0.x * tmp1.y;
		p2 = e0.y * tmp2.x - e0.x * tmp2.y;
		min = FastMath.min(p1, p2);
		max = FastMath.max(p1, p2);
		rad = fey * extent.x + fex * extent.y;
		if (min > rad || max < -rad)
		{
			return false;
		}

		fex = FastMath.abs(e1.x);
		fey = FastMath.abs(e1.y);
		fez = FastMath.abs(e1.z);

		//AXISTEST_X01(e1[Z], e1[Y], fez, fey);
		p0 = e1.z * tmp0.y - e1.y * tmp0.z;
		p2 = e1.z * tmp2.y - e1.y * tmp2.z;
		min = FastMath.min(p0, p2);
		max = FastMath.max(p0, p2);
		rad = fez * extent.y + fey * extent.z;
		if (min > rad || max < -rad)
		{
			return false;
		}

		//   AXISTEST_Y02(e1[Z], e1[X], fez, fex);
		p0 = -e1.z * tmp0.x + e1.x * tmp0.z;
		p2 = -e1.z * tmp2.x + e1.x * tmp2.z;
		min = FastMath.min(p0, p2);
		max = FastMath.max(p0, p2);
		rad = fez * extent.x + fex * extent.z;
		if (min > rad || max < -rad)
		{
			return false;
		}

		// AXISTEST_Z0(e1[Y], e1[X], fey, fex);
		p0 = e1.y * tmp0.x - e1.x * tmp0.y;
		p1 = e1.y * tmp1.x - e1.x * tmp1.y;
		min = FastMath.min(p0, p1);
		max = FastMath.max(p0, p1);
		rad = fey * extent.x + fex * extent.y;
		if (min > rad || max < -rad)
		{
			return false;
		}
//
		fex = FastMath.abs(e2.x);
		fey = FastMath.abs(e2.y);
		fez = FastMath.abs(e2.z);

		// AXISTEST_X2(e2[Z], e2[Y], fez, fey);
		p0 = e2.z * tmp0.y - e2.y * tmp0.z;
		p1 = e2.z * tmp1.y - e2.y * tmp1.z;
		min = FastMath.min(p0, p1);
		max = FastMath.max(p0, p1);
		rad = fez * extent.y + fey * extent.z;
		if (min > rad || max < -rad)
		{
			return false;
		}

		// AXISTEST_Y1(e2[Z], e2[X], fez, fex);
		p0 = -e2.z * tmp0.x + e2.x * tmp0.z;
		p1 = -e2.z * tmp1.x + e2.x * tmp1.z;
		min = FastMath.min(p0, p1);
		max = FastMath.max(p0, p1);
		rad = fez * extent.x + fex * extent.y;
		if (min > rad || max < -rad)
		{
			return false;
		}

		//AXISTEST_Z12(e2[Y], e2[X], fey, fex);
		p1 = e2.y * tmp1.x - e2.x * tmp1.y;
		p2 = e2.y * tmp2.x - e2.x * tmp2.y;
		min = FastMath.min(p1, p2);
		max = FastMath.max(p1, p2);
		rad = fey * extent.x + fex * extent.y;
		if (min > rad || max < -rad)
		{
			return false;
		}

		//  Bullet 1:
		//  first test overlap in the {x,y,z}-directions
		//  find min, max of the triangle each direction, and test for overlap in
		//  that direction -- this is equivalent to testing a minimal AABB around
		//  the triangle against the AABB


		var minMax:Vector3f = new Vector3f();

		// test in X-direction
		findMinMax(tmp0.x, tmp1.x, tmp2.x, minMax);
		if (minMax.x > extent.x || minMax.y < -extent.x)
		{
			return false;
		}

		// test in Y-direction
		findMinMax(tmp0.y, tmp1.y, tmp2.y, minMax);
		if (minMax.x > extent.y || minMax.y < -extent.y)
		{
			return false;
		}

		// test in Z-direction
		findMinMax(tmp0.z, tmp1.z, tmp2.z, minMax);
		if (minMax.x > extent.z || minMax.y < -extent.z)
		{
			return false;
		}

		// Bullet 2:
		//  test if the box intersects the plane of the triangle
		//  compute plane equation of triangle: normal * x + d = 0
		// Vector3f normal = new Vector3f();
		// e0.cross(e1, normal);
		var p:Plane = new Plane();
		p.setPoints(v1, v2, v3);
		if (bbox.whichSide(p) == PlaneSide.Negative)
		{
			return false;
		}

		//if(!planeBoxOverlap(normal,v0,boxhalfsize)) return false;

		return true; /* box and triangle overlaps */
	}
}

