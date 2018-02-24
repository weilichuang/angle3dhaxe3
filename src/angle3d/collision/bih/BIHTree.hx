package angle3d.collision.bih;

import angle3d.bounding.BoundingBox;
import angle3d.bounding.BoundingSphere;
import angle3d.bounding.BoundingVolume;
import angle3d.collision.Collidable;
import angle3d.collision.CollisionData;
import angle3d.collision.CollisionResults;
import angle3d.math.FastMath;
import angle3d.math.Matrix4f;
import angle3d.math.Ray;
import angle3d.math.Vector3f;
import angle3d.scene.mesh.BufferType;
import angle3d.scene.mesh.Mesh;
import angle3d.utils.TempVars;

class BIHTree implements CollisionData {
	public static inline var MAX_TREE_DEPTH:Int = 100;
	public static inline var MAX_TRIS_PER_NODE:Int = 21;

	private var root:BIHNode;

	private var numTris:Int;
	private var maxTrisPerNode:Int;

	private var mesh:Mesh;

	private var pointData:Array<Float>;
	private var triIndices:Array<Int>;

	private var boundResults:CollisionResults;
	private var bihSwapTmp:Array<Float>;

	public function new(mesh:Mesh, maxTrisPerNode:Int = 100) {
		this.mesh = mesh;
		this.maxTrisPerNode = maxTrisPerNode;

		#if debug
		if (maxTrisPerNode < 1) {
			throw "maxTrisPerNode cannot be less than 1";
		}

		if (mesh == null) {
			throw "Mesh cannot be null";
		}
		#end

		boundResults = new CollisionResults();
		bihSwapTmp = new Array<Float>(9);

		var vertices:Array<Float> = mesh.getVertexBuffer(BufferType.POSITION).getData();
		var indices:Array<UInt> = mesh.getIndices();

		numTris = Std.int(indices.length / 3);
		initTriList(vertices, indices);
	}

	private function initTriList(vertices:Array<Float>, indices:Array<UInt>):Void {
		pointData = new Array<Float>(numTris * 3 * 3);
		var p:Int = 0;
		var count:Int = numTris * 3;
		var i:Int = 0;
		while (i < count) {
			var vert:Int = indices[i] * 3;

			pointData[p++] = vertices[vert++];
			pointData[p++] = vertices[vert++];
			pointData[p++] = vertices[vert];

			vert = indices[i + 1] * 3;
			pointData[p++] = vertices[vert++];
			pointData[p++] = vertices[vert++];
			pointData[p++] = vertices[vert];

			vert = indices[i + 2] * 3;
			pointData[p++] = vertices[vert++];
			pointData[p++] = vertices[vert++];
			pointData[p++] = vertices[vert];

			i += 3;
		}

		triIndices = new Array<Int>(numTris);
		for (i in 0...numTris) {
			triIndices[i] = i;
		}
	}

	public function construct():Void {
		var sceneBbox:BoundingBox = createBox(0, numTris - 1);
		root = createNode(0, numTris - 1, sceneBbox, 0);
	}

	private function createBox(l:Int, r:Int):BoundingBox {
		var vars:TempVars = TempVars.getTempVars();

		var min:Vector3f = vars.vect1.copyFrom(new Vector3f(FastMath.POSITIVE_INFINITY, FastMath.POSITIVE_INFINITY, FastMath.POSITIVE_INFINITY));
		var max:Vector3f = vars.vect2.copyFrom(new Vector3f(FastMath.NEGATIVE_INFINITY, FastMath.NEGATIVE_INFINITY, FastMath.NEGATIVE_INFINITY));

		var v1:Vector3f = vars.vect3;
		var v2:Vector3f = vars.vect4;
		var v3:Vector3f = vars.vect5;

		for (i in l...r + 1) {
			getTriangle(i, v1, v2, v3);
			Vector3f.checkMinMax(min, max, v1);
			Vector3f.checkMinMax(min, max, v2);
			Vector3f.checkMinMax(min, max, v3);
		}

		var bbox:BoundingBox = new BoundingBox();
		bbox.setMinMax(min, max);

		vars.release();

		return bbox;
	}

	public function getTriangleIndex(triIndex:Int):Int {
		return triIndices[triIndex];
	}

	private function sortTriangles(l:Int, r:Int, split:Float, axis:Int):Int {
		var pivot:Int = l;
		var j:Int = r;

		var vars:TempVars = TempVars.getTempVars();

		var v1:Vector3f = vars.vect1;
		var v2:Vector3f = vars.vect2;
		var v3:Vector3f = vars.vect3;

		while (pivot <= j) {
			getTriangle(pivot, v1, v2, v3);
			v1.addLocal(v2).addLocal(v3).scaleLocal(FastMath.ONE_THIRD);
			if (v1.getValueAt(axis) > split) {
				swapTriangles(pivot, j);
				--j;
			} else {
				++pivot;
			}
		}

		vars.release();
		pivot = (pivot == l && j < pivot) ? j : pivot;
		return pivot;
	}

	private function setMinMax(bbox:BoundingBox, doMin:Bool, axis:Int, value:Float):Void {
		var min:Vector3f = bbox.getMin(null);
		var max:Vector3f = bbox.getMax(null);

		if (doMin) {
			min.setValueAt(axis, value);
		} else
		{
			max.setValueAt(axis, value);
		}

		bbox.setMinMax(min, max);
	}

	private function getMinMax(bbox:BoundingBox, doMin:Bool, axis:Int):Float {
		if (doMin) {
			return bbox.getMin(null).getValueAt(axis);
		} else
		{
			return bbox.getMax(null).getValueAt(axis);
		}
	}

	private function createNode(l:Int, r:Int, nodeBbox:BoundingBox, depth:Int):BIHNode {
		if ((r - l) < maxTrisPerNode || depth > MAX_TREE_DEPTH) {
			return new BIHNode(l, r);
		}

		var currentBox:BoundingBox = createBox(l, r);

		var exteriorExt:Vector3f = nodeBbox.getExtent(null);
		var interiorExt:Vector3f = currentBox.getExtent(null);
		exteriorExt.subtractLocal(interiorExt);

		var axis:Int = 0;
		if (exteriorExt.x > exteriorExt.y) {
			if (exteriorExt.x > exteriorExt.z) {
				axis = 0;
			} else {
				axis = 2;
			}
		} else
		{
			if (exteriorExt.y > exteriorExt.z) {
				axis = 1;
			} else
			{
				axis = 2;
			}
		}

		if (exteriorExt.isZero()) {
			axis = 0;
		}

//        Arrays.sort(tris, l, r, comparators[axis]);
		var split:Float = currentBox.getCenter().getValueAt(axis);
		var pivot:Int = sortTriangles(l, r, split, axis);
		if (pivot == l || pivot == r) {
			pivot = Std.int((r + l) / 2);
		}

		var lbbox:BoundingBox;
		var rbbox:BoundingBox;
		//If one of the partitions is empty, continue with recursion: same level but different bbox
		if (pivot < l) {
			//Only right
			rbbox = Std.instance(currentBox.clone(), BoundingBox);
			setMinMax(rbbox, true, axis, split);
			return createNode(l, r, rbbox, depth + 1);
		} else if (pivot > r) {
			//Only left
			lbbox = Std.instance(currentBox.clone(), BoundingBox);
			setMinMax(lbbox, false, axis, split);
			return createNode(l, r, lbbox, depth + 1);
		} else
		{
			//Build the node
			var node:BIHNode = new BIHNode(-1, -1);
			node.axis = axis;

			//Left child
			lbbox = Std.instance(currentBox.clone(), BoundingBox);
			setMinMax(lbbox, false, axis, split);

			//The left node right border is the plane most right
			node.leftPlane = getMinMax(createBox(l, FastMath.maxInt(l, pivot - 1)), false, axis);
			node.left = createNode(l, FastMath.maxInt(l, pivot - 1), lbbox, depth + 1); //Recursive call

			//Right Child
			rbbox = Std.instance(currentBox.clone(), BoundingBox);
			setMinMax(rbbox, true, axis, split);
			//The right node left border is the plane most left
			node.rightPlane = getMinMax(createBox(pivot, r), true, axis);
			node.right = createNode(pivot, r, rbbox, depth + 1); //Recursive call

			return node;
		}
	}

	public function getTriangle(index:Int, v1:Vector3f, v2:Vector3f, v3:Vector3f):Void {
		var pointIndex:Int = index * 9;

		v1.x = pointData[pointIndex++];
		v1.y = pointData[pointIndex++];
		v1.z = pointData[pointIndex++];

		v2.x = pointData[pointIndex++];
		v2.y = pointData[pointIndex++];
		v2.z = pointData[pointIndex++];

		v3.x = pointData[pointIndex++];
		v3.y = pointData[pointIndex++];
		v3.z = pointData[pointIndex++];
	}

	public function swapTriangles(index1:Int, index2:Int):Void {
		var p1:Int = index1 * 9;
		var p2:Int = index2 * 9;

		var i:Int;

		// store p1 in tmp
		for (i in 0...9) {
			bihSwapTmp[i] = pointData[p1 + i];
		}

		// copy p2 to p1
		for (i in 0...9) {
			pointData[p1 + i] = pointData[p2 + i];
		}

		// copy tmp to p2
		for (i in 0...9) {
			pointData[p2 + i] = bihSwapTmp[i];
		}

		// swap indices
		var tmp2:Int = triIndices[index1];
		triIndices[index1] = triIndices[index2];
		triIndices[index2] = tmp2;
	}

	private function collideWithRay(r:Ray,
									worldMatrix:Matrix4f,
									worldBound:BoundingVolume,
									results:CollisionResults):Int {
		boundResults.clear();
		worldBound.collideWith(r, boundResults);
		if (boundResults.size > 0) {
			var tMin:Float = boundResults.getClosestCollision().distance;
			var tMax:Float = boundResults.getFarthestCollision().distance;

			if (tMax <= 0) {
				tMax = FastMath.POSITIVE_INFINITY;
			} else if (tMin == tMax) {
				tMin = 0;
			}

			if (tMin <= 0) {
				tMin = 0;
			}

			if (r.getLimit() < FastMath.POSITIVE_INFINITY) {
				tMax = Math.min(tMax, r.getLimit());
				if (tMin > tMax) {
					return 0;
				}
			}

			//            return root.intersectBrute(r, worldMatrix, this, tMin, tMax, results);
			return root.intersectWhere2(r, worldMatrix, this, tMin, tMax, results);
		}
		return 0;
	}

	private function collideWithBoundingVolume(bv:BoundingVolume,
			worldMatrix:Matrix4f,results:CollisionResults):Int {
		var bbox:BoundingBox = null;
		if (Std.is(bv,BoundingSphere)) {
			var sphere:BoundingSphere = Std.instance(bv,BoundingSphere);
			bbox = new BoundingBox(bv.center.clone());
			bbox.setExtent(sphere.radius, sphere.radius, sphere.radius);
		} else if (Std.is(bv,BoundingBox)) {
			bbox = Std.instance(bv.clone(), BoundingBox);
		} else
		{
			throw "BoundingVolume:" + Std.string(bv);
		}

		bbox.transformMatrix(worldMatrix.invert(), bbox);
		return root.intersectWhere(bv, bbox, worldMatrix, this, results);
	}

	public function collideWith(other:Collidable,worldMatrix:Matrix4f,
								worldBound:BoundingVolume,results:CollisionResults):Int {
		if (Std.is(other,Ray)) {
			var ray:Ray = Std.instance(other, Ray);
			return collideWithRay(ray, worldMatrix, worldBound, results);
		} else if (Std.is(other,BoundingVolume)) {
			var bv:BoundingVolume = Std.instance(other, BoundingVolume);
			return collideWithBoundingVolume(bv, worldMatrix, results);
		} else
		{
			return -1;
		}
	}
}

