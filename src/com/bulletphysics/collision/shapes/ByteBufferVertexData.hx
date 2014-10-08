package com.bulletphysics.collision.shapes;

/**
 * 实现不对，需要修改
 * @author weilichuang
 */
class ByteBufferVertexData extends VertexData
{
	public var vertexData:Array<Float>;
	public var vertexCount:Int;
	public var vertexStride:Int;
	public var vertexType:ScalarType;
	
	public var indexData:Array<Int>;
	public var indexCount:Int;
	public var indexStride:Int;
	public var indexType:ScalarType;

	public function new() 
	{
		super();
	}
	
	override public function getVertexCount():Int 
	{
		return this.vertexCount;
	}
	
	override public function getIndexCount():Int 
	{
		return this.indexCount;
	}
	
	override public function getVertex(idx:Int, out:{x:Float, y:Float, z:Float}):{x:Float, y:Float, z:Float} 
	{
		var off:Int = idx * vertexStride;
        out.x = vertexData[off + 4 * 0];
        out.y = vertexData[off + 4 * 1];
        out.z = vertexData[off + 4 * 2];
        return out;
	}
	
	override public function setVertex(idx:Int, x:Float, y:Float, z:Float):Void 
	{
		var off:Int = idx * vertexStride;
		vertexData[off + 4 * 0] = x;
        vertexData[off + 4 * 1] = y;
        vertexData[off + 4 * 2] = z;
	}
	
	override public function getIndex(idx:Int):Int 
	{
		if (indexType == ScalarType.SHORT) 
		{
            return indexData[idx * indexStride] & 0xFFFF;
        }
		else if (indexType == ScalarType.INTEGER)
		{
            return indexData[idx * indexStride];
        }
		else 
		{
            throw ("indicies type must be short or integer");
        }
	}
	
}