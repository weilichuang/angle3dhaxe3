package org.angle3d.io.parser.ang;
import flash.Vector;
import flash.utils.ByteArray;
import flash.utils.CompressionAlgorithm;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;

/**
 * ...
 * @author 
 */
class AngReader
{

	public function new() 
	{
		
	}
	
	public function readMeshes(byte:ByteArray):Vector<Mesh>
	{
		byte.uncompress(CompressionAlgorithm.LZMA);
		byte.position = 0;
		
		var header:String = byte.readUTFBytes(3);
		var version:Int = byte.readByte();
		
		var meshCount:Int = byte.readInt();
		
		var result:Vector<Mesh> = new Vector<Mesh>();
		for (i in 0...meshCount)
		{
			result.push(readMesh(byte));
		}
			
		return result;
	}
	
	public function readMesh(byte:ByteArray):Mesh
	{
		var mesh:Mesh = new Mesh();
		
		//flags
		var flags:AngFlag = new AngFlag(byte.readUnsignedInt());
		
		var lod:Int = byte.readByte();
		if (lod > 0)
		{
			var lodLevels:Vector<Vector<UInt>> = new Vector<Vector<UInt>>();
			for (i in 0...lod)
			{
				var levels:Vector<UInt> = new Vector<UInt>();
				readInts(byte, levels);
				
				lodLevels[i] = levels;
			}
			
			mesh.setLodLevels(lodLevels);
		}
		else
		{
			var indices:Vector<UInt> = new Vector<UInt>();
			readInts(byte, indices);
			mesh.setIndices(indices);
		}
		
		var vertices:Vector<Float> = new Vector<Float>();
		readFloats(byte, vertices);
		mesh.setVertexBuffer(BufferType.POSITION, 3, vertices);
		
		if (flags.contains(AngFlag.UV))
		{
			var uvs:Vector<Float> = new Vector<Float>();
			readFloats(byte, uvs);
			mesh.setVertexBuffer(BufferType.TEXCOORD, 2, uvs);
		}
		
		if (flags.contains(AngFlag.COLOR))
		{
			var colors:Vector<Float> = new Vector<Float>();
			readFloats(byte, colors);
			mesh.setVertexBuffer(BufferType.COLOR, 3, colors);
		}
		
		if (flags.contains(AngFlag.NORMAL))
		{
			var normals:Vector<Float> = new Vector<Float>();
			readFloats(byte, normals);
			mesh.setVertexBuffer(BufferType.NORMAL, 3, normals);
		}
		
		if (flags.contains(AngFlag.TANGENT))
		{
			var tangents:Vector<Float> = new Vector<Float>();
			readFloats(byte, tangents);
			mesh.setVertexBuffer(BufferType.TANGENT, 3, tangents);
		}
		
		return mesh;
	}
	
	private function readFloats(byte:ByteArray,datas:Vector<Float>):Void
	{
		var count:Int = byte.readUnsignedInt();
		for (i in 0...count)
		{
			datas[i] = byte.readFloat();
		}
	}
	
	private function readInts(byte:ByteArray,datas:Vector<UInt>):Void
	{
		var count:Int = byte.readUnsignedInt();
		for (i in 0...count)
		{
			datas[i] = byte.readInt();
		}
	}
	
}