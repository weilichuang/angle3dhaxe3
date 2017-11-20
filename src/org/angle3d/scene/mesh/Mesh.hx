package org.angle3d.scene.mesh;

import org.angle3d.bounding.BoundingBox;
import org.angle3d.bounding.BoundingVolume;
import org.angle3d.collision.Collidable;
import org.angle3d.collision.CollisionData;
import org.angle3d.collision.CollisionResults;
import org.angle3d.collision.bih.BIHTree;
import org.angle3d.error.Assert;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Triangle;
import org.angle3d.math.Vector2f;
import org.angle3d.utils.BufferUtils;

using org.angle3d.utils.VectorUtil;

/**
 * Mesh is used to store rendering data.
 * <p>
 * All visible elements in a scene are represented by meshes.
 */
class Mesh {
	public var id:String;

	public var extra:Dynamic;

	public var type:MeshType;

	private var collisionTree:CollisionData;

	/**
	 * The bounding volume that contains the mesh entirely.
	 * By default a BoundingBox (AABB).
	 */
	private var mBound:BoundingVolume;
	private var mBoundDirty:Bool;

	private var mBufferMap:Array<VertexBuffer>;

	private var mIndices:Array<UInt>;

	private var maxNumWeights:Int = -1;// only if using skeletal animation

	private var mVertCount:Int = 0;
	private var mElementCount:Int = 0;

	//Lods
	private var lodLevels:Array<Array<UInt>>;
	private var numLodLevel:Int = 0;

	public function new() {
		type = MeshType.STATIC;

		mBound = new BoundingBox();

		mBufferMap = new Array<VertexBuffer>();
	}

	/**
	 * Determines if the mesh uses bone animation.
	 *
	 * A mesh uses bone animation if it has bone index / weight buffers
	 *
	 * @return true if the mesh uses bone animation, false otherwise
	 */
	public inline function isAnimated():Bool {
		return getVertexBuffer(BufferType.BONE_INDICES) != null;
	}

	/**
	 * Prepares the mesh for software skinning by converting the bone index
	 * and weight buffers to heap buffers.
	 *
	 * @param forSoftwareAnim Should be true to enable the conversion.
	 */
	public function prepareForAnim(forSoftwareAnim:Bool):Void {

	}

	public function generateBindPose(forSoftwareAnim:Bool):Void {

	}

	public inline function setLodLevels(lodLevels:Array<Array<UInt>>):Void {
		this.lodLevels = lodLevels;
		this.numLodLevel = lodLevels != null ? lodLevels.length : 0;
	}

	public inline function getNumLodLevels():Int {
		return numLodLevel;
	}

	public inline function getLodLevel(lod:Int):Array<UInt> {
		return lodLevels[lod];
	}

	public function getTriangle(index:Int, store:Triangle):Void {
		var pb:VertexBuffer = getVertexBuffer(BufferType.POSITION);
		if (pb != null && mIndices != null) {
			var vertices:Array<Float> = pb.getData();
			var vertIndex:Int = index * 3;
			for (i in 0...3) {
				BufferUtils.populateFromBuffer(store.getPoint(i), vertices, mIndices[vertIndex + i]);
			}
		}
	}

	public function updateCounts():Void {
		var pb:VertexBuffer = getVertexBuffer(BufferType.POSITION);
		if (pb != null)
			mVertCount = Std.int(pb.getData().length / pb.components);

		mElementCount = Std.int(mIndices.length / 3);
	}

	/**
	 * Indicates to the GPU that this mesh will not be modified (a hint).
	 * Sets the usage mode to `Usage.Static`
	 * for all vertex buffers on this Mesh.
	 */
	public function setStatic():Void {
		for (i in 0...mBufferMap.length) {
			var vb:VertexBuffer = mBufferMap[i];
			if (vb != null)
				vb.setUsage(Usage.STATIC);
		}
	}

	/**
	 * Indicates to the GPU that this mesh will be modified occasionally (a hint).
	 * Sets the usage mode to `Usage.Dynamic`
	 * for all vertex buffers on this Mesh.
	 */
	public function setDynamic():Void {
		for (i in 0...mBufferMap.length) {
			var vb:VertexBuffer = mBufferMap[i];
			if (vb != null)
				vb.setUsage(Usage.DYNAMIC);
		}
	}

	public function validate():Void {
		updateBound();
		updateCounts();
	}

	/**
	 * Updates the bounding volume of this mesh.
	 * The method does nothing if the mesh has no Position buffer.
	 * It is expected that the position buffer is a float buffer with 3 components.
	 */
	public function updateBound():Void {
		var vb:VertexBuffer = getVertexBuffer(BufferType.POSITION);
		if (mBound != null && vb != null) {
			mBound.computeFromPoints(vb.getData());
		}
	}

	/**
	 * Sets the {BoundingVolume} for this Mesh.
	 * The bounding volume is recomputed by calling {#updateBound() }.
	 *
	 * @param modelBound The model bound to set
	 */
	public function setBound(bound:BoundingVolume):Void {
		mBound = bound;
		mBoundDirty = false;
	}

	/**
	 * Returns the `BoundingVolume` of this Mesh.
	 * By default the bounding volume is a `BoundingBox`.
	 *
	 * @return the bounding volume of this mesh
	 */
	public function getBound():BoundingVolume {
		return mBound;
	}

	/**
	 * Returns the maximum number of weights per vertex on this mesh.
	 *
	 * @return maximum number of weights per vertex
	 *
	 * @see `setMaxNumWeights`
	 */
	public function getMaxNumWeights():Int {
		return maxNumWeights;
	}

	/**
	 * Set the maximum number of weights per vertex on this mesh.
	 * Only relevant if this mesh has bone index/weight buffers.
	 * This value should be between 0 and 4.
	 *
	 * @param maxNumWeights
	 */
	public function setMaxNumWeights(maxNumWeights:Int):Void {
		this.maxNumWeights = maxNumWeights;
	}

	/**
	 * Generates a collision tree for the mesh.
	 */
	public function createCollisionData():Void {
		var tree:BIHTree = new BIHTree(this);
		tree.construct();
		collisionTree = tree;
	}

	/**
	 * Clears any previously generated collision data.  Use this if
	 * the mesh has changed in some way that invalidates any previously
	 * generated BIHTree.
	 */
	public function clearCollisionData():Void {
		collisionTree = null;
	}

	public function collideWith(other:Collidable, worldMatrix:Matrix4f, worldBound:BoundingVolume, results:CollisionResults):Int {
		if (collisionTree == null) {
			createCollisionData();
		}

		return collisionTree.collideWith(other, worldMatrix, worldBound, results);
	}

	public inline function getVertexCount():Int {
		return mVertCount;
	}

	public function getTriangleCount(lod:Int = 0):Int {
		if (lodLevels != null) {
			if (lod < 0)
				throw "LOD level cannot be < 0";

			if (lod >= lodLevels.length)
				throw "LOD level " + lod + " does not exist!";

			return Std.int(lodLevels[lod].length / 3);
		} else if (lod == 0) {
			return mElementCount;
		} else
		{
			throw "There are no LOD levels on the mesh!";
		}
		return 0;
	}

	public inline function getVertexBuffer(type:Int):VertexBuffer {
		return mBufferMap[type];
	}

	public function createVertexBuffer(type:Int,numComponents:Int):Void {
		var vb:VertexBuffer = mBufferMap[type];
		if (vb == null) {
			vb = new VertexBuffer(type,numComponents);
			mBufferMap[type] = vb;
		}
	}

	/**
	 * Unsets the {VertexBuffer} set on this mesh
	 * with the given type. Does nothing if the vertex buffer type is not set
	 * initially.
	 *
	 * @param type The buffer type to remove
	 */
	public function clearBuffer(type:Int):Void {
		var vb:VertexBuffer = mBufferMap[type];
		if (vb != null) {
			mBufferMap[type] = null;
			updateCounts();
		}
	}

	public function setVertexBuffer(type:Int, components:Int, data:Array<Float>):Void {
		#if debug
		Assert.assert(data != null, "data can not be null");
		#end

		var vb:VertexBuffer = mBufferMap[type];
		if (vb == null) {
			vb = new VertexBuffer(type,components);
			mBufferMap[type] = vb;
		}

		vb.updateData(data);
	}

	public function setVertexBufferDirect(buffer:VertexBuffer):Void {
		mBufferMap[buffer.type] = buffer;
	}

	public function scaleTextureCoordinates(scaleFactor:Vector2f):Void {
		var vb:VertexBuffer = mBufferMap[BufferType.TEXCOORD];
		if (vb == null)
			return;

		var sx:Float = scaleFactor.x;
		var sy:Float = scaleFactor.y;

		var data:Array<Float> = vb.getData();
		var i:Int = 0;
		while (i < data.length) {
			data[i + 0] *= sx;
			data[i + 1] *= sy;
			i += 2;
		}
		vb.updateData(data);
	}

	public function getBufferList():Array<VertexBuffer> {
		return mBufferMap;
	}

	public function setIndices(indices:Array<UInt>):Void {
		mIndices = indices;
	}

	public function getIndices():Array<UInt> {
		return mIndices;
	}

	public function dispose():Void {
	}
}

