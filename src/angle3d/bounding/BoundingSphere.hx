package angle3d.bounding;

import angle3d.collision.Collidable;
import angle3d.collision.CollisionResult;
import angle3d.collision.CollisionResults;
import angle3d.math.FastMath;
import angle3d.math.Matrix4f;
import angle3d.math.Plane;
import angle3d.math.PlaneSide;
import angle3d.math.Ray;
import angle3d.math.Transform;
import angle3d.math.Triangle;
import angle3d.math.Vector3f;
import angle3d.scene.Spatial;
import angle3d.utils.BufferUtils;
import angle3d.utils.Logger;
import angle3d.utils.TempVars;
import haxe.ds.Vector;

/**
 * BoundingSphere defines a sphere that defines a container for a
 * group of vertices of a particular piece of geometry. This sphere defines a
 * radius and a center. <br>
 * <br>
 * A typical usage is to allow the class define the center and radius by calling
 * either containAABB or averagePoints. A call to
 * computeFramePoint in turn calls `containAABB`.
 *
 */
class BoundingSphere extends BoundingVolume {
	private static inline var RADIUS_EPSILON:Float = 1.00001;

	public var radius:Float;

	/**
	 * Constructor instantiates a new `BoundingSphere` object.
	 *
	 * @param r
	 *            the radius of the sphere.
	 * @param c
	 *            the center of the sphere.
	 */
	public function new(r:Float = 0, center:Vector3f = null) {
		super(center);
		this.type = BoundingVolumeType.Sphere;
		this.radius = r;
	}

	/**
	 * `computeFromPoints` creates a new Bounding Sphere from a
	 * given set_of points. It uses the `calcWelzl` method as
	 * default.
	 *
	 * @param points
	 *            the points to contain.
	 */
	override public function computeFromPoints(points:Array<Float>):Void {
		calcWelzl(points);
	}

	/**
	 * `computeFromTris` creates a new Bounding Box from a given
	 * set_of triangles. It is used in OBBTree calculations.
	 *
	 * @param tris
	 * @param start
	 * @param end
	 */
	public function computeFromTris(tris:Array<Triangle>, start:Int, end:Int):Void {
		if (end - start <= 0) {
			return;
		}

		var vertList:Array<Vector3f> = new Array<Vector3f>();
		var count:Int = 0;
		for (i in start...end) {
			vertList[count++] = tris[i].point1;
			vertList[count++] = tris[i].point2;
			vertList[count++] = tris[i].point3;
		}
		averagePoints(vertList);
	}

	/**
	 * Calculates a minimum bounding sphere for the set_of points. The algorithm
	 * was originally found at
	 * http://www.flipcode.com/cgi-bin/msg.cgi?showThread=COTD-SmallestEnclosingSpheres&forum=cotd&id=-1
	 * in C++ and translated to java by Cep21
	 *
	 * @param points
	 *            The points to calculate the minimum bounds from.
	 */
	public function calcWelzl(points:Array<Float>):Void {
		if (center == null)
			center = new Vector3f();
		recurseMini(points, Std.int(points.length / 3), 0, 0);
	}

	/**
	 * Used from calcWelzl. This function recurses to calculate a minimum
	 * bounding sphere a few points at a time.
	 *
	 * @param points
	 *            The array of points to look through.
	 * @param p
	 *            The size of the list to be used.
	 * @param b
	 *            The Float of points currently considering to include with the
	 *            sphere.
	 * @param ap
	 *            A variable simulating pointer arithmatic from C++, and offset
	 *            in `points`.
	 */

	private function recurseMini(points:Array<Float>, p:Int, b:Int, ap:Int):Void {
		var tempA:Vector3f = new Vector3f();
		var tempB:Vector3f = new Vector3f();
		var tempC:Vector3f = new Vector3f();
		var tempD:Vector3f = new Vector3f();
		switch (b) {
			case 0:
				this.radius = 0;
				this.center.setTo(0, 0, 0);
			case 1:
				this.radius = 1 - RADIUS_EPSILON;
				BufferUtils.populateFromBuffer(center, points, ap - 1);
			case 2:
				BufferUtils.populateFromBuffer(tempA, points, ap - 1);
				BufferUtils.populateFromBuffer(tempB, points, ap - 2);
				setSphere2(tempA, tempB);
			case 3:
				BufferUtils.populateFromBuffer(tempA, points, ap - 1);
				BufferUtils.populateFromBuffer(tempB, points, ap - 2);
				BufferUtils.populateFromBuffer(tempC, points, ap - 3);
				setSphere3(tempA, tempB, tempC);
			case 4:
				BufferUtils.populateFromBuffer(tempA, points, ap - 1);
				BufferUtils.populateFromBuffer(tempB, points, ap - 2);
				BufferUtils.populateFromBuffer(tempC, points, ap - 3);
				BufferUtils.populateFromBuffer(tempD, points, ap - 4);
				setSphere4(tempA, tempB, tempC, tempD);
				return;
		}

		for (i in 0...p) {
			BufferUtils.populateFromBuffer(tempA, points, i + ap);
			if (tempA.distanceSquared(center) - (radius * radius) > RADIUS_EPSILON - 1) {
				var j:Int = i;
				while (j > 0) {
					BufferUtils.populateFromBuffer(tempB, points, j + ap);
					BufferUtils.populateFromBuffer(tempC, points, j - 1 + ap);
					BufferUtils.setInBuffer(tempC, points, j + ap);
					BufferUtils.setInBuffer(tempB, points, j - 1 + ap);
					j--;
				}
				recurseMini(points, i, b + 1, ap + 1);
			}
		}
	}

	/**
	 * Calculates the minimum bounding sphere of 4 points. Used in welzl's algorithm.
	 *
	 * @param O
	 *            The 1st point inside the sphere.
	 * @param A
	 *            The 2nd point inside the sphere.
	 * @param B
	 *            The 3rd point inside the sphere.
	 * @param C
	 *            The 4th point inside the sphere.
	 */
	private function setSphere4(D:Vector3f, A:Vector3f, B:Vector3f, C:Vector3f):Void {
		var a:Vector3f = A.subtract(D);
		var b:Vector3f = B.subtract(D);
		var c:Vector3f = C.subtract(D);

		var denominator:Float = 2.0 * (a.x * (b.y * c.z - c.y * b.z) -
		b.x * (a.y * c.z - c.y * a.z) +
		c.x * (a.y * b.z - b.y * a.z));
		if (denominator == 0) {
			center.setTo(0, 0, 0);
			radius = 0;
		} else {
			//var t:Vector3f = a.cross(b).scaleBy(c.lengthSquared()).incrementBy(
			//c.cross(a).scaleBy(b.lengthSquared())).incrementBy(
			//b.cross(c).scaleBy(a.lengthSquared())).scaleBy(
			//1/Denominator);

			var cca:Vector3f = c.cross(a);
			var bcc:Vector3f = b.cross(c);
			var t:Vector3f = a.cross(b);

			var aLenSqr:Float = a.lengthSquared;
			var bLenSqr:Float = b.lengthSquared;
			var cLenSqr:Float = c.lengthSquared;

			denominator = 1 / denominator;

			t.x = (t.x * cLenSqr + cca.x * bLenSqr + bcc.x * aLenSqr) * denominator;
			t.y = (t.y * cLenSqr + cca.y * bLenSqr + bcc.y * aLenSqr) * denominator;
			t.z = (t.z * cLenSqr + cca.z * bLenSqr + bcc.z * aLenSqr) * denominator;

			radius = t.length * RADIUS_EPSILON;
			center.x = D.x + t.x;
			center.y = D.y + t.y;
			center.z = D.z + t.z;
		}
	}

	/**
	 * Calculates the minimum bounding sphere of 3 points. Used in welzl's algorithm.
	 *
	 * @param D
	 *            The 1st point inside the sphere.
	 * @param A
	 *            The 2nd point inside the sphere.
	 * @param B
	 *            The 3rd point inside the sphere.
	 */
	private function setSphere3(D:Vector3f, A:Vector3f, B:Vector3f):Void {
		var a:Vector3f = A.subtract(D);
		var b:Vector3f = B.subtract(D);
		var acrossB:Vector3f = a.subtract(b);

		var denominator:Float = 2.0 * acrossB.dot(acrossB);

		if (denominator == 0) {
			center.setTo(0, 0, 0);
			radius = 0;
		} else {
			//var t = acrossB.cross(a).multLocal(b.lengthSquared()).addLocal(b.cross(acrossB).multLocal(a.lengthSquared())).divideLocal(Denominator);

			var bcaB:Vector3f = b.cross(acrossB);
			var t:Vector3f = acrossB.cross(a);

			var aLenSqr:Float = a.lengthSquared;
			var bLenSqr:Float = b.lengthSquared;

			denominator = 1 / denominator;

			t.x = (t.x * bLenSqr + bcaB.x * aLenSqr) * denominator;
			t.y = (t.y * bLenSqr + bcaB.y * aLenSqr) * denominator;
			t.z = (t.z * bLenSqr + bcaB.z * aLenSqr) * denominator;

			radius = t.length * RADIUS_EPSILON;
			center.x = D.x + t.x;
			center.y = D.y + t.y;
			center.z = D.z + t.z;
		}
	}

	/**
	 * Calculates the minimum bounding sphere of 2 points. Used in welzl's algorithm.
	 *
	 * @param O
	 *            The 1st point inside the sphere.
	 * @param A
	 *            The 2nd point inside the sphere.
	 */
	private function setSphere2(D:Vector3f, A:Vector3f):Void {
		var ADx:Float = A.x - D.x;
		var ADy:Float = A.y - D.y;
		var ADz:Float = A.z - D.z;

		radius = Math.sqrt((ADx * ADx + ADy * ADy + ADz * ADz) * 0.25) + RADIUS_EPSILON - 1;

		center.lerp(D, A, 0.5);
	}

	/**
	 * `averagePoints` selects the sphere center to be the average
	 * of the points and the sphere radius to be the smallest value to enclose
	 * all points.
	 *
	 * @param points
	 *            the list of points to contain.
	 */
	public function averagePoints(points:Array<Vector3f>):Void {
		#if debug
		Logger.log("Bounding Sphere calculated using average points.");
		#end

		center.copyFrom(points[0]);

		var len:Int = points.length;
		for (i in 1...len) {
			center.addLocal(points[i]);
		}

		var quantity:Float = 1.0 / points.length;
		center.scaleLocal(quantity);

		var diff:Vector3f = new Vector3f();
		var maxRadiusSqr:Float = 0;
		len = points.length;
		for (i in 1...len) {
			diff = points[i].subtract(center, diff);
			var radiusSqr:Float = diff.lengthSquared;
			if (radiusSqr > maxRadiusSqr) {
				maxRadiusSqr = radiusSqr;
			}
		}

		radius = Math.sqrt(maxRadiusSqr) + RADIUS_EPSILON - 1;
	}

	/**
	 * transform modifies the center of the sphere to reflect the
	 * change made via a rotation, translation and scale.
	 *
	 * @param rotate
	 *            the rotation change.
	 * @param translate
	 *            the translation change.
	 * @param scale
	 *            the size change.
	 * @param store
	 *            sphere to store result in
	 * @return BoundingVolume
	 */
	override public function transform(trans:Transform, result:BoundingVolume = null):BoundingVolume {
		var sphere:BoundingSphere;
		if (result == null || result.type != BoundingVolumeType.Sphere) {
			sphere = new BoundingSphere();
		} else
		{
			sphere = Std.instance(result, BoundingSphere);
		}

		center.mult(trans.scale, sphere.center);
		trans.rotation.multVector(sphere.center, sphere.center);
		sphere.center.addLocal(trans.translation);
		sphere.radius = FastMath.abs(getMaxAxis(trans.scale) * radius) + RADIUS_EPSILON - 1;
		return sphere;
	}

	override public function transformMatrix(trans:Matrix4f, result:BoundingVolume = null):BoundingVolume {
		var sphere:BoundingSphere;
		if (result == null || result.type != BoundingVolumeType.Sphere) {
			sphere = new BoundingSphere();
		} else
		{
			sphere = Std.instance(result, BoundingSphere);
		}

		trans.multVec(center, sphere.center);

		var axes:Vector3f = new Vector3f(1, 1, 1);

		trans.multVec(axes, axes);

		var ax:Float = getMaxAxis(axes);

		sphere.radius = FastMath.abs(ax * radius) + RADIUS_EPSILON - 1;

		return sphere;
	}

	private function getMaxAxis(scale:Vector3f):Float {
		var x:Float = FastMath.abs(scale.x);
		var y:Float = FastMath.abs(scale.y);
		var z:Float = FastMath.abs(scale.z);

		if (x >= y) {
			if (x >= z)
				return x;
			return z;
		}

		if (y >= z)
			return y;

		return z;
	}

	/**
	 * `whichSide` takes a plane (typically provided by a view
	 * frustum) to determine which side this bound is on.
	 *
	 * @param plane
	 *            the plane to check against.
	 * @return side
	 */
	override public function whichSide(plane:Plane):PlaneSide {
		var distance:Float = plane.pseudoDistance(center);

		if (distance <= -radius) {
			return PlaneSide.Negative;
		} else if (distance >= radius) {
			return PlaneSide.Positive;
		} else
		{
			return PlaneSide.None;
		}
	}

	/**
	* `merge` combines this sphere with a second bounding sphere.
	* This new sphere contains both bounding spheres and is returned.
	*
	* @param volume
	*            the sphere to combine with this sphere.
	* @return a new sphere
	*/
	override public function merge(volume:BoundingVolume):BoundingVolume {
		switch (volume.type) {
			case BoundingVolumeType.AABB: {
					var box:BoundingBox = cast volume;
					var radVect:Vector3f = box.getExtent();
					return mergeSphere(radVect.length, box.center);
				}
			case BoundingVolumeType.Sphere: {
					var sphere:BoundingSphere = cast volume;
					return mergeSphere(sphere.radius, sphere.center);
				}
		}
		return null;
	}

	override public function mergeLocal(volume:BoundingVolume):Void {
		switch (volume.type) {
			case BoundingVolumeType.AABB:
				var box:BoundingBox = cast volume;
				var radVect:Vector3f = box.getExtent();
				mergeSphere(radVect.length, box.center, this);
			case BoundingVolumeType.Sphere:
				var sphere:BoundingSphere = cast volume;
				mergeSphere(sphere.radius, sphere.center, this);
		}
	}

	public function mergeSphere(temp_radius:Float, temp_center:Vector3f, result:BoundingSphere = null):BoundingSphere {
		if (result == null) {
			result = new BoundingSphere();
		}

		var diff:Vector3f = temp_center.subtract(center);

		var lengthSquared:Float = diff.lengthSquared;
		var radiusDiff:Float = temp_radius - radius;

		var fRDiffSqr:Float = radiusDiff * radiusDiff;

		if (fRDiffSqr >= lengthSquared) {
			if (radiusDiff <= 0.0) {
				return result;
			}

			result.center.copyFrom(temp_center);
			result.radius = temp_radius;
			return result;
		}

		var length:Float = Math.sqrt(lengthSquared);
		if (length > RADIUS_EPSILON) {
			var coeff:Float = (length + radiusDiff) / (2.0 * length);
			result.center.x = center.x + diff.x * coeff;
			result.center.y = center.y + diff.y * coeff;
			result.center.z = center.z + diff.z * coeff;
		} else
		{
			result.center.copyFrom(center);
		}

		result.radius = 0.5 * (length + radius + temp_radius);

		return result;
	}

	override public function clone(result:BoundingVolume = null):BoundingVolume {
		var sphere:BoundingSphere;
		if (result == null || !Std.is(result,BoundingSphere)) {
			sphere = new BoundingSphere();
		} else
		{
			sphere = cast result;
		}

		sphere = cast super.clone(sphere);

		sphere.radius = radius;
		sphere.center.copyFrom(center);
		sphere.checkPlane = checkPlane;
		return sphere;
	}

	public function toString():String {
		return "BoundingSphere [Radius: " + radius + " Center: " + center + "]";
	}

	override public function intersects(bv:BoundingVolume):Bool {
		return bv.intersectsSphere(this);
	}

	override public function intersectsSphere(bs:BoundingSphere):Bool {
		return Intersection.intersectSphereSphere(bs, this.center, this.radius);
	}

	override public function intersectsBoundingBox(bb:BoundingBox):Bool {
		return Intersection.intersectBoxSphere(bb, this.center, this.radius);
	}

	override public function intersectsRay(ray:Ray):Bool {
		//var diff:Vector3f = ray.origin.subtract(center);
		var dx:Float = ray.origin.x - center.x;
		var dy:Float = ray.origin.y - center.y;
		var dz:Float = ray.origin.z - center.z;
		var diffSquared:Float = dx * dx + dy * dy + dz * dz;

		var radiusSquared:Float = radius * radius;
		var a:Float = diffSquared - radiusSquared;
		if (a <= 0.0) {
			// in sphere
			return true;
		}

		// outside sphere
		var b:Float = ray.direction.x * dx + ray.direction.y * dy + ray.direction.z * dz;
		if (b >= 0.0) {
			return false;
		}
		return b * b >= a;
	}

	public function collideWithRay(ray:Ray, results:CollisionResults):Int {
		var point:Vector3f;
		var dist:Float;

		//var diff:Vector3f = ray.origin.subtract(center);
		var dx:Float = ray.origin.x - center.x;
		var dy:Float = ray.origin.y - center.y;
		var dz:Float = ray.origin.z - center.z;
		var diffSquared:Float = dx * dx + dy * dy + dz * dz;

		var radiusSquared:Float = radius * radius;
		var a:Float = diffSquared - radiusSquared;
		var a1:Float, discr:Float, root:Float;
		if (a <= 0.0) {
			// inside sphere
			//ray.direction.dot(diff)
			a1 = ray.direction.x * dx + ray.direction.y * dy + ray.direction.z * dz;
			discr = (a1 * a1) - a;
			root = Math.sqrt(discr);

			var distance:Float = root - a1;
			point = ray.direction.clone();
			point.scaleAdd(distance, ray.origin);

			var result:CollisionResult = new CollisionResult();
			result.contactPoint = point;
			result.distance = distance;
			results.addCollision(result);
			return 1;
		}

		a1 = ray.direction.x * dx + ray.direction.y * dy + ray.direction.z * dz;
		if (a1 >= 0.0) {
			return 0;
		}

		discr = a1 * a1 - a;
		if (discr < 0.0) {
			return 0;
		} else if (discr >= FastMath.ZERO_TOLERANCE) {
			root = Math.sqrt(discr);
			dist = -a1 - root;
			point = ray.direction.clone();
			point.scaleAdd(dist, ray.origin);
			var cr:CollisionResult = new CollisionResult();
			cr.contactPoint = point;
			cr.distance = dist;
			results.addCollision(cr);

			dist = -a1 + root;
			point = ray.direction.clone();
			point.scaleAdd(dist, ray.origin);
			cr = new CollisionResult();
			cr.contactPoint = point;
			cr.distance = dist;
			results.addCollision(cr);
			return 2;
		} else
		{
			dist = -a1;
			point = ray.direction.clone();
			point.scaleAdd(dist, ray.origin);
			var cr:CollisionResult = new CollisionResult();
			cr.contactPoint = point;
			cr.distance = dist;
			results.addCollision(cr);
			return 1;
		}
	}

	public function collideWithTri(tri:Triangle, results:CollisionResults):Int {
		// Much of this is based on adaptation from this algorithm:
		// http://realtimecollisiondetection.net/blog/?p=103
		// ...mostly the stuff about eliminating sqrts wherever
		// possible.

		var tvars:TempVars = TempVars.getTempVars();

		// Math is done in center-relative space.
		var a:Vector3f = tri.point1.subtract(center, tvars.vect1);
		var b:Vector3f = tri.point2.subtract(center, tvars.vect2);
		var c:Vector3f = tri.point3.subtract(center, tvars.vect3);

		var ab:Vector3f = b.subtract(a, tvars.vect4);
		var ac:Vector3f = c.subtract(a, tvars.vect5);

		// Check the plane... if it doesn't intersect the plane
		// then it doesn't intersect the triangle.
		var n:Vector3f = ab.cross(ac, tvars.vect6);
		var d:Float = a.dot(n);
		var e:Float = n.dot(n);
		if ( d * d > radius * radius * e ) {
			// Can't possibly intersect
			return 0;
		}

		// We intersect the verts, or the edges, or the face...

		// First check against the face since it's the most
		// specific.

		// Calculate the barycentric coordinates of the
		// sphere center
		var v0:Vector3f = ac;
		var v1:Vector3f = ab;
		// a was P relative, so p.subtract(a) is just -a
		// instead of wasting a vector we'll just negate the
		// dot products below... it's all v2 is used for.
		var v2:Vector3f = a;

		var dot00:Float = v0.dot(v0);
		var dot01:Float = v0.dot(v1);
		var dot02:Float = -v0.dot(v2);
		var dot11:Float = v1.dot(v1);
		var dot12:Float = -v1.dot(v2);

		var invDenom:Float = 1 / (dot00 * dot11 - dot01 * dot01);
		var u:Float = (dot11 * dot02 - dot01 * dot12) * invDenom;
		var v:Float = (dot00 * dot12 - dot01 * dot02) * invDenom;

		if ( u >= 0 && v >= 0 && (u + v) <= 1 ) {
			// We intersect... and we even know where
			var part1:Vector3f = ac;
			var part2:Vector3f = ab;
			var p:Vector3f = center.add(a.add(part1.scale(u)).addLocal(part2.scale(v)));

			var r:CollisionResult = new CollisionResult();
			var normal:Vector3f = n.normalize();
			var dist:Float = -normal.dot(a);  // a is center relative, so -a points to center
			dist = dist - radius;

			r.distance = dist;
			r.contactNormal = normal;
			r.contactPoint = p;
			results.addCollision(r);

			tvars.release();
			return 1;
		}

		// Check the edges looking for the nearest point
		// that is also less than the radius.  We don't care
		// about points that are farther away than that.
		var nearestPt:Vector3f = null;
		var nearestDist:Float = radius * radius;

		var base:Vector3f;
		var edge:Vector3f;
		var t:Float;

		// Edge AB
		base = a;
		edge = ab;

		t = -edge.dot(base) / edge.dot(edge);
		if ( t >= 0 && t <= 1 ) {
			//var Q:Vector3f = base.add(edge.scale(t, tvars.vect7), tvars.vect8);
			var Q:Vector3f = tvars.vect7;
			Q.x = base.x + edge.x * t;
			Q.y = base.y + edge.y * t;
			Q.z = base.z + edge.z * t;

			var distSq = Q.dot(Q); // distance squared to origin
			if ( distSq < nearestDist ) {
				nearestPt = Q;
				nearestDist = distSq;
			}
		}

		// Edge AC
		base = a;
		edge = ac;

		t = -edge.dot(base) / edge.dot(edge);
		if ( t >= 0 && t <= 1 ) {
			//var Q:Vector3f = base.add(edge.scale(t, tvars.vect7), tvars.vect9);
			var Q:Vector3f = tvars.vect8;
			Q.x = base.x + edge.x * t;
			Q.y = base.y + edge.y * t;
			Q.z = base.z + edge.z * t;

			var distSq:Float = Q.dot(Q); // distance squared to origin
			if ( distSq < nearestDist ) {
				nearestPt = Q;
				nearestDist = distSq;
			}
		}

		// Edge BC
		base = b;
		var bc:Vector3f = c.subtract(b);
		edge = bc;

		t = -edge.dot(base) / edge.dot(edge);
		if ( t >= 0 && t <= 1 ) {
			//var Q:Vector3f = base.add(edge.scale(t, tvars.vect7), tvars.vect10);
			var Q:Vector3f = tvars.vect9;
			Q.x = base.x + edge.x * t;
			Q.y = base.y + edge.y * t;
			Q.z = base.z + edge.z * t;

			var distSq:Float = Q.dot(Q); // distance squared to origin
			if ( distSq < nearestDist ) {
				nearestPt = Q;
				nearestDist = distSq;
			}
		}

		// If we have a point at all then it is going to be
		// closer than any vertex to center distance... so we're
		// done.
		if ( nearestPt != null ) {
			// We have a hit
			var dist:Float = Math.sqrt(nearestDist);
			var cn:Vector3f = nearestPt.scale(-1/dist);

			var r = new CollisionResult();
			r.distance = (dist - radius);
			r.contactNormal  = (cn);
			r.contactPoint = (nearestPt.add(center));
			results.addCollision(r);

			tvars.release();
			return 1;
		}

		// Finally check each of the triangle corners

		// Vert A
		base = a;
		t = base.dot(base); // distance squared to origin
		if ( t < nearestDist ) {
			nearestDist = t;
			nearestPt = base;
		}

		// Vert B
		base = b;
		t = base.dot(base); // distance squared to origin
		if ( t < nearestDist ) {
			nearestDist = t;
			nearestPt = base;
		}

		// Vert C
		base = c;
		t = base.dot(base); // distance squared to origin
		if ( t < nearestDist ) {
			nearestDist = t;
			nearestPt = base;
		}

		if ( nearestPt != null ) {
			// We have a hit
			var dist:Float = Math.sqrt(nearestDist);
			var cn:Vector3f = nearestPt.scale(-1/dist);

			var r:CollisionResult = new CollisionResult();
			r.distance = (dist - radius);
			r.contactNormal = (cn);
			r.contactPoint = (nearestPt.add(center));
			results.addCollision(r);

			tvars.release();
			return 1;
		}

		// Nothing hit... oh, well
		tvars.release();
		return 0;
	}

	override public function collideWith(other:Collidable, results:CollisionResults):Int {
		if (Std.is(other,Ray)) {
			return collideWithRay(cast other, results);
		} else if (Std.is(other, Triangle)) {
			return collideWithTri(cast other, results);
		} else if (Std.is(other, BoundingVolume)) {
			if (intersects(cast other)) {
				var r:CollisionResult = new CollisionResult();
				results.addCollision(r);
				return 1;
			}
			return 0;
		} else if (Std.is(other, Spatial)) {
			return cast(other, Spatial).collideWith(this, results);
		} else
		{
			throw new Error("Unsupported Collision Object");
		}
	}

	private function collideWithRayNoResult(ray:Ray):Int {
		//var diff:Vector3f = vars.vect1.copyFrom(ray.getOrigin()).subtractLocal(center);

		var dx:Float = ray.origin.x - center.x;
		var dy:Float = ray.origin.y - center.y;
		var dz:Float = ray.origin.z - center.z;
		var diffSquared:Float = dx * dx + dy * dy + dz * dz;

		var a:Float = diffSquared - (radius * radius);
		var a1:Float, discr:Float;
		if (a <= 0.0) {
			// inside sphere
			return 1;
		}

		a1 = ray.direction.x * dx + ray.direction.y * dy + ray.direction.z * dz;
		if (a1 >= 0.0) {
			return 0;
		}

		discr = a1 * a1 - a;
		if (discr < 0.0) {
			return 0;
		} else if (discr >= FastMath.ZERO_TOLERANCE) {
			return 2;
		}
		return 1;
	}

	override public function collideWithNoResult(other:Collidable):Int {
		if (Std.is(other, Ray)) {
			var ray:Ray = cast other;
			return collideWithRayNoResult(ray);
		} else if (Std.is(other, Triangle)) {
			return super.collideWithNoResult(other);
		} else if (Std.is(other, BoundingVolume)) {
			return intersects(cast other) ? 1 : 0;
		} else
		{
			throw "UnsupportedCollisionException With: " + Type.getClassName(Type.getClass(other));
		}

		return 0;
	}

	override public function contains(point:Vector3f):Bool {
		return center.distanceSquared(point) < radius * radius;
	}

	override public function intersectsPoint(point:Vector3f):Bool {
		return center.distanceSquared(point) <= radius * radius;
	}

	override public function distanceToEdge(point:Vector3f):Float {
		return center.distance(point) - radius;
	}

	//TODO 这里是如何计算的？
	override public function getVolume():Float {
		return 4 * (1 / 3) * Math.PI * radius * radius * radius;
	}
}

