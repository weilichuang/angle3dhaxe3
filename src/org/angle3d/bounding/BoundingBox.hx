package org.angle3d.bounding;

import org.angle3d.error.Assert;
import flash.Lib;
import flash.Vector;
import org.angle3d.collision.Collidable;
import org.angle3d.collision.CollisionResult;
import org.angle3d.collision.CollisionResults;
import org.angle3d.math.FastMath;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Plane;
import org.angle3d.math.PlaneSide;
import org.angle3d.math.Ray;
import org.angle3d.math.Transform;
import org.angle3d.math.Triangle;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Spatial;
import org.angle3d.utils.TempVars;

/**
 * BoundingBox describes a bounding volume as an axis-aligned box.
 * <br>
 * Instances may be initialized by invoking the containAABB method.
 *
 */
class BoundingBox extends BoundingVolume
{
	public var xExtent:Float = 0;
	public var yExtent:Float = 0;
	public var zExtent:Float = 0;

	public function new(center:Vector3f = null, extent:Vector3f = null)
	{
		super(center);
		
		this.type = BoundingVolumeType.AABB;

		if (extent != null)
		{
			xExtent = extent.x;
			yExtent = extent.y;
			zExtent = extent.z;
		}
	}
	
	public function reset():Void
	{
		this.center.setTo(0, 0, 0);
		xExtent = 0;
		yExtent = 0;
		zExtent = 0;
	}

	public function setExtent(x:Float, y:Float, z:Float):Void
	{
		xExtent = x;
		yExtent = y;
		zExtent = z;
	}

	public function setMinMax(min:Vector3f, max:Vector3f):Void
	{
		center.x = (max.x - min.x) * 0.5;
		center.y = (max.y - min.y) * 0.5;
		center.z = (max.z - min.z) * 0.5;

		xExtent = FastMath.abs(max.x - center.x);
		yExtent = FastMath.abs(max.y - center.y);
		zExtent = FastMath.abs(max.z - center.z);
	}

	/**
	 * `computeFromPoints` creates a new Bounding Box from a given
	 * set_of points. It uses the `containAABB` method as default.
	 *
	 * @param points
	 *            the points to contain.
	 */
	override public function computeFromPoints(points:Vector<Float>):Void
	{
		containAABB(points);
	}

	/**
	 * `computeFromTris` creates a new Bounding Box from a given
	 * set_of triangles. It is used in OBBTree calculations.
	 *
	 * @param tris
	 * @param start
	 * @param end
	 */
	public function computeFromTris(tris:Vector<Triangle>, start:Int, end:Int):Void
	{
		Assert.assert(end - start > 0, "end should be greater than end");

		var min:Vector3f = new Vector3f();
		var max:Vector3f = new Vector3f();

		var tri:Triangle = tris[start];
		var point:Vector3f = tri.getPoint(0);

		min.copyFrom(point);
		max.copyFrom(point);

		for (i in start...end)
		{
			tri = tris[i];
			Vector3f.checkMinMax(min, max, tri.getPoint(0));
			Vector3f.checkMinMax(min, max, tri.getPoint(1));
			Vector3f.checkMinMax(min, max, tri.getPoint(2));
		}

		center.x = (min.x + max.x) * 0.5;
		center.y = (min.y + max.y) * 0.5;
		center.z = (min.z + max.z) * 0.5;

		xExtent = max.x - center.x;
		yExtent = max.y - center.y;
		zExtent = max.z - center.z;
	}

	//public function computeFromMesh(indices:Vector<Int>, mesh:SubMesh, start:Int, end:Int):Void
	//{
		//Assert.assert(end - start > 0, "end should be greater than end");
//
		//var min:Vector3f = new Vector3f();
		//var max:Vector3f = new Vector3f();
//
		//var tri:Triangle = new Triangle();
		//var point:Vector3f;
//
		//初始化min,max
		//mesh.getTriangle(indices[start], tri);
		//point = tri.getPoint(0);
		//min.copyFrom(point);
		//max.copyFrom(point);
//
		//for (i in start...end)
		//{
			//mesh.getTriangle(indices[i], tri);
			//point = tri.getPoint(0);
			//Vector3f.checkMinMax(min, max, point);
			//point = tri.getPoint(1);
			//Vector3f.checkMinMax(min, max, point);
			//point = tri.getPoint(2);
			//Vector3f.checkMinMax(min, max, point);
		//}
//
		//center.x = (min.x + max.x) * 0.5;
		//center.y = (min.y + max.y) * 0.5;
		//center.z = (min.z + max.z) * 0.5;
//
		//xExtent = max.x - center.x;
		//yExtent = max.y - center.y;
		//zExtent = max.z - center.z;
	//}

	/**
	 * `containAABB` creates a minimum-volume axis-aligned bounding
	 * box of the points, then selects the smallest enclosing sphere of the box
	 * with the sphere centered at the boxes center.
	 *
	 * @param points
	 *            the list of points.
	 */
	public function containAABB(points:Vector<Float>):Void
	{
		if (points.length <= 2) // we need at least a 3 float vector
			return;

		var minX:Float = points[0];
		var minY:Float = points[1];
		var minZ:Float = points[2];
		var maxX:Float = minX;
		var maxY:Float = minY;
		var maxZ:Float = minZ;

		var len:Int = Std.int(points.length / 3);
		for (i in 1...len)
		{
			var i3:Int = i * 3;

			var px:Float = points[i3];
			var py:Float = points[i3 + 1];
			var pz:Float = points[i3 + 2];

			if (px < minX)
				minX = px;
			else if (px > maxX)
				maxX = px;

			if (py < minY)
				minY = py;
			else if (py > maxY)
				maxY = py;

			if (pz < minZ)
				minZ = pz;
			else if (pz > maxZ)
				maxZ = pz;
		}

		center.x = (minX + maxX) * 0.5;
		center.y = (minY + maxY) * 0.5;
		center.z = (minZ + maxZ) * 0.5;

		xExtent = maxX - center.x;
		yExtent = maxY - center.y;
		zExtent = maxZ - center.z;
	}

	/**
	 * `transform` modifies the center of the box to reflect the
	 * change made via a rotation, translation and scale.
	 *
	 * @param rotate
	 *            the rotation change.
	 * @param translate
	 *            the translation change.
	 * @param scale
	 *            the size change.
	 * @param result
	 *            box to store result in
	 */
	private static var hTransMatrix:Matrix3f = new Matrix3f();
	private static var hVect:Vector3f = new Vector3f();
	override public function transform(trans:Transform, result:BoundingVolume = null):BoundingVolume
	{
		var box:BoundingBox;
		if (result == null || result.type != BoundingVolumeType.AABB)
		{
			box = new BoundingBox();
		}
		else
		{
			box = cast result;
		}

		center.mult(trans.scale, box.center);
		trans.rotation.multVector(box.center, box.center);
		box.center.addLocal(trans.translation);

		hTransMatrix.fromQuaternion(trans.rotation);
		// Make the rotation matrix all positive to get_the maximum x/y/z extent
		hTransMatrix.abs();

		var scale:Vector3f = trans.scale;
		hVect.x = xExtent * FastMath.abs(scale.x);
		hVect.y = yExtent * FastMath.abs(scale.y);
		hVect.z = zExtent * FastMath.abs(scale.z);

		hTransMatrix.multVecLocal(hVect);

		// Assign the biggest rotations after scales.
		box.xExtent = FastMath.abs(hVect.x);
		box.yExtent = FastMath.abs(hVect.y);
		box.zExtent = FastMath.abs(hVect.z);

		return box;
	}
	
	override public function transformMatrix(trans:Matrix4f, result:BoundingVolume = null):BoundingVolume
	{
		var box:BoundingBox;
		if (result == null || result.type != BoundingVolumeType.AABB)
		{
			box = new BoundingBox();
		}
		else
		{
			box = cast result;
		}

		var w:Float = trans.multProj(center, box.center);
		box.center.scaleLocal(1 / w);

		trans.toMatrix3f(hTransMatrix);

		// Make the rotation matrix all positive to get_the maximum x/y/z extent
		hTransMatrix.abs();

		hVect.setTo(xExtent, yExtent, zExtent);
		hTransMatrix.multVecLocal(hVect);

		// Assign the biggest rotations after scales.
		box.xExtent = FastMath.abs(hVect.x);
		box.yExtent = FastMath.abs(hVect.y);
		box.zExtent = FastMath.abs(hVect.z);

		return box;
	}

	/**
	 * `whichSide` takes a plane (typically provided by a view
	 * frustum) to determine which side this bound is on.
	 *
	 * @param plane
	 *            the plane to check against.
	 */
	override public function whichSide(plane:Plane):PlaneSide
	{
		var normal:Vector3f = plane.normal;
		var radius:Float = FastMath.abs(xExtent * normal.x) + FastMath.abs(yExtent * normal.y) + FastMath.abs(zExtent * normal.z);

		var distance:Float = plane.pseudoDistance(center);

		//changed to < and > to prevent floating point precision problems
		if (distance < -radius)
		{
			return PlaneSide.Negative;
		}
		else if (distance > radius)
		{
			return PlaneSide.Positive;
		}
		else
		{
			return PlaneSide.None;
		}
	}

	/**
	 * `merge` combines this bounding box with a second bounding box.
	 * This new box contains both bounding box and is returned.
	 *
	 * @param volume
	 *            the bounding box to combine with this bounding box.
	 * @return the new bounding box
	 */
	override public function merge(volume:BoundingVolume):BoundingVolume
	{
		switch (volume.type)
		{
			case BoundingVolumeType.AABB:
				var box:BoundingBox = cast volume;
				return mergeToBoundingBox(box.center, box.xExtent, box.yExtent, box.zExtent);
			case BoundingVolumeType.Sphere:
				var sphere:BoundingSphere = cast volume;
				return mergeToBoundingBox(sphere.center, sphere.radius, sphere.radius, sphere.radius);
			default:
				return null;
		}
	}

	/**
	 * `merge` combines this bounding box with another box which is
	 * defined by the center, x, y, z extents.
	 *
	 * @param boxCenter
	 *            the center of the box to merge with
	 * @param boxX
	 *            the x extent of the box to merge with.
	 * @param boxY
	 *            the y extent of the box to merge with.
	 * @param boxZ
	 *            the z extent of the box to merge with.
	 * @param rVal
	 *            the resulting merged box.
	 * @return the resulting merged box.
	 */
	public function mergeToBoundingBox(c:Vector3f, x:Float, y:Float, z:Float, result:BoundingBox = null):BoundingBox
	{
		if (result == null)
			result = new BoundingBox();

		var rCenter:Vector3f = result.center;
		if (xExtent == FastMath.POSITIVE_INFINITY || x == FastMath.POSITIVE_INFINITY)
		{
            rCenter.x = 0;
            result.xExtent = FastMath.POSITIVE_INFINITY;
        }
		else
		{
            var low:Float = center.x - xExtent;
            if (low > c.x - x)
			{
                low = c.x - x;
            }
            var high:Float = center.x + xExtent;
            if (high < c.x + x) 
			{
                high = c.x + x;
            }
            rCenter.x = (low + high) * 0.5;
            result.xExtent = high - rCenter.x;
        }

        if (yExtent == FastMath.POSITIVE_INFINITY || y == FastMath.POSITIVE_INFINITY)
		{
            rCenter.y = 0;
            result.yExtent = FastMath.POSITIVE_INFINITY;
        } 
		else 
		{
            var low:Float = center.y - yExtent;
            if (low > c.y - y)
			{
                low = c.y - y;
            }
            var high:Float = center.y + yExtent;
            if (high < c.y + y) 
			{
                high = c.y + y;
            }
            rCenter.y = (low + high) * 0.5;
            result.yExtent = high - rCenter.y;
        }

        if (zExtent == FastMath.POSITIVE_INFINITY || z == FastMath.POSITIVE_INFINITY)
		{
            rCenter.z = 0;
            result.zExtent = FastMath.POSITIVE_INFINITY;
        } 
		else
		{
            var low:Float = center.z - zExtent;
            if (low > c.z - z)
			{
                low = c.z - z;
            }
            var high:Float = center.z + zExtent;
            if (high < c.z + z) 
			{
                high = c.z + z;
            }
            rCenter.z = (low + high) * 0.5;
            result.zExtent = high - rCenter.z;
        }
		
		return result;
	}

	override public function mergeLocal(volume:BoundingVolume):Void
	{
		if (volume == null)
			return;
			
		switch (volume.type)
		{
			case BoundingVolumeType.AABB:
				var box:BoundingBox = cast volume;
				mergeToBoundingBox(box.center, box.xExtent, box.yExtent, box.zExtent, this);
			case BoundingVolumeType.Sphere:
				var sphere:BoundingSphere = cast volume;
				mergeToBoundingBox(sphere.center, sphere.radius, sphere.radius, sphere.radius, this);
		}
	}

	override public function copyFrom(volume:BoundingVolume):Void
	{
		var box:BoundingBox = Lib.as(volume, BoundingBox);

		#if debug
		Assert.assert(box != null, "volume is not a BoundingBox");
		#end

		this.center.copyFrom(box.center);
		this.xExtent = box.xExtent;
		this.yExtent = box.yExtent;
		this.zExtent = box.zExtent;
		this.checkPlane = box.checkPlane;
	}

	override public function clone(result:BoundingVolume = null):BoundingVolume
	{
		var box:BoundingBox;
		if (result == null || !Std.is(result,BoundingBox))
		{
			box = new BoundingBox();
		}
		else
		{
			box = cast result;
		}

		box = cast super.clone(box);

		box.center.copyFrom(center);
		box.xExtent = xExtent;
		box.yExtent = yExtent;
		box.zExtent = zExtent;
		box.checkPlane = checkPlane;
		return box;
	}

	public function toString():String
	{
		return "BoundingBox [Center: " + center + "  xExtent: " + xExtent + "  yExtent: " + yExtent + "  zExtent: " + zExtent + "]";
	}

	/**
	 * intersects determines if this Bounding Box intersects with another given
	 * bounding volume. If so, true is returned, otherwise, false is returned.
	 *
	 * @see `BoundingVolume.intersects`
	 */
	override public function intersects(bv:BoundingVolume):Bool
	{
		return bv.intersectsBoundingBox(this);
	}

	/**
	 * determines if this bounding box intersects a given bounding sphere.
	 *
	 * @see `BoundingVolume.intersectsSphere`
	 */
	override public function intersectsSphere(bs:BoundingSphere):Bool
	{
		return bs.intersectsBoundingBox(this);
	}

	/**
	 * determines if this bounding box intersects a given bounding box. If the
	 * two boxes intersect in any way, true is returned. Otherwise, false is
	 * returned.
	 *
	 * @see `BoundingVolume.intersectsBoundingBox`
	 */
	override public function intersectsBoundingBox(bb:BoundingBox):Bool
	{
		var bbc:Vector3f = bb.center;
		if (center.x + xExtent < bbc.x - bb.xExtent || center.x - xExtent > bbc.x + bb.xExtent)
		{
			return false;
		}
		else if (center.y + yExtent < bbc.y - bb.yExtent || center.y - yExtent > bbc.y + bb.yExtent)
		{
			return false;
		}
		else if (center.z + zExtent < bbc.z - bb.zExtent || center.z - zExtent > bbc.z + bb.zExtent)
		{
			return false;
		}
		else
		{
			return true;
		}
	}

	/**
	 * determines if this bounding box intersects with a given ray object. If an
	 * intersection has occurred, true is returned, otherwise false is returned.
	 *
	 * @see `BoundingVolume.intersects`
	 */
	override public function intersectsRay(ray:Ray):Bool
	{
		var diff:Vector3f = ray.origin.subtract(center, hVect);

		var rhs:Float;

		//var fWdU:Array<Float> = [];
		//var fAWdU:Array<Float> = [];
		//var fDdU:Array<Float> = [];
		//var fADdU:Array<Float> = [];
		//var fAWxDdU:Array<Float> = [];

		var fWdU0:Float = ray.direction.dot(Vector3f.X_AXIS);
		var fAWdU0:Float = FastMath.abs(fWdU0);
		var fDdU0:Float = diff.dot(Vector3f.X_AXIS);
		var fADdU0:Float = FastMath.abs(fDdU0);
		if (fADdU0 > xExtent && fDdU0 * fWdU0 >= 0.0)
		{
			return false;
		}

		var fWdU1:Float = ray.direction.dot(Vector3f.Y_AXIS);
		var fAWdU1:Float = FastMath.abs(fWdU1);
		var fDdU1:Float = diff.dot(Vector3f.Y_AXIS);
		var fADdU1:Float = FastMath.abs(fDdU1);
		if (fADdU1 > yExtent && fDdU1 * fWdU1 >= 0.0)
		{
			return false;
		}

		var fWdU2:Float = ray.direction.dot(Vector3f.Z_AXIS);
		var fAWdU2:Float = FastMath.abs(fWdU2);
		var fDdU2:Float = diff.dot(Vector3f.Z_AXIS);
		var fADdU2:Float = FastMath.abs(fDdU2);
		if (fADdU2 > zExtent && fDdU2 * fWdU2 >= 0.0)
		{
			return false;
		}

		var wCrossD:Vector3f = ray.direction.cross(diff);

		var fAWxDdU0:Float = FastMath.abs(wCrossD.dot(Vector3f.X_AXIS));
		rhs = yExtent * fAWdU2 + zExtent * fAWdU1;
		if (fAWxDdU0 > rhs)
		{
			return false;
		}

		var fAWxDdU1:Float = FastMath.abs(wCrossD.dot(Vector3f.Y_AXIS));
		rhs = xExtent * fAWdU2 + zExtent * fAWdU0;
		if (fAWxDdU1 > rhs)
		{
			return false;
		}

		var fAWxDdU2:Float = FastMath.abs(wCrossD.dot(Vector3f.Z_AXIS));
		rhs = xExtent * fAWdU1 + yExtent * fAWdU0;
		if (fAWxDdU2 > rhs)
		{
			return false;
		}

		return true;
	}

	public function collideWithRay(ray:Ray, results:CollisionResults):Int
	{
		var diffX:Float = ray.origin.x - center.x;
		var diffY:Float = ray.origin.y - center.y;
		var diffZ:Float = ray.origin.z - center.z;
		
		var dirX:Float = ray.direction.x;
		var dirY:Float = ray.direction.y;
		var dirZ:Float = ray.direction.z;

		tVector[0] = 0;
		tVector[1] = FastMath.POSITIVE_INFINITY;  

		var saveT0:Float = tVector[0];
		var saveT1:Float = tVector[1];
		var notEntirelyClipped:Bool = clip( dirX,  -diffX - xExtent, tVector)
									&& clip(-dirX,  diffX - xExtent, tVector)
									&& clip( dirY, -diffY - yExtent, tVector)
									&& clip(-dirY,  diffY - yExtent, tVector)
									&& clip( dirZ, -diffZ - zExtent, tVector)
									&& clip( -dirZ,  diffZ - zExtent, tVector);

		if (notEntirelyClipped && (tVector[0] != saveT0 || tVector[1] != saveT1))
		{
			if (tVector[1] > tVector[0])
			{
				var distances:Vector<Float> = tVector;

				var point0:Vector3f = ray.direction.clone();
				point0.scaleAdd(distances[0], ray.origin);

				var point1:Vector3f = ray.direction.clone();
				point1.scaleAdd(distances[1], ray.origin);

				var result:CollisionResult = new CollisionResult();
				result.contactPoint = point0;
				result.distance = distances[0];
				results.addCollision(result);

				result = new CollisionResult();
				result.contactPoint = point1;
				result.distance = distances[1];
				results.addCollision(result);

				return 2;
			}

			var point:Vector3f = ray.direction.clone();
			point.scaleAdd(tVector[0], ray.origin);

			var result:CollisionResult = new CollisionResult();
			result.contactPoint = point;
			result.distance = tVector[0];
			results.addCollision(result);
			
			return 1;
		}
		return 0;
	}

	override public function collideWith(other:Collidable, results:CollisionResults):Int
	{
		if (Std.is(other,Ray))
		{
			var ray:Ray = cast other;
			return collideWithRay(ray, results);
		}
		else if (Std.is(other,Triangle))
		{
			var t:Triangle = Std.instance(other, Triangle);
			if (intersectsTriangle(t))
			{
				var r:CollisionResult = new CollisionResult();
				results.addCollision(r);
				return 1;
			}
			return 0;
		}
		else if (Std.is(other, BoundingVolume))
		{
			if (intersects(cast other))
			{
				var r:CollisionResult = new CollisionResult();
				results.addCollision(r);
				return 1;
			}
			return 0;
		}
		else if (Std.is(other, Spatial))
		{
			return cast(other, Spatial).collideWith(this, results);
		}
		else
		{
			return 0;
		}
	}
	
	private static var tVector:Vector<Float> = new Vector<Float>(2, true);
	private function collideWithRayNoResult(ray:Ray):Int
	{
		var diffX:Float = ray.origin.x - center.x;
		var diffY:Float = ray.origin.y - center.y;
		var diffZ:Float = ray.origin.z - center.z;
		
		var dirX:Float = ray.direction.x;
		var dirY:Float = ray.direction.y;
		var dirZ:Float = ray.direction.z;

		tVector[0] = 0;
		tVector[1] = FastMath.POSITIVE_INFINITY;  

		var saveT0:Float = tVector[0];
		var saveT1:Float = tVector[1];
		var notEntirelyClipped:Bool = clip( dirX,  -diffX - xExtent, tVector)
									&& clip(-dirX,  diffX - xExtent, tVector)
									&& clip( dirY, -diffY - yExtent, tVector)
									&& clip(-dirY,  diffY - yExtent, tVector)
									&& clip( dirZ, -diffZ - zExtent, tVector)
									&& clip(-dirZ,  diffZ - zExtent, tVector);

		if (notEntirelyClipped && (tVector[0] != saveT0 || tVector[1] != saveT1))
		{
			if (tVector[1] > tVector[0]) 
			{
				return 2;
			}
			else 
			{
				return 1;
			}
		}
		
		return 0;    
    }
	
	override public function collideWithNoResult(other:Collidable):Int
	{
		if (Std.is(other, Ray))
		{
            var ray:Ray = cast other;
            return collideWithRayNoResult(ray);
        } 
		else if (Std.is(other, Triangle))
		{
            if (intersectsTriangle(cast other))
			{
                return 1;
            }
            return 0;
        }
		else if (Std.is(other, BoundingVolume))
		{
			return intersects(cast other) ? 1 : 0;
		}
		else
		{
			throw "UnsupportedCollisionException With: " + Type.getClassName(Type.getClass(other));
		}

		return 0;
	}

	override public function intersectsTriangle(tri:Triangle):Bool
	{
		return Intersection.intersectBoxTriangle(this, tri.point1, tri.point2, tri.point3);
	}

	override public function contains(point:Vector3f):Bool
	{
		var px:Float = FastMath.abs(center.x - point.x);
		var py:Float = FastMath.abs(center.y - point.y);
		var pz:Float = FastMath.abs(center.z - point.z);
		return px < xExtent && py < yExtent && pz < zExtent;
	}

	override public function intersectsPoint(point:Vector3f):Bool
	{
		var px:Float = FastMath.abs(center.x - point.x);
		var py:Float = FastMath.abs(center.y - point.y);
		var pz:Float = FastMath.abs(center.z - point.z);
		return px < xExtent && py < yExtent && pz < zExtent;
	}

	override public function distanceToEdge(point:Vector3f):Float
	{
		// compute coordinates of point in box coordinate system
		//var closest:Vector3f = point.subtract(center);
		var closestX:Float = point.x - center.x;
		var closestY:Float = point.y - center.y;
		var closestZ:Float = point.z - center.z;

		// project test point onto box
		var sqrDistance:Float = 0.0;
		var delta:Float;

		if (closestX < -xExtent)
		{
			delta = closestX + xExtent;
			sqrDistance += delta * delta;
			closestX = -xExtent;
		}
		else if (closestX > xExtent)
		{
			delta = closestX - xExtent;
			sqrDistance += delta * delta;
			closestX = xExtent;
		}

		if (closestY < -yExtent)
		{
			delta = closestY + yExtent;
			sqrDistance += delta * delta;
			closestY = -yExtent;
		}
		else if (closestY > yExtent)
		{
			delta = closestY - yExtent;
			sqrDistance += delta * delta;
			closestY = yExtent;
		}

		if (closestZ < -zExtent)
		{
			delta = closestZ + zExtent;
			sqrDistance += delta * delta;
			closestZ = -zExtent;
		}
		else if (closestZ > zExtent)
		{
			delta = closestZ - zExtent;
			sqrDistance += delta * delta;
			closestZ = zExtent;
		}

		return Math.sqrt(sqrDistance);
	}

	/**
	 * `clip` determines if a line segment intersects the current
	 * test plane.
	 *
	 * @param denom
	 *            the denominator of the line segment.
	 * @param numer
	 *            the numerator of the line segment.
	 * @param t
	 *            test values of the plane.
	 * @return true if the line segment intersects the plane, false otherwise.
	 */
	private function clip(denom:Float, numer:Float, t:Vector<Float>):Bool
	{
		// Return value is 'true' if line segment intersects the current test
		// plane. Otherwise 'false' is returned in which case the line segment
		// is entirely clipped.
		if (denom > 0.0)
		{
			// This is the old if statement...
            // if (numer > denom * t[1]) {
            //
            // The problem is that what is actually stored is
            // numer/denom.  In non-floating point, this math should
            // work out the same but in floating point there can
            // be subtle math errors.  The multiply will exaggerate
            // errors that may have been introduced when the value
            // was originally divided.  
            //
            // This is especially true when the bounding box has zero
            // extents in some plane because the error rate is critical.
            // comparing a to b * c is not the same as comparing a/b to c
            // in this case.  In fact, I tried converting this method to 
            // double and the and the error was in the last decimal place. 
            //
            // So, instead, we now compare the divided version to the divided
            // version.  We lose some slight performance here as divide
            // will be more expensive than the divide.  Some microbenchmarks
            // show divide to be 3x slower than multiple on Java 1.6.
            // BUT... we also saved a multiply in the non-clipped case because 
            // we can reuse the divided version in both if checks.
            // I think it's better to be right in this case.
            //
            // Bug that I'm fixing: rays going right through quads at certain
            // angles and distances because they fail the bounding box test.
            // Many Bothans died bring you this fix. 
            //    -pspeed  
			var newT:Float = numer / denom;
            if (newT > t[1]) 
			{
                return false;
            }
            if (newT > t[0])
			{
                t[0] = newT;
            }
			return true;
		}
		else if (denom < 0.0)
		{
			// Old if statement... see above
            // if (numer > denom * t[0]) {
            //
            // Note though that denom is always negative in this block.
            // When we move it over to the other side we have to flip
            // the comparison.  Algebra for the win.
            var newT:Float = numer / denom;
            if (newT < t[0]) 
			{            
                return false;
            }
            if (newT < t[1]) 
			{
                t[1] = newT;
            }
			return true;
		}
		else
		{
			return numer <= 0.0;
		}
	}

	/**
	 * Query extent.
	 *
	 * @param store
	 *            where extent gets stored - null to return a new vector
	 * @return store / new vector
	 */
	public function getExtent(result:Vector3f = null):Vector3f
	{
		if (result == null)
			result = new Vector3f();

		result.setTo(xExtent, yExtent, zExtent);
		return result;
	}

	public function getMin(result:Vector3f = null):Vector3f
	{
		if (result == null)
			result = new Vector3f();

		result.x = center.x - xExtent;
		result.y = center.y - yExtent;
		result.z = center.z - zExtent;
		return result;
	}

	public function getMax(result:Vector3f = null):Vector3f
	{
		if (result == null)
			result = new Vector3f();

		result.x = center.x + xExtent;
		result.y = center.y + yExtent;
		result.z = center.z + zExtent;

		return result;
	}

	override public function getVolume():Float
	{
		return (8 * xExtent * yExtent * zExtent);
	}

}

