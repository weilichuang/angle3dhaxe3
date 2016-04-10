package org.angle3d.math;

import org.angle3d.math.Vector3f;

/**
 * Plane defines a plane where Normal dot (x,y,z) = Constant.
 * This provides methods for calculating a "distance" of a point from this
 * plane. The distance is pseudo due to the fact that it can be negative if the
 * point is on the non-normal side of the plane.
 *
 */
class Plane
{
	/**
	 * Vector normal to the plane.
	 */
	public var normal:Vector3f = new Vector3f();

	/**
	 * Constant of the plane. See formula in class definition.
	 */
	public var constant:Float = 0;

	/**
	 * Constructor instantiates a new `Plane` object. The normal
	 * and constant values are set_at creation.
	 *
	 * @param normal
	 *            the normal of the plane.
	 * @param constant
	 *            the constant of the plane.
	 */
	public inline function new(normal:Vector3f = null, constant:Float = 0.)
	{
		if (normal != null)
		{
			this.normal.copyFrom(normal);
		}
		this.constant = constant;
	}

	/**
	 * `setNormal` sets the normal of the plane.
	 *
	 * @param normal
	 *            the new normal of the plane.
	 */
	public function setNormal(normal:Vector3f):Void
	{
		this.normal.copyFrom(normal);
	}


	/**
	 * `setConstant` sets the constant value that helps define the
	 * plane.
	 *
	 * @param constant
	 *            the new constant value.
	 */
	public function setConstant(constant:Float):Void
	{
		this.constant = constant;
	}

	public function getClosestPoint(point:Vector3f, result:Vector3f = null):Vector3f
	{
		if (result == null)
		{
			result = new Vector3f();
		}
		var t:Float = (constant - normal.dot(point)) / normal.dot(normal);
		result.x = normal.x * t + point.x;
		result.y = normal.y * t + point.y;
		result.z = normal.z * t + point.z;
		return result;
	}

	public function reflect(point:Vector3f, result:Vector3f = null):Vector3f
	{
		if (result == null)
		{
			result = new Vector3f();
		}

		var d:Float = 2 * pseudoDistance(point);
		result.x = -normal.x * d + point.x;
		result.y = -normal.y * d + point.y;
		result.z = -normal.z * d + point.z;
		return result;
	}

	/**
	* pseudoDistance calculates the distance from this plane to
	* a provided point. If the point is on the negative side of the plane the
	* distance returned is negative, otherwise it is positive. If the point is
	* on the plane, it is zero.
	*
	* @param point the point to check.
	* @return the signed distance from the plane to a point.
	*/
	public inline function pseudoDistance(point:Vector3f):Float
	{
		return normal.dot(point) - constant;
	}

	/**
	 * `whichSide` returns the side at which a point lies on the
	 * plane. The positive values returned are: NEGATIVE_SIDE, POSITIVE_SIDE and
	 * NO_SIDE.
	 *
	 * @param point
	 *            the point to check.
	 * @return the side at which the point lies.
	 */
	public inline function whichSide(point:Vector3f):PlaneSide
	{
		var dis:Float = pseudoDistance(point);
		if (dis < 0)
		{
			return PlaneSide.Negative;
		}
		else if (dis > 0)
		{
			return PlaneSide.Positive;
		}
		else
		{
			return PlaneSide.None;
		}
	}

	public function isOnPlane(point:Vector3f):Bool
	{
		var dist:Float = pseudoDistance(point);
		if (dist < FastMath.FLT_EPSILON && dist > -FastMath.FLT_EPSILON)
		{
			return true;
		}
		else
		{
			return false;
		}
	}

	/**
	 * Initialize this plane using the three points of the given triangle.
	 *
	 * @param t
	 *            the triangle
	 */
	public function setTriangle(t:Triangle):Void
	{
		setPoints(t.point1, t.point2, t.point3);
	}

	/**
	 * Initialize the Plane using the given 3 points as coplanar.
	 *
	 * @param v1
	 *            the first point
	 * @param v2
	 *            the second point
	 * @param v3
	 *            the third point
	 */
	public function setPoints(v1:Vector3f, v2:Vector3f, v3:Vector3f):Void
	{
		//normal.copyFrom(v2);
		//normal.subtractLocal(v1);
		//normal = normal.cross(v3.subtract(v1));
		
		var nx:Float = v2.x - v1.x;
		var ny:Float = v2.y - v1.y;
		var nz:Float = v2.z - v1.z;
		
		var v3v1x:Float = v3.x - v1.x;
		var v3v1y:Float = v3.y - v1.y;
		var v3v1z:Float = v3.z - v1.z;
		
		normal.x = (ny * v3v1z - nz * v3v1y);
		normal.y = (nz * v3v1x - nx * v3v1z);
		normal.z = (nx * v3v1y - ny * v3v1x);

		normal.normalizeLocal();

		constant = normal.dot(v1);
	}

	/**
	 * Initialize this plane using a point of origin and a normal.
	 *
	 * @param origin
	 * @param normal
	 */
	public function setOriginNormal(origin:Vector3f, normal:Vector3f):Void
	{
		this.normal.copyFrom(normal);
		this.constant = normal.dot(origin);
	}

	/**
	 * `toString` returns a string thta represents the string
	 * representation of this plane. It represents the normal as a
	 * `Vector3f` object, so the format is the following:
	 * org.angle3d.math.Plane [Normal: org.Angle3D.math.Vector3f [X=XX.XXXX, Y=YY.YYYY,
	 * Z=ZZ.ZZZZ] - Constant: CC.CCCCC]
	 *
	 * @return the string representation of this plane.
	 */
	public function toString():String
	{
		return "Plane[Normal: " + normal + " - Constant: " + constant + "]";
	}

	public function copyFrom(other:Plane):Void
	{
		this.normal.copyFrom(other.normal);
		this.constant = other.constant;
	}

	public function clone():Plane
	{
		return new Plane(this.normal, this.constant);
	}
}


