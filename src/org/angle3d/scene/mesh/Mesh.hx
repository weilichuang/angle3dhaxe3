package org.angle3d.scene.mesh;

import flash.display3D.Context3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.Vector;
import haxe.ds.StringMap;
import org.angle3d.bounding.BoundingBox;
import org.angle3d.bounding.BoundingVolume;
import org.angle3d.collision.bih.BIHTree;
import org.angle3d.collision.Collidable;
import org.angle3d.collision.CollisionData;
import org.angle3d.collision.CollisionResults;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Triangle;

import org.angle3d.utils.Assert;

using org.angle3d.math.VectorUtil;

/**
 * <code>Mesh</code> is used to store rendering data.
 * <p>
 * All visible elements in a scene are represented by meshes.
 * 
 */
class Mesh
{
	public var type:MeshType;
	
	private var collisionTree:CollisionData;
	
	/**
	 * The bounding volume that contains the mesh entirely.
	 * By default a BoundingBox (AABB).
	 */
	private var mBound:BoundingVolume;

	private var mBoundDirty:Bool;

	private var mBufferMap:StringMap<VertexBuffer>;

	private var mIndices:Vector<UInt>;
	private var mIndexBuffer3D:IndexBuffer3D;

	private var _vertexBuffer3DMap:StringMap<VertexBuffer3D>;

	public function new()
	{
		type = MeshType.STATIC;

		mBound = new BoundingBox();
		
		mBufferMap = new StringMap<VertexBuffer>();
	}

	public function getTriangle(index:Int, store:Triangle):Void
	{
		var pb:VertexBuffer = getVertexBuffer(BufferType.POSITION);
		if (pb != null && mIndices != null)
		{
			var vertices:Vector<Float> = pb.getData();
			var vertIndex:Int = index * 3;
			for (i in 0...3)
			{
				BufferUtils.populateFromBuffer(store.getPoint(i), vertices, mIndices[vertIndex + i]);
			}
		}
	}

	public function validate():Void
	{
		updateBound();
	}
	
	/**
	 * Updates the bounding volume of this mesh.
	 * The method does nothing if the mesh has no Position buffer.
	 * It is expected that the position buffer is a float buffer with 3 components.
	 */
	public function updateBound():Void
	{
		//if (!mBoundDirty)
			//return;

		var vb:VertexBuffer = getVertexBuffer(BufferType.POSITION);
		if (mBound != null && vb != null)
		{
			mBound.computeFromPoints(vb.getData());
		}

		//mBoundDirty = false;
	}

	/**
	 * Sets the {@link BoundingVolume} for this Mesh.
	 * The bounding volume is recomputed by calling {@link #updateBound() }.
	 *
	 * @param modelBound The model bound to set
	 */
	public function setBound(bound:BoundingVolume):Void
	{
		mBound = bound;
		mBoundDirty = false;
	}

	/**
	 * Returns the {@link BoundingVolume} of this Mesh.
	 * By default the bounding volume is a {@link BoundingBox}.
	 *
	 * @return the bounding volume of this mesh
	 */
	public function getBound():BoundingVolume
	{
		return mBound;
	}
	
	/**
	 * Generates a collision tree for the mesh.
	 */
	private function createCollisionData():Void
	{
		var tree:BIHTree = new BIHTree(this);
		tree.construct();
		collisionTree = tree;
	}

	/**
     * Clears any previously generated collision data.  Use this if
     * the mesh has changed in some way that invalidates any previously
     * generated BIHTree.
     */
	public function clearCollisionData():Void 
	{
		collisionTree = null;
	}

	public function collideWith(other:Collidable, worldMatrix:Matrix4f, worldBound:BoundingVolume, results:CollisionResults):Int
	{
		if (collisionTree == null)
		{
			createCollisionData();
		}

		return collisionTree.collideWith(other, worldMatrix, worldBound, results);
	}

	public function getIndexBuffer3D(context:Context3D):IndexBuffer3D
	{
		if (mIndexBuffer3D == null)
		{
			mIndexBuffer3D = context.createIndexBuffer(mIndices.length);
			mIndexBuffer3D.uploadFromVector(mIndices, 0, mIndices.length);
		}
		return mIndexBuffer3D;
	}

	/**
	 * 不同Shader可能会生成不同的VertexBuffer3D
	 *
	 */
	public function getVertexBuffer3D(context:Context3D, type:String):VertexBuffer3D
	{
		var vertCount:Int;
		
		if (_vertexBuffer3DMap == null)
			_vertexBuffer3DMap = new StringMap<VertexBuffer3D>();

		var buffer3D:VertexBuffer3D;
		var buffer:VertexBuffer;

		buffer = getVertexBuffer(type);
		//buffer更改过数据，需要重新上传数据
		if (buffer.dirty)
		{
			vertCount = getVertexCount();

			buffer3D = _vertexBuffer3DMap.get(type);
			if (buffer3D == null)
			{
				buffer3D = context.createVertexBuffer(vertCount, buffer.components);
				_vertexBuffer3DMap.set(type,buffer3D);
			}

			buffer3D.uploadFromVector(buffer.getData(), 0, vertCount);

			buffer.dirty = false;
		}
		else
		{
			buffer3D = _vertexBuffer3DMap.get(type);
			if (buffer3D == null)
			{
				vertCount = getVertexCount();
				buffer3D = context.createVertexBuffer(vertCount, buffer.components);
				_vertexBuffer3DMap.set(type,buffer3D);

				buffer3D.uploadFromVector(buffer.getData(), 0, vertCount);
			}
		}

		return buffer3D;
	}

	public function getVertexCount():Int
	{
		var pb:VertexBuffer = getVertexBuffer(BufferType.POSITION);
		if (pb != null)
			return pb.count;
		return 0;
	}
	
	public function getTriangleCount():Int
	{
		return Std.int(mIndices.length / 3);
	}
	
	private function _getData32PerVertex():Int
	{
		var count:Int = 0;

		var TYPES:Array<String> = BufferType.VERTEX_TYPES;
		var TYPES_SIZE:Int = TYPES.length;
		for (j in 0...TYPES_SIZE)
		{
			var buffer:VertexBuffer = mBufferMap.get(TYPES[j]);
			if (buffer != null)
			{
				count += buffer.components;
			}
		}
		return count;
	}
	
	public function getVertexBuffer(type:String):VertexBuffer
	{
		return mBufferMap.get(type);
	}

	public function setVertexBuffer(type:String, components:Int, data:Vector<Float>):Void
	{
		Assert.assert(data != null, "data can not be null");

		var vb:VertexBuffer = mBufferMap.get(type);
		if (vb == null)
		{
			vb = new VertexBuffer(type);
			mBufferMap.set(type,vb);
		}

		vb.setData(data, components);
	}

	public function setIndices(indices:Vector<UInt>):Void
	{
		mIndices = indices;

		if (mIndexBuffer3D != null)
		{
			mIndexBuffer3D.dispose();
			mIndexBuffer3D = null;
		}
	}

	public function getIndices():Vector<UInt>
	{
		return mIndices;
	}
}

