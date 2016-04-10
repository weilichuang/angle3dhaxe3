package com.bulletphysics.collision.shapes;
import flash.Vector;

/**
 * IndexedMesh indexes into existing vertex and index arrays, in a similar way to
 * OpenGL's glDrawElements. Instead of the number of indices, we pass the number
 * of triangles.
 * 
 
 */
class IndexedMesh
{
	public var numTriangles:Int;
    public var triangleIndexBase:Vector<Int>;//ByteBuffer
    public var triangleIndexStride:Int;
    public var numVertices:Int;
    public var vertexBase:Vector<Float>;//ByteBuffer
    public var vertexStride:Int;
    // The index type is set when adding an indexed mesh to the
    // TriangleIndexVertexArray, do not set it manually
    public var indexType:ScalarType;

	public function new() 
	{
		
	}
	
}