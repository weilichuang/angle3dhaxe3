package com.bulletphysics.collision.shapes;
import com.bulletphysics.collision.shapes.VertexData;
import de.polygonal.ds.error.Assert;
import com.bulletphysics.util.ObjectArrayList;
import flash.Vector;

/**
 * TriangleIndexVertexArray allows to use multiple meshes, by indexing into existing
 * triangle/index arrays. Additional meshes can be added using {@link #addIndexedMesh addIndexedMesh}.<p>
 * <p/>
 * No duplicate is made of the vertex/index data, it only indexes into external vertex/index
 * arrays. So keep those arrays around during the lifetime of this TriangleIndexVertexArray.
 * 
 * @author weilichuang
 */
class TriangleIndexVertexArray extends StridingMeshInterface
{
	private var indexedMeshes:ObjectArrayList<IndexedMesh> = new ObjectArrayList<IndexedMesh>();
	
	private var data:ByteBufferVertexData = new ByteBufferVertexData();
	
	public function new(numTriangles:Int, triangleIndexBase:Vector<Int>, triangleIndexStride:Int,
						numVertices:Int,vertexBase:Vector<Float>,vertexStride:Int) 
	{
		super();
		
		var mesh:IndexedMesh = new IndexedMesh();

        mesh.numTriangles = numTriangles;
        mesh.triangleIndexBase = triangleIndexBase;
        mesh.triangleIndexStride = triangleIndexStride;
        mesh.numVertices = numVertices;
        mesh.vertexBase = vertexBase;
        mesh.vertexStride = vertexStride;

        addIndexedMesh(mesh);
	}
	
	public function addIndexedMesh(mesh:IndexedMesh, ?indexType:ScalarType = null):Void
	{
		if (indexType == null)
			indexType = ScalarType.INTEGER;
		mesh.indexType = indexType;
		indexedMeshes.add(mesh);
	}
	
	override public function getLockedVertexIndexBase(subpart:Int):VertexData 
	{
		Assert.assert (subpart < getNumSubParts());

        var mesh:IndexedMesh = indexedMeshes.getQuick(subpart);

        data.vertexCount = mesh.numVertices;
        data.vertexData = mesh.vertexBase;
        //#ifdef BT_USE_DOUBLE_PRECISION
        //type = PHY_DOUBLE;
        //#else
        data.vertexType = ScalarType.FLOAT;
        //#endif
        data.vertexStride = mesh.vertexStride;

        data.indexCount = mesh.numTriangles * 3;

        data.indexData = mesh.triangleIndexBase;
        data.indexStride = Std.int(mesh.triangleIndexStride / 3);
        data.indexType = mesh.indexType;
        return data;
	}
	
	override public function getLockedReadOnlyVertexIndexBase(subpart:Int):VertexData 
	{
		return this.getLockedVertexIndexBase(subpart);
	}
	
	override public function unLockVertexBase(subpart:Int):Void 
	{
		data.vertexData = null;
		data.indexData = null;
	}
	
	override public function unLockReadOnlyVertexBase(subpart:Int):Void 
	{
		this.unLockVertexBase(subpart);
	}
	
	override public function getNumSubParts():Int 
	{
		return this.indexedMeshes.size();
	}
	
	public function getIndexedMeshArray():ObjectArrayList<IndexedMesh>
	{
		return indexedMeshes;
	}
	
	override public function preallocateVertices(numverts:Int):Void 
	{
		
	}
	
	override public function preallocateIndices(numindices:Int):Void 
	{
		
	}
	
}