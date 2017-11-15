package org.angle3d.bullet.control.ragdoll ;

import haxe.ds.IntMap;
import org.angle3d.animation.Bone;
import org.angle3d.animation.Skeleton;
import org.angle3d.bullet.collision.shapes.HullCollisionShape;
import org.angle3d.bullet.joints.SixDofJoint;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Transform;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.Node;
import org.angle3d.scene.Spatial;

class RagdollUtils {

	public static function setJointLimit(joint:SixDofJoint, maxX:Float, minX:Float, maxY:Float, minY:Float, maxZ:Float, minZ:Float):Void {
		joint.getRotationalLimitMotor(0).setHiLimit(maxX);
		joint.getRotationalLimitMotor(0).setLoLimit(minX);
		joint.getRotationalLimitMotor(1).setHiLimit(maxY);
		joint.getRotationalLimitMotor(1).setLoLimit(minY);
		joint.getRotationalLimitMotor(2).setHiLimit(maxZ);
		joint.getRotationalLimitMotor(2).setLoLimit(minZ);
	}

	public static function buildPointMap(model:Spatial):IntMap<Array<Float>> {
		var map:IntMap<Array<Float>>  = new IntMap<Array<Float>> ();
		if (Std.is(model, Geometry)) {
			var g:Geometry = cast model;
			buildPointMapForMesh(g.getMesh(), map);
		} else if (Std.is(model,Node)) {
			var node:Node = cast model;
			for ( s in node.children) {
				if (Std.is(s, Geometry)) {
					var g:Geometry = cast s;
					buildPointMapForMesh(g.getMesh(), map);
				}
			}
		}
		return map;
	}

	private static function buildPointMapForMesh(mesh:Mesh, map:IntMap<Array<Float>> ):IntMap<Array<Float>> {
		var vertices:Array<Float> = mesh.getVertexBuffer(BufferType.POSITION).getData();
		var boneIndices:Array<Float> = mesh.getVertexBuffer(BufferType.BONE_INDICES).getData();
		var boneWeight:Array<Float> = mesh.getVertexBuffer(BufferType.BONE_WEIGHTS).getData();

		var vertexComponents:Int = mesh.getVertexCount() * 3;
		var k:Int, start:Int, index:Int;
		var maxWeight:Float = 0;

		var i:Int = 0;
		while (i < vertexComponents) {
			start = Std.int(i / 3) * 4;
			index = 0;
			maxWeight = -1;
			for (k in start...(start + 40)) {
				var weight:Float = boneWeight[k];
				if (weight > maxWeight) {
					maxWeight = weight;
					index = Std.int(boneIndices[k]);
				}
			}
			var points:Array<Float> = map.get(index);
			if (points == null) {
				points = new Array<Float>();
				map.set(index, points);
			}
			points.push(vertices[i]);
			points.push(vertices[i + 1]);
			points.push(vertices[i + 2]);

			i += 3;
		}
		return map;
	}

	/**
	 * Create a hull collision shape from linked vertices to this bone.
	 * Vertices have to be previoulsly gathered in a map using buildPointMap method
	 *
	 * @param pointsMap
	 * @param boneIndices
	 * @param initialScale
	 * @param initialPosition
	 * @return
	 */
	public static function makeShapeFromPointMap(pointsMap:IntMap<Array<Float>>,
			boneIndices:Array<Float>,
			initialScale:Vector3f,
			initialPosition:Vector3f):HullCollisionShape {

		var points:Array<Float> = new Array<Float>();

		for (i in 0...boneIndices.length) {
			var index:Int = Std.int(boneIndices[i]);

			var l:Array<Float> = pointsMap.get(index);
			if (l != null) {
				var j:Int = 0;
				while (j < l.length) {
					var pos:Vector3f = new Vector3f();
					pos.x = l[i];
					pos.y = l[i + 1];
					pos.z = l[i + 2];
					pos.subtractLocal(initialPosition).multLocal(initialScale);
					points.push(pos.x);
					points.push(pos.y);
					points.push(pos.z);

					j += 3;
				}
			}
		}

		var shape:HullCollisionShape = new HullCollisionShape();
		shape.fromPoints(points);

		return shape;
	}

	//retruns the list of bone indices of the given bone and its child(if they are not in the boneList)
	public static function getBoneIndices(bone:Bone, skeleton:Skeleton, boneList:Array<String>):Array<Float> {
		var list:Array<Float> = new Array<Float>();
		if (boneList.length == 0) {
			list.push(skeleton.getBoneIndex(bone));
		} else
		{
			list.push(skeleton.getBoneIndex(bone));
			for (chilBone in bone.children) {
				if (boneList.indexOf(chilBone.name) == -1) {
					list = list.concat(getBoneIndices(chilBone, skeleton, boneList));
				}
			}
		}
		return list;
	}

	/**
	 * Create a hull collision shape from linked vertices to this bone.
	 *
	 * @param model
	 * @param boneIndices
	 * @param initialScale
	 * @param initialPosition
	 * @param weightThreshold
	 * @return
	 */
	public static function makeShapeFromVerticeWeights(model:Spatial, boneIndices:Array<Float>,
			initialScale:Vector3f,
			initialPosition:Vector3f,
			weightThreshold:Float):HullCollisionShape {

		var points:Array<Float> = new Array<Float>();
		if (Std.is(model, Geometry)) {
			var g:Geometry = cast model;
			for (i in 0...boneIndices.length) {
				var index:Float = boneIndices[i];
				points = points.concat(getPoints(g.getMesh(), index, initialScale, initialPosition, weightThreshold));
			}
		} else if (Std.is(model, Node)) {
			var node:Node = cast model;
			for (s in node.children) {
				if (Std.is(s, Geometry)) {
					var g:Geometry = cast s;
					for (i in 0...boneIndices.length) {
						var index:Float = boneIndices[i];
						points = points.concat(getPoints(g.getMesh(), index, initialScale, initialPosition, weightThreshold));
					}
				}
			}
		}

		var shape:HullCollisionShape = new HullCollisionShape();
		shape.fromPoints(points);

		return shape;
	}

	/**
	 * returns a list of points for the given bone
	 * @param mesh
	 * @param boneIndex
	 * @param offset
	 * @param link
	 * @return
	 */
	private static function getPoints(mesh:Mesh, boneIndex:Float, initialScale:Vector3f, offset:Vector3f, weightThreshold:Float):Array<Float> {
		var vertices:Array<Float> = mesh.getVertexBuffer(BufferType.POSITION).getData();
		var boneIndices:Array<Float> = mesh.getVertexBuffer(BufferType.BONE_INDICES).getData();
		var boneWeight:Array<Float> = mesh.getVertexBuffer(BufferType.BONE_WEIGHTS).getData();

		var results:Array<Float> = new Array<Float>();

		var vertexComponents:Int = mesh.getVertexCount() * 3;

		var i:Int = 0;
		while (i < vertexComponents) {
			var add:Bool = false;
			var start = Std.int(i / 3) * 4;
			for (k in start...(start + 4)) {
				if (boneIndices[k] == boneIndex && boneWeight[k] >= weightThreshold) {
					add = true;
					break;
				}
			}

			if (add) {
				var pos:Vector3f = new Vector3f();
				pos.x = vertices[i];
				pos.y = vertices[i + 1];
				pos.z = vertices[i + 2];
				pos.subtractLocal(offset).multLocal(initialScale);
				results.push(pos.x);
				results.push(pos.y);
				results.push(pos.z);

			}
			i += 3;
		}

		return results;
	}

	/**
	 * Updates a bone position and rotation.
	 * if the child bones are not in the bone list this means, they are not associated with a physic shape.
	 * So they have to be updated
	 * @param bone the bone
	 * @param pos the position
	 * @param rot the rotation
	 */
	public static function setTransform(bone:Bone, pos:Vector3f, rot:Quaternion, restoreBoneControl:Bool, boneList:Array<String>):Void {
		//we ensure that we have the control
		if (restoreBoneControl) {
			bone.setUserControl(true);
		}
		//we set te user transforms of the bone
		bone.setUserTransformsInModelSpace(pos, rot);

		var t:Transform = new Transform();
		for (childBone in bone.children) {
			//each child bone that is not in the list is updated
			if (boneList.indexOf(childBone.name) == -1) {
				t = childBone.getCombinedTransform(pos, rot, t);
				setTransform(childBone, t.translation, t.rotation, restoreBoneControl, boneList);
			}
		}
		//we give back the control to the keyframed animation
		if (restoreBoneControl) {
			bone.setUserControl(false);
		}
	}

	public static function setUserControl(bone:Bone, bool:Bool):Void {
		bone.setUserControl(bool);
		for (child in bone.children) {
			setUserControl(child, bool);
		}
	}
}
