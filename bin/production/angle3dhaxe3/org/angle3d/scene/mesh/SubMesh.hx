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


/**
 * SubMesh is used to store rendering data.
 * <p>
 * All visible elements in a scene are represented by meshes.
 */
//TODO 目前有个问题，Shader中Attribute的顺序可能和这里的不同，这时候该根据那个作为标准呢
//TODO 合并后对某些Shader可能会有问题，因为数据可能不搭配。
//合并有许多问题，暂时不使用
//合并应该用在那些不需要改变的物品上,提供速度
class SubMesh implements ISubMesh
{
	public var merge(get, set):Bool;
	
	private var collisionTree:CollisionData;

	public var mesh:Mesh;

	/**
	 * The bounding volume that contains the mesh entirely.
	 * By default a BoundingBox (AABB).
	 */
	private var mBound:BoundingVolume;

	private var mBufferMap:StringMap<VertexBuffer>;

	private var mIndices:Vector<UInt>;
	private var _indexBuffer3D:IndexBuffer3D;

	private var _merge:Bool;

	//合并时使用
	private var _vertexData:Vector<Float>;
	private var _vertexBuffer3D:VertexBuffer3D;

	//不合并时使用
	private var _vertexBuffer3DMap:StringMap<VertexBuffer3D>;

	public function new()
	{
		mBound = new BoundingBox();

		mBufferMap = new StringMap<VertexBuffer>();

		merge = false;
	}

	public function validate():Void
	{
		updateBound();
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

	public function collideWith(other:Collidable, worldMatrix:Matrix4f, 
								worldBound:BoundingVolume, results:CollisionResults):Int
	{
		if (collisionTree == null)
		{
			createCollisionData();
		}

		return collisionTree.collideWith(other, worldMatrix, worldBound, results);
	}

	/**
	 * 数据是否合并为一个VertexBuffer3D提交给GPU
	 */
	
	private function get_merge():Bool
	{
		return _merge;
	}

	private function set_merge(value:Bool):Bool
	{
		_merge = value;
		if (!_merge)
		{
			_vertexBuffer3DMap = new StringMap<VertexBuffer3D>();

			if (_vertexBuffer3D != null)
			{
				_vertexBuffer3D.dispose();
				_vertexBuffer3D = null;
			}
		}
		return _merge;
	}

	public function getIndexBuffer3D(context:Context3D):IndexBuffer3D
	{
		if (_indexBuffer3D == null)
		{
			_indexBuffer3D = context.createIndexBuffer(mIndices.length);
			_indexBuffer3D.uploadFromVector(mIndices, 0, mIndices.length);
		}
		return _indexBuffer3D;
	}

	/**
	 * 不同Shader可能会生成不同的VertexBuffer3D
	 *
	 */
	public function getVertexBuffer3D(context:Context3D, type:String):VertexBuffer3D
	{
		var vertCount:Int;
		//合并到一个VertexBuffer3D中
		//FIXME 需要判断有数据变化时进行重新合并
		if (_merge)
		{
			if (_vertexBuffer3D == null)
			{
				vertCount = getVertexCount();
				_vertexData = getCombineData();
				_vertexBuffer3D = context.createVertexBuffer(vertCount, _getData32PerVertex());
				_vertexBuffer3D.uploadFromVector(_vertexData, 0, vertCount);
			}
			return _vertexBuffer3D;
		}

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

	private function getCombineData():Vector<Float>
	{
		var vertCount:Int = getVertexCount();

		var TYPES:Array<String> = BufferType.VERTEX_TYPES;
		var TYPES_SIZE:Int = TYPES.length;

		var result:Array<Float> = new Array<Float>();

		var buffer:VertexBuffer;
		var comps:Int;
		var data:Vector<Float>;
		for (i in 0...vertCount)
		{
			for (j in 0...TYPES_SIZE)
			{
				buffer = mBufferMap.get(TYPES[j]);
				if (buffer != null)
				{
					data = buffer.getData();
					comps = buffer.components;
					for (k in 0...comps)
					{
						result.push(data[i * comps + k]);
					}
				}
			}
		}

		return Vector.ofArray(result);
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

	/**
	 * Updates the bounding volume of this mesh.
	 * The method does nothing if the mesh has no Position buffer.
	 * It is expected that the position buffer is a float buffer with 3 components.
	 */
	public function updateBound():Void
	{
		var vb:VertexBuffer = getVertexBuffer(BufferType.POSITION);
		if (mBound != null && vb != null)
		{
			mBound.computeFromPoints(vb.getData());
		}
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

		if (merge)
		{
			if (_vertexBuffer3D != null)
			{
				_vertexBuffer3D.dispose();
				_vertexBuffer3D = null;
			}
		}
	}

	public function setIndices(indices:Vector<UInt>):Void
	{
		mIndices = indices;

		if (_indexBuffer3D != null)
		{
			_indexBuffer3D.dispose();
			_indexBuffer3D = null;
		}
	}

	public function getIndices():Vector<UInt>
	{
		return mIndices;
	}

	public function getTriangle(index:Int, tri:Triangle):Void
	{
		var pb:VertexBuffer = getVertexBuffer(BufferType.POSITION);
		if (pb != null && mIndices != null)
		{
			var vertices:Vector<Float> = pb.getData();
			var vertIndex:Int = index * 3;
			for (i in 0...3)
			{
				BufferUtils.populateFromBuffer(tri.getPoint(i), vertices, mIndices[vertIndex + i]);
			}
		}
	}
}

