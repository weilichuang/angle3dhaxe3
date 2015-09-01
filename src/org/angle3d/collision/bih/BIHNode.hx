package org.angle3d.collision.bih;

import org.angle3d.bounding.BoundingBox;
import org.angle3d.collision.Collidable;
import org.angle3d.collision.CollisionResult;
import org.angle3d.collision.CollisionResults;
import org.angle3d.math.FastMath;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Ray;
import org.angle3d.math.Triangle;
import org.angle3d.math.Vector3f;
import org.angle3d.utils.TempVars;
import flash.Vector;

/**
 * Bounding Interval Hierarchy.
 * Based on:
 *
 * Instant Ray Tracing: The Bounding Interval Hierarchy
 * By Carsten Wächter and Alexander Keller
 */
class BIHNode
{
	public var leftIndex:Int;
	public var rightIndex:Int;

	public var left:BIHNode;
	public var right:BIHNode;

	public var leftPlane:Float;
	public var rightPlane:Float;
	public var axis:Int;

	public function new(left:Int, right:Int)
	{
		this.leftIndex = left;
		this.rightIndex = right;
		axis = 3; //indicates leaf
	}

	public function intersectWhere(col:Collidable, box:BoundingBox, worldMatrix:Matrix4f,
		tree:BIHTree, results:CollisionResults):Int
	{
		var vars:TempVars = TempVars.getTempVars();
		var stack:Array<BIHStackData> = new Array<BIHStackData>();
		
		var minExts:Vector<Float> = Vector.ofArray([box.center.x - box.xExtent,
			box.center.y - box.yExtent,
			box.center.z - box.zExtent]);

		var maxExts:Vector<Float> = Vector.ofArray([box.center.x + box.xExtent,
			box.center.y + box.yExtent,
			box.center.z + box.zExtent]);

		stack.push(new BIHStackData(this, 0, 0));

		var t:Triangle = new Triangle();
		var cols:Int = 0;

		//由于haXe不支持label for，因此需要使用一个布尔值来跳转
		var jumpToStackloop:Bool = false;
		//stackloop
		while (stack.length > 0)
		{
			var node:BIHNode = stack.pop().node;

			while (node.axis != 3)
			{
				var a:Int = node.axis;

				var maxExt:Float = maxExts[a];
				var minExt:Float = minExts[a];

				if (node.leftPlane < node.rightPlane)
				{
					// means there's a gap in the middle
					// if the box is in that gap, we stop there
					if (minExt > node.leftPlane &&
						maxExt < node.rightPlane)
					{
						jumpToStackloop = true;
						continue;
					}
				}

				if (maxExt < node.rightPlane)
				{
					node = node.left;
				}
				else if (minExt > node.leftPlane)
				{
					node = node.right;
				}
				else
				{
					stack.push(new BIHStackData(node.right, 0, 0));
					node = node.left;
				}
				//if (maxExt < node.leftPlane
				 //&& maxExt < node.rightPlane){
					//node = node.left;
				//}else if (minExt > node.leftPlane
					   //&& minExt > node.rightPlane){
					//node = node.right;
				//}else{
//
				//}
			}
			
			if (jumpToStackloop)
			{
				jumpToStackloop = false;
				continue;
			}

			for (i in node.leftIndex...node.rightIndex + 1)
			{
				tree.getTriangle(i, t.point1, t.point2, t.point3);
				if (worldMatrix != null)
				{
					worldMatrix.multVec(t.point1, t.point1);
					worldMatrix.multVec(t.point2, t.point2);
					worldMatrix.multVec(t.point3, t.point3);
				}

				var added:Int = col.collideWith(t, results);

				if (added > 0)
				{
					var index:Int = tree.getTriangleIndex(i);
					var start:Int = results.size - added;

					for (j in start...results.size)
					{
						var cr:CollisionResult = results.getCollisionDirect(j);
						cr.triangleIndex = index;
					}

					cols += added;
				}
			}
		}
		vars.release();
		return cols;
	}

	public function intersectWhere2(r:Ray, worldMatrix:Matrix4f, tree:BIHTree,
									sceneMin:Float, sceneMax:Float,
									results:CollisionResults):Int
	{
		var vars:TempVars = TempVars.getTempVars();
		
		var stack:Array<BIHStackData> = new Array<BIHStackData>();

		//        float tHit = Float.POSITIVE_INFINITY;

		var o:Vector3f = vars.vect1.copyFrom(r.origin);
		var d:Vector3f = vars.vect2.copyFrom(r.direction);

		var inv:Matrix4f = vars.tempMat4.copyFrom(worldMatrix).invertLocal();

		inv.multVec(r.origin, r.origin);

		// Fixes rotation collision bug
		inv.multNormal(r.direction, r.direction);
		//        inv.multNormalAcross(r.direction, r.direction);

		var origins:Vector<Float> = Vector.ofArray([r.origin.x, r.origin.y, r.origin.z]);

		var invDirections:Vector<Float> = Vector.ofArray([1 / r.direction.x, 1 / r.direction.y, 1 / r.direction.z]);

		r.direction.normalizeLocal();

		var v1:Vector3f = vars.vect3;
		var v2:Vector3f = vars.vect4;
		var v3:Vector3f = vars.vect5;
		var cols:Int = 0;
		stack.push(new BIHStackData(this, sceneMin, sceneMax));

		//由于haXe不支持label for，因此需要使用一个布尔值来跳转
		var jumpToStackloop:Bool = false;
		//stackloop
		while (stack.length > 0)
		{
			var data:BIHStackData = stack.pop();
			var node:BIHNode = data.node;
			var tMin:Float = data.min;
			var tMax:Float = data.max;

			if (tMax < tMin)
			{
				continue;
			}

			while (node.axis != 3)
			{
				//while node is not a leaf
				var a:Int = node.axis;

				// find the origin and direction value for the given axis
				var origin:Float = origins[a];
				var invDirection:Float = invDirections[a];

				var tNearSplit:Float, tFarSplit:Float;
				var nearNode:BIHNode, farNode:BIHNode;

				tNearSplit = (node.leftPlane - origin) * invDirection;
				tFarSplit = (node.rightPlane - origin) * invDirection;
				nearNode = node.left;
				farNode = node.right;

				if (invDirection < 0)
				{
					var tmpSplit:Float = tNearSplit;
					tNearSplit = tFarSplit;
					tFarSplit = tmpSplit;

					var tmpNode:BIHNode = nearNode;
					nearNode = farNode;
					farNode = tmpNode;
				}

				if (tMin > tNearSplit && tMax < tFarSplit)
				{
					jumpToStackloop = true;
					continue;
				}

				if (tMin > tNearSplit)
				{
					tMin = Math.max(tMin, tFarSplit);
					node = farNode;
				}
				else if (tMax < tFarSplit)
				{
					tMax = Math.min(tMax, tNearSplit);
					node = nearNode;
				}
				else
				{
					stack.push(new BIHStackData(farNode, Math.max(tMin, tFarSplit), tMax));
					tMax = Math.min(tMax, tNearSplit);
					node = nearNode;
				}
			}
			
			if (jumpToStackloop)
			{
				jumpToStackloop = false;
				continue;
			}

//			if ((node.rightIndex - node.leftIndex) > minTrisPerNode)
//			{
//              // on demand subdivision
//              node.subdivide();
//              stack.add(new BIHStackData(node, tMin, tMax));
//              continue stackloop;
//          }

			// a leaf
			for (i in node.leftIndex...node.rightIndex + 1)
			{
				tree.getTriangle(i, v1, v2, v3);

				var t:Float = r.intersects2(v1, v2, v3);
				if (Math.isFinite(t))
				{
					if (worldMatrix != null)
					{
						worldMatrix.multVec(v1, v1);
						worldMatrix.multVec(v2, v2);
						worldMatrix.multVec(v3, v3);
						var t_world:Float = new Ray(o, d).intersects2(v1, v2, v3);
						t = t_world;
					}

					var contactNormal:Vector3f = Triangle.computeTriangleNormal(v1, v2, v3, null);
					var contactPoint:Vector3f = d.clone().scaleLocal(t).addLocal(o);
					var worldSpaceDist:Float = o.distance(contactPoint);

					var cr:CollisionResult = new CollisionResult();
					cr.contactPoint = contactPoint;
					cr.distance = worldSpaceDist;
					cr.contactNormal = contactNormal;
					cr.triangleIndex = tree.getTriangleIndex(i);
					results.addCollision(cr);
					cols++;
				}
			}
		}

		r.setOrigin(o);
		r.setDirection(d);
		vars.release();

		return cols;
	}

	public function intersectBrute(r:Ray, worldMatrix:Matrix4f, tree:BIHTree,
								sceneMin:Float, sceneMax:Float,results:CollisionResults):Int
	{
		var tHit:Float = FastMath.POSITIVE_INFINITY;

		var vars:TempVars = TempVars.getTempVars();

		var v1:Vector3f = vars.vect1;
		var v2:Vector3f = vars.vect2;
		var v3:Vector3f = vars.vect3;

		var cols:Int = 0;

		var stack:Array<BIHStackData> = new Array<BIHStackData>();
		stack.push(new BIHStackData(this, 0, 0));

		while (stack.length > 0)
		{
			var data:BIHStackData = stack.pop();
			var node:BIHNode = data.node;

			while (node.axis != 3)
			{
				//whilenode is not a leaf
				var nearNode:BIHNode, farNode:BIHNode;
				nearNode = node.left;
				farNode = node.right;

				stack.push(new BIHStackData(farNode, 0, 0));
				node = nearNode;
			}

			//a leaf
			for (i in node.leftIndex...node.rightIndex + 1)
			{
				tree.getTriangle(i, v1, v2, v3);

				if (worldMatrix != null)
				{
					worldMatrix.multVec(v1, v1);
					worldMatrix.multVec(v2, v2);
					worldMatrix.multVec(v3, v3);
				}

				var t:Float = r.intersects2(v1, v2, v3);
				if (t < tHit)
				{
					tHit = t;
					var contactPoint:Vector3f = r.direction.clone().scaleLocal(tHit).addLocal(r.origin);
					var cr:CollisionResult = new CollisionResult();
					cr.contactPoint = contactPoint;
					cr.distance = tHit;
					cr.triangleIndex = tree.getTriangleIndex(i);
					results.addCollision(cr);
					cols++;
				}
			}
		}

		vars.release();
		return cols;
	}
}

