package org.angle3d.scene.mesh;

import de.polygonal.ds.error.Assert;
import flash.display3D.Context3D;
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


using org.angle3d.math.VectorUtil;

/**
 * Mesh is used to store rendering data.
 * <p>
 * All visible elements in a scene are represented by meshes.
 * 
 */
class Mesh
{
	public var id:String;
	
	public var type:MeshType;
	
	private var collisionTree:CollisionData;
	
	/**
	 * The bounding volume that contains the mesh entirely.
	 * By default a BoundingBox (AABB).
	 */
	private var mBound:BoundingVolume;

	private var mBoundDirty:Bool;

	private var mBufferMap:Array<VertexBuffer>;

	private var mIndices:Vector<UInt>;
	
	private var mVertCount:Int = 0;
	private var mElementCount:Int = 0;
	
	//Lods
	private var lodLevels:Vector<Vector<UInt>>;
	private var numLodLevel:Int = 0;
	
	//GPU info
	private var _indexBuffer3D:IndexBuffer3D;
	private var _vertexBuffer3DMap:Array<VertexBuffer3D>;
	private var _lodIndexBuffer3Ds:Array<IndexBuffer3D>;
	
	public function new()
	{
		type = MeshType.STATIC;

		mBound = new BoundingBox();
		
		mBufferMap = new Array<VertexBuffer>();
		_vertexBuffer3DMap = new Array<VertexBuffer3D>();
	}
	
	/**
     * Determines if the mesh uses bone animation.
     * 
     * A mesh uses bone animation if it has bone index / weight buffers
     * such as {Type#BoneIndex} or {Type#HWBoneIndex}.
     * 
     * @return true if the mesh uses bone animation, false otherwise
     */
    public inline function isAnimated():Bool
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
	
	public inline function setLodLevels(lodLevels:Vector<Vector<UInt>>):Void
	{
		this.lodLevels = lodLevels;
		this.numLodLevel = lodLevels != null ? lodLevels.length : 0;
	}
	
	public inline function getNumLodLevels():Int
	{
		return numLodLevel;
	}
	
	public inline function getLodLevel(lod:Int):Vector<UInt>
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
	
	public function updateCounts():Void
	{
		var pb:VertexBuffer = getVertexBuffer(BufferType.POSITION);
		if (pb != null)
			mVertCount = Std.int(pb.getData().length / pb.components);
		
		mElementCount = Std.int(mIndices.length / 3);
	}
	
	/**
     * Indicates to the GPU that this mesh will not be modified (a hint). 
     * Sets the usage mode to {Usage#Static}
     * for all {VertexBuffer vertex buffers} on this Mesh.
     */
    public function setStatic():Void
	{
		for (vb in mBufferMap)
		{
			if(vb != null)
				vb.setUsage(Usage.STATIC);
		}
    }

    /**
     * Indicates to the GPU that this mesh will be modified occasionally (a hint).
     * Sets the usage mode to {Usage#Dynamic}
     * for all {VertexBuffer vertex buffers} on this Mesh.
     */
    public function setDynamic():Void
	{
        for (vb in mBufferMap)
		{
			if(vb != null)
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
		var vb:VertexBuffer = getVertexBuffer(BufferType.POSITION);
		if (mBound != null && vb != null)
		{
			mBound.computeFromPoints(vb.getData());
		}
	}

	/**
	 * Sets the {BoundingVolume} for this Mesh.
	 * The bounding volume is recomputed by calling {#updateBound() }.
	 *
	 * @param modelBound The model bound to set
	 */
	public function setBound(bound:BoundingVolume):Void
	{
		mBound = bound;
		mBoundDirty = false;
	}

	/**
	 * Returns the {BoundingVolume} of this Mesh.
	 * By default the bounding volume is a {BoundingBox}.
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
	
	private inline function createVertexBuffer3D(context:Context3D,vertCount:Int, data32PerVertex:Int, usage:Int):VertexBuffer3D
	{
		#if flash12
			var bufferUsage:String;
			if (usage == Usage.STATIC)
			{
				bufferUsage = "staticDraw";
			}
			else
			{
				bufferUsage = "dynamicDraw";
			}
			return context.createVertexBuffer(vertCount, data32PerVertex, cast bufferUsage);
		#else
			return context.createVertexBuffer(vertCount, data32PerVertex);
		#end
	}

	/**
	 * 不同Shader可能会生成不同的VertexBuffer3D
	 *
	 */
	public function getVertexBuffer3D(context:Context3D, type:Int):VertexBuffer3D
	{
		var buffer3D:VertexBuffer3D;
		var buffer:VertexBuffer = getVertexBuffer(type);
		//buffer更改过数据，需要重新上传数据
		if (buffer.dirty)
		{
			var vertCount:Int = getVertexCount();

			buffer3D = _vertexBuffer3DMap[type];
			if (buffer3D == null)
			{
				buffer3D = createVertexBuffer3D(context, vertCount, buffer.components, buffer.getUsage());
				_vertexBuffer3DMap[type] = buffer3D;
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
			buffer3D = _vertexBuffer3DMap[type];
			if (buffer3D == null)
			{
				var vertCount:Int = getVertexCount();
				buffer3D = createVertexBuffer3D(context, vertCount, buffer.components, buffer.getUsage());
				_vertexBuffer3DMap[type] = buffer3D;

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
	
	public inline function getVertexBuffer(type:Int):VertexBuffer
	{
		return mBufferMap[type];
	}
	
	public function createVertexBuffer(type:Int,numComponents:Int):Void
	{
		var vb:VertexBuffer = mBufferMap[type];
		if (vb == null)
		{
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
    public function clearBuffer(type:Int):Void
	{
        var vb:VertexBuffer = mBufferMap[type];
        if (vb != null)
		{
			mBufferMap[type] = null;
            updateCounts();
        }
    }

	public function setVertexBuffer(type:Int, components:Int, data:Vector<Float>):Void
	{
		#if debug
		Assert.assert(data != null, "data can not be null");
		#end

		var vb:VertexBuffer = mBufferMap[type];
		if (vb == null)
		{
			vb = new VertexBuffer(type,components);
			mBufferMap[type] = vb;
		}

		vb.updateData(data);
	}
	
	public function setVertexBufferDirect(buffer:VertexBuffer):Void
	{
		mBufferMap[buffer.type] = buffer;
	}
	
	public function scaleTextureCoordinates(scaleFactor:Vector2f):Void
	{
		var vb:VertexBuffer = mBufferMap[BufferType.TEXCOORD];
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
	
	public function getBufferList():Array<VertexBuffer>
	{
		return mBufferMap;
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
			for (buffer in _vertexBuffer3DMap)
			{
				if (buffer != null)
				{
					buffer.dispose();
				}
			}
			_vertexBuffer3DMap = null;
		}
	}
}

