package org.angle3d.scene.mesh;

import de.polygonal.ds.error.Assert;
import flash.display3D.Context3D;
import flash.display3D.Context3DBufferUsage;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.Vector;
import org.angle3d.bounding.BoundingBox;
import org.angle3d.bounding.BoundingVolume;
import org.angle3d.collision.bih.BIHTree;
import org.angle3d.collision.Collidable;
import org.angle3d.collision.CollisionData;
import org.angle3d.collision.CollisionResults;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Triangle;
import org.angle3d.math.Vector2f;
import org.angle3d.utils.FastStringMap;


using org.angle3d.math.VectorUtil;

/**
 * <code>Mesh</code> is used to store rendering data.
 * <p>
 * All visible elements in a scene are represented by meshes.
 * 
 */
//TODO VertexBuffer3D,IndexBuffer3D等GPU数据最好和Mesh分离，放到具体的渲染类中，以便后期用opengl es2或者webgl渲染
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

	private var mBufferMap:FastStringMap<VertexBuffer>;
	private var mBufferList:Vector<VertexBuffer>;

	private var mIndices:Vector<UInt>;
	
	private var mVertCount:Int = 0;
	private var mElementCount:Int = 0;
	
	//Lods
	private var lodLevels:Vector<Vector<UInt>>;
	
	//GPU info
	private var _indexBuffer3D:IndexBuffer3D;
	private var _vertexBuffer3DMap:FastStringMap<VertexBuffer3D>;
	private var _lodIndexBuffer3Ds:Array<IndexBuffer3D>;
	
	public function new()
	{
		type = MeshType.STATIC;

		mBound = new BoundingBox();
		
		mBufferMap = new FastStringMap<VertexBuffer>();
		mBufferList = new Vector<VertexBuffer>();
	}
	
	/**
     * Determines if the mesh uses bone animation.
     * 
     * A mesh uses bone animation if it has bone index / weight buffers
     * such as {@link Type#BoneIndex} or {@link Type#HWBoneIndex}.
     * 
     * @return true if the mesh uses bone animation, false otherwise
     */
    public function isAnimated():Bool
	{
        return getVertexBuffer(BufferType.BONE_INDICES) != null;
    }
	
	/**
     * Prepares the mesh for software skinning by converting the bone index
     * and weight buffers to heap buffers. 
     * 
     * @param forSoftwareAnim Should be true to enable the conversion.
     */
	public function prepareForAnim(forSoftwareAnim:Bool):Void
	{
		
	}
	
	public function generateBindPose(forSoftwareAnim:Bool):Void
	{
		
	}
	
	public function setLodLevels(lodLevels:Vector<Vector<UInt>>):Void
	{
		this.lodLevels = lodLevels;
	}
	
	public function getNumLodLevels():Int
	{
		return lodLevels != null ? lodLevels.length : 0;
	}
	
	public function getLodLevel(lod:Int):Vector<UInt>
	{
		return lodLevels[lod];
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
	
	//TODO 实现此函数
	public function updateCounts():Void
	{
		var pb:VertexBuffer = getVertexBuffer(BufferType.POSITION);
		if (pb != null)
			mVertCount = Std.int(pb.getData().length / pb.components);
		
		mElementCount = Std.int(mIndices.length / 3);
	}
	
	/**
     * Indicates to the GPU that this mesh will not be modified (a hint). 
     * Sets the usage mode to {@link Usage#Static}
     * for all {@link VertexBuffer vertex buffers} on this Mesh.
     */
    public function setStatic():Void
	{
		for (vb in mBufferList)
		{
			vb.setUsage(Usage.STATIC);
		}
    }

    /**
     * Indicates to the GPU that this mesh will be modified occasionally (a hint).
     * Sets the usage mode to {@link Usage#Dynamic}
     * for all {@link VertexBuffer vertex buffers} on this Mesh.
     */
    public function setDynamic():Void
	{
        for (vb in mBufferList)
		{
			vb.setUsage(Usage.DYNAMIC);
		}
    }

	public function validate():Void
	{
		updateBound();
		updateCounts();
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
	public function createCollisionData():Void
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
		if (_indexBuffer3D == null)
		{
			_indexBuffer3D = context.createIndexBuffer(mIndices.length);
			_indexBuffer3D.uploadFromVector(mIndices, 0, mIndices.length);
		}
		return _indexBuffer3D;
	}
	
	
	public function getLodIndexBuffer3D(context:Context3D, lod:Int):IndexBuffer3D
	{
		if (_lodIndexBuffer3Ds == null)
		{
			_lodIndexBuffer3Ds = [];
		}
		
		if (_lodIndexBuffer3Ds[lod] == null)
		{
			var indices:Vector<UInt> = getLodLevel(lod);
			_lodIndexBuffer3Ds[lod] = context.createIndexBuffer(indices.length);
			_lodIndexBuffer3Ds[lod].uploadFromVector(indices, 0, indices.length);
		}
		return _lodIndexBuffer3Ds[lod];
	}

	/**
	 * 不同Shader可能会生成不同的VertexBuffer3D
	 *
	 */
	public function getVertexBuffer3D(context:Context3D, type:String):VertexBuffer3D
	{
		var vertCount:Int;
		
		if (_vertexBuffer3DMap == null)
			_vertexBuffer3DMap = new FastStringMap<VertexBuffer3D>();

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
				var bufferUsage:Context3DBufferUsage;
				if (buffer.getUsage() == Usage.STATIC)
				{
					bufferUsage = Context3DBufferUsage.STATIC_DRAW;
				}
				else
				{
					bufferUsage = Context3DBufferUsage.DYNAMIC_DRAW;
				}
				buffer3D = context.createVertexBuffer(vertCount, buffer.components, bufferUsage);
				_vertexBuffer3DMap.set(type,buffer3D);
			}

			if (buffer.byteArrayData != null)
			{
				buffer3D.uploadFromByteArray(buffer.byteArrayData, 0, 0, vertCount);
			}
			else
			{
				buffer3D.uploadFromVector(buffer.getData(), 0, vertCount);
			}
			
			buffer.dirty = false;
		}
		else
		{
			buffer3D = _vertexBuffer3DMap.get(type);
			if (buffer3D == null)
			{
				vertCount = getVertexCount();
				
				var bufferUsage:Context3DBufferUsage;
				if (buffer.getUsage() == Usage.STATIC)
				{
					bufferUsage = Context3DBufferUsage.STATIC_DRAW;
				}
				else
				{
					bufferUsage = Context3DBufferUsage.DYNAMIC_DRAW;
				}
				buffer3D = context.createVertexBuffer(vertCount, buffer.components, bufferUsage);
				_vertexBuffer3DMap.set(type,buffer3D);

				if (buffer.byteArrayData != null)
				{
					buffer3D.uploadFromByteArray(buffer.byteArrayData, 0, 0, vertCount);
				}
				else
				{
					buffer3D.uploadFromVector(buffer.getData(), 0, vertCount);
				}
			}
		}

		return buffer3D;
	}

	public function getVertexCount():Int
	{
		return mVertCount;
	}
	
	public function getTriangleCount(lod:Int = 0):Int
	{
		if (lodLevels != null)
		{
            if (lod < 0)
                throw "LOD level cannot be < 0";

            if (lod >= lodLevels.length)
                throw "LOD level " + lod + " does not exist!";

            return Std.int(lodLevels[lod].length / 3);
        }
		else if (lod == 0)
		{
            return mElementCount;
        }
		else
		{
            throw "There are no LOD levels on the mesh!";
        }
		return 0;
	}
	
	public inline function getVertexBuffer(type:String):VertexBuffer
	{
		return mBufferMap.get(type);
	}
	
	public function createVertexBuffer(type:String,numComponents:Int):Void
	{
		var vb:VertexBuffer = mBufferMap.get(type);
		if (vb == null)
		{
			vb = new VertexBuffer(type,numComponents);
			mBufferMap.set(type, vb);
			mBufferList.push(vb);
		}
	}
	
	/**
     * Unsets the {@link VertexBuffer} set on this mesh
     * with the given type. Does nothing if the vertex buffer type is not set 
     * initially.
     * 
     * @param type The buffer type to remove
     */
    public function clearBuffer(type:String):Void
	{
        var vb:VertexBuffer = mBufferMap.get(type);
        if (vb != null)
		{
			mBufferMap.remove(type);
            mBufferList.remove(vb);
            updateCounts();
        }
    }

	public function setVertexBuffer(type:String, components:Int, data:Vector<Float>):Void
	{
		#if debug
		Assert.assert(data != null, "data can not be null");
		#end

		var vb:VertexBuffer = mBufferMap.get(type);
		if (vb == null)
		{
			vb = new VertexBuffer(type,components);
			mBufferMap.set(type, vb);
			mBufferList.push(vb);
		}

		vb.updateData(data);
	}
	
	public function setVertexBufferDirect(buffer:VertexBuffer):Void
	{
		var vb:VertexBuffer = mBufferMap.get(buffer.type);
		if (vb == null)
		{
			mBufferList.push(buffer);
		}
		else
		{
			mBufferList.remove(vb);
			mBufferList.push(buffer);
		}
		mBufferMap.set(buffer.type, buffer);
	}
	
	public function scaleTextureCoordinates(scaleFactor:Vector2f):Void
	{
		var vb:VertexBuffer = mBufferMap.get(BufferType.TEXCOORD);
		if (vb == null)
			return;
			
		var sx:Float = scaleFactor.x;
		var sy:Float = scaleFactor.y;
			
		var data:Vector<Float> = vb.getData();
		var i:Int = 0;
		while (i < data.length)
		{
			data[i + 0] *= sx;
			data[i + 1] *= sy;
			i += 2;
		}
		vb.updateData(data);
	}
	
	public function getBufferList():Vector<VertexBuffer>
	{
		return mBufferList;
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
	
	public function dispose():Void
	{
		cleanGPUInfo();
	}
	
	/**
	 * 清理GPU相关信息，GPU丢失后旧的数据不能使用了
	 */
	public function cleanGPUInfo():Void
	{
		if (_indexBuffer3D != null)
		{
			_indexBuffer3D.dispose();
			_indexBuffer3D = null;
		}
		
		if (_lodIndexBuffer3Ds != null)
		{
			for (i in 0..._lodIndexBuffer3Ds.length)
			{
				if (_lodIndexBuffer3Ds[i] != null)
				{
					_lodIndexBuffer3Ds[i].dispose();
				}
			}
			_lodIndexBuffer3Ds = null;
		}
		
		if (_vertexBuffer3DMap != null)
		{
			var keys:Array<String> = _vertexBuffer3DMap.keys();
			for (key in keys)
			{
				var buffer:VertexBuffer3D = _vertexBuffer3DMap.get(key);
				if (buffer != null)
				{
					buffer.dispose();
				}
			}
			_vertexBuffer3DMap.clear();
			_vertexBuffer3DMap = null;
		}
	}
}

