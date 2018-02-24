package angle3d.bounding;

import angle3d.math.Vector3f;
import angle3d.math.FastMath;
import angle3d.math.Plane;
import angle3d.math.PlaneSide;

/**
 * This class includes some utility methods for computing intersection
 * between bounding volumes and triangles.
 */
class Intersection {
	public static inline function intersectSphereSphere(sphere:BoundingSphere, center:Vector3f, radius:Float):Bool {
		var dx:Float = center.x - sphere.center.x;
		var dy:Float = center.y - sphere.center.y;
		var dz:Float = center.z - sphere.center.z;
		var rsum:Float = radius + sphere.radius;
		return (dx * dx + dy * dy + dz * dz) <= rsum * rsum;
	}

	public static inline function intersectBoxSphere(bbox:BoundingBox, center:Vector3f, radius:Float):Bool {
		// Arvo's algorithm
		var distSqr:Float = radius * radius;

		var minX:Float = bbox.center.x - bbox.xExtent;
		var maxX:Float = bbox.center.x + bbox.xExtent;

		var minY:Float = bbox.center.y - bbox.yExtent;
		var maxY:Float = bbox.center.y + bbox.yExtent;

		var minZ:Float = bbox.center.z - bbox.zExtent;
		var maxZ:Float = bbox.center.z + bbox.zExtent;

		if (center.x < minX)
			distSqr -= FastMath.sqr(center.x - minX);
		else if (center.x > maxX)
			distSqr -= FastMath.sqr(center.x - maxX);

		if (center.y < minY)
			distSqr -= FastMath.sqr(center.y - minY);
		else if (center.y > maxY)
			distSqr -= FastMath.sqr(center.y - maxY);

		if (center.z < minZ)
			distSqr -= FastMath.sqr(center.z - minZ);
		else if (center.z > maxZ)
			distSqr -= FastMath.sqr(center.z - maxZ);

		return distSqr > 0;
	}

	private static inline function findMinMax(x0:Float, x1:Float, x2:Float, minMax:Vector3f):Void {
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

	private static var minMax:Vector3f;
	private static var plane:Plane;
	/**
	 * @see http://www.cs.lth.se/home/Tomas_Akenine_Moller/code/tribox3.txt
	 * @param	bbox
	 * @param	v1
	 * @param	v2
	 * @param	v3
	 * @return
	 */
	public static function intersectBoxTriangle(bbox:BoundingBox, v1:Vector3f, v2:Vector3f, v3:Vector3f):Bool {
		//  use separating axis theorem to test overlap between triangle and box
		//  need to test for overlap in these directions:
		//  1) the {x,y,z}-directions (actually, since we use the AABB of the triangle
		//     we do not even need to test these)
		//  2) normal of the triangle
		//  3) crossproduct(edge from tri, {x,y,z}-directin)
		//       this gives 3x3=9 more tests

		if (minMax == null)
			minMax = new Vector3f();

		var center:Vector3f = bbox.center;

		var extentX:Float = bbox.xExtent;
		var extentY:Float = bbox.yExtent;
		var extentZ:Float = bbox.zExtent;

		//float min,max,p0,p1,p2,rad,fex,fey,fez;
		//float normal[3]

		// This is the fastest branch on Sun
		// move everything so that the boxcenter is in (0,0,0)
		//var tmp0:Vector3f = v1.subtract(center);
		//var tmp1:Vector3f = v2.subtract(center);
		//var tmp2:Vector3f = v3.subtract(center);

		var tmp0x:Float = v1.x - center.x;
		var tmp0y:Float = v1.y - center.y;
		var tmp0z:Float = v1.z - center.z;

		var tmp1x:Float = v2.x - center.x;
		var tmp1y:Float = v2.y - center.y;
		var tmp1z:Float = v2.z - center.z;

		var tmp2x:Float = v3.x - center.x;
		var tmp2y:Float = v3.y - center.y;
		var tmp2z:Float = v3.z - center.z;

		// compute triangle edges
		//var e0 = tmp1.subtract(tmp0); // tri edge 0
		//var e1 = tmp2.subtract(tmp1); // tri edge 1
		//var e2 = tmp0.subtract(tmp2); // tri edge 2
		var e0x:Float = tmp1x - tmp0x;
		var e0y:Float = tmp1y - tmp0y;
		var e0z:Float = tmp1z - tmp0z;

		var e1x:Float = tmp2x - tmp1x;
		var e1y:Float = tmp2y - tmp1y;
		var e1z:Float = tmp2z - tmp1z;

		var e2x:Float = tmp0x - tmp2x;
		var e2y:Float = tmp0y - tmp2y;
		var e2z:Float = tmp0z - tmp2z;

		// Bullet 3:
		// test the 9 tests first (this was faster)
		var min:Float, max:Float;
		var p0:Float, p1:Float, p2:Float, rad:Float;
		var fex:Float = FastMath.abs(e0x);
		var fey:Float = FastMath.abs(e0y);
		var fez:Float = FastMath.abs(e0z);

		//AXISTEST_X01(e0[Z], e0[Y], fez, fey);
		p0 = e0z * tmp0y - e0y * tmp0z;
		p2 = e0z * tmp2y - e0y * tmp2z;
		min = FastMath.min(p0, p2);
		max = FastMath.max(p0, p2);
		rad = fez * extentY + fey * extentZ;
		if (min > rad || max < -rad) {
			return false;
		}

		//   AXISTEST_Y02(e0[Z], e0[X], fez, fex);
		p0 = -e0z * tmp0x + e0x * tmp0z;
		p2 = -e0z * tmp2x + e0x * tmp2z;
		min = FastMath.min(p0, p2);
		max = FastMath.max(p0, p2);
		rad = fez * extentX + fex * extentZ;
		if (min > rad || max < -rad) {
			return false;
		}

		// AXISTEST_Z12(e0[Y], e0[X], fey, fex);
		p1 = e0y * tmp1x - e0x * tmp1y;
		p2 = e0y * tmp2x - e0x * tmp2y;
		min = FastMath.min(p1, p2);
		max = FastMath.max(p1, p2);
		rad = fey * extentX + fex * extentY;
		if (min > rad || max < -rad) {
			return false;
		}

		fex = FastMath.abs(e1x);
		fey = FastMath.abs(e1y);
		fez = FastMath.abs(e1z);

		//AXISTEST_X01(e1[Z], e1[Y], fez, fey);
		p0 = e1z * tmp0y - e1y * tmp0z;
		p2 = e1z * tmp2y - e1y * tmp2z;
		min = FastMath.min(p0, p2);
		max = FastMath.max(p0, p2);
		rad = fez * extentY + fey * extentZ;
		if (min > rad || max < -rad) {
			return false;
		}

		//   AXISTEST_Y02(e1[Z], e1[X], fez, fex);
		p0 = -e1z * tmp0x + e1x * tmp0z;
		p2 = -e1z * tmp2x + e1x * tmp2z;
		min = FastMath.min(p0, p2);
		max = FastMath.max(p0, p2);
		rad = fez * extentX + fex * extentZ;
		if (min > rad || max < -rad) {
			return false;
		}

		// AXISTEST_Z0(e1[Y], e1[X], fey, fex);
		p0 = e1y * tmp0x - e1x * tmp0y;
		p1 = e1y * tmp1x - e1x * tmp1y;
		min = FastMath.min(p0, p1);
		max = FastMath.max(p0, p1);
		rad = fey * extentX + fex * extentY;
		if (min > rad || max < -rad) {
			return false;
		}
//
		fex = FastMath.abs(e2x);
		fey = FastMath.abs(e2y);
		fez = FastMath.abs(e2z);

		// AXISTEST_X2(e2[Z], e2[Y], fez, fey);
		p0 = e2z * tmp0y - e2y * tmp0z;
		p1 = e2z * tmp1y - e2y * tmp1z;
		min = FastMath.min(p0, p1);
		max = FastMath.max(p0, p1);
		rad = fez * extentY + fey * extentZ;
		if (min > rad || max < -rad) {
			return false;
		}

		// AXISTEST_Y1(e2[Z], e2[X], fez, fex);
		p0 = -e2z * tmp0x + e2x * tmp0z;
		p1 = -e2z * tmp1x + e2x * tmp1z;
		min = FastMath.min(p0, p1);
		max = FastMath.max(p0, p1);
		rad = fez * extentX + fex * extentY;
		if (min > rad || max < -rad) {
			return false;
		}

		//AXISTEST_Z12(e2[Y], e2[X], fey, fex);
		p1 = e2y * tmp1x - e2x * tmp1y;
		p2 = e2y * tmp2x - e2x * tmp2y;
		min = FastMath.min(p1, p2);
		max = FastMath.max(p1, p2);
		rad = fey * extentX + fex * extentY;
		if (min > rad || max < -rad) {
			return false;
		}

		//  Bullet 1:
		//  first test overlap in the {x,y,z}-directions
		//  find min, max of the triangle each direction, and test for overlap in
		//  that direction -- this is equivalent to testing a minimal AABB around
		//  the triangle against the AABB

		// test in X-direction
		findMinMax(tmp0x, tmp1x, tmp2x, minMax);
		if (minMax.x > extentX || minMax.y < -extentX) {
			return false;
		}

		// test in Y-direction
		findMinMax(tmp0y, tmp1y, tmp2y, minMax);
		if (minMax.x > extentY || minMax.y < -extentY) {
			return false;
		}

		// test in Z-direction
		findMinMax(tmp0z, tmp1z, tmp2z, minMax);
		if (minMax.x > extentZ || minMax.y < -extentZ) {
			return false;
		}

		// Bullet 2:
		//  test if the box intersects the plane of the triangle
		//  compute plane equation of triangle: normal * x + d = 0
		// Vector3f normal = new Vector3f();
		// e0.cross(e1, normal);

		if (plane == null)
			plane = new Plane();

		plane.setPoints(v1, v2, v3);
		if (bbox.whichSide(plane) == PlaneSide.Negative) {
			return false;
		}

		//if(!planeBoxOverlap(normal,v0,boxhalfsize)) return false;

		return true; /* box and triangle overlaps */
	}
}

