package org.angle3d.io.parser.ang;

import flash.utils.ByteArray;
import flash.utils.CompressionAlgorithm;
import flash.utils.Endian;
import org.angle3d.error.Assert;
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
	
	public function readMeshes(byte:ByteArray):Array<Mesh>
	{
		byte.endian = Endian.LITTLE_ENDIAN;
		byte.uncompress(CompressionAlgorithm.LZMA);
		byte.position = 0;
		
		var header:String = byte.readUTFBytes(3);
		var version:Int = byte.readByte();
		
		Assert.assert(header == "ANG", "this is not ang format");
		
		var meshCount:Int = byte.readInt();
		
		var result:Array<Mesh> = new Array<Mesh>();
		for (i in 0...meshCount)
		{
			result.push(readMesh(byte));
		}
			
		return result;
	}
	
	private function readMesh(byte:ByteArray):Mesh
	{
		var mesh:Mesh = new Mesh();
		
		var nameLen:Int = byte.readUnsignedInt();
		if (nameLen > 0)
		{
			mesh.id = byte.readUTFBytes(nameLen);
		}
		
		//flags
		var flags:AngFlag = new AngFlag(byte.readUnsignedInt());
		
		var lod:Int = byte.readByte();
		if (lod > 0)
		{
			var lodLevels:Array<Array<UInt>> = new Array<Array<UInt>>();
			for (i in 0...lod)
			{
				var levels:Array<UInt> = new Array<UInt>();
				readInts(byte, levels);
				
				lodLevels[i] = levels;
			}
			
			mesh.setLodLevels(lodLevels);
		}
		else
		{
			var indices:Array<UInt> = new Array<UInt>();
			readInts(byte, indices);
			mesh.setIndices(indices);
		}
		
		var vertices:Array<Float> = new Array<Float>();
		readFloats(byte, vertices);
		mesh.setVertexBuffer(BufferType.POSITION, 3, vertices);
		
		if (flags.contains(AngFlag.UV))
		{
			var uvs:Array<Float> = new Array<Float>();
			readFloats(byte, uvs);
			mesh.setVertexBuffer(BufferType.TEXCOORD, 2, uvs);
		}
		
		if (flags.contains(AngFlag.COLOR))
		{
			var colors:Array<Float> = new Array<Float>();
			readFloats(byte, colors);
			mesh.setVertexBuffer(BufferType.COLOR, 3, colors);
		}
		
		if (flags.contains(AngFlag.NORMAL))
		{
			var normals:Array<Float> = new Array<Float>();
			readFloats(byte, normals);
			mesh.setVertexBuffer(BufferType.NORMAL, 3, normals);
		}
		
		if (flags.contains(AngFlag.TANGENT))
		{
			var tangents:Array<Float> = new Array<Float>();
			readFloats(byte, tangents);
			mesh.setVertexBuffer(BufferType.TANGENT, 4, tangents);
		}
		
		if (flags.contains(AngFlag.BINORMAL))
		{
			var binormals:Array<Float> = new Array<Float>();
			readFloats(byte, binormals);
			mesh.setVertexBuffer(BufferType.BINORMAL, 3, binormals);
		}
		
		if (flags.contains(AngFlag.EXTRA))
		{
			flags = flags.add(AngFlag.EXTRA);
			
			var len:Int = byte.readUnsignedInt();
			mesh.extra = byte.readUTFBytes(len);
		}
		
		mesh.validate();
		
		return mesh;
	}
	
	private inline function readFloats(byte:ByteArray,datas:Array<Float>):Void
	{
		var count:Int = byte.readUnsignedInt();
		for (i in 0...count)
		{
			datas[i] = byte.readFloat();
		}
	}
	
	private inline function readInts(byte:ByteArray,datas:Array<UInt>):Void
	{
		var count:Int = byte.readUnsignedInt();
		for (i in 0...count)
		{
			datas[i] = byte.readInt();
		}
	}
	
}