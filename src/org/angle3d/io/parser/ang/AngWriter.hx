package org.angle3d.io.parser.ang;
import flash.Vector;
import flash.utils.ByteArray;
import flash.utils.CompressionAlgorithm;
import flash.utils.Endian;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;

/**
 * ...
 * @author 
 */
class AngWriter
{

	public function new() 
	{
		
	}
	
	public function writeMeshes(meshes:Vector<Mesh>):ByteArray
	{
		var byte:ByteArray = new ByteArray();
		byte.endian = Endian.LITTLE_ENDIAN;
		
		byte.writeUTFBytes("ANG");
		byte.writeByte(1);//version
		
		var count:Int = meshes.length;
		byte.writeInt(count);
		
		for (i in 0...count)
		{
			writeMesh(byte, meshes[i]);
		}
		
		byte.compress(CompressionAlgorithm.LZMA);
				
		return byte;
	}
	
	private function writeMesh(byte:ByteArray,mesh:Mesh):Void
	{
		if (mesh.id != null && mesh.id != "")
		{
			var nameLen:Int = mesh.id.length;
			byte.writeUnsignedInt(nameLen);
			byte.writeUTFBytes(mesh.id);
		}
		else
		{
			byte.writeUnsignedInt(0);
		}
		
		var pos:Int = byte.position;
		var flags:AngFlag = new AngFlag(0);
		byte.writeUnsignedInt(flags.toInt());//tmp flags
		
		var lod:Int = mesh.getNumLodLevels();
		byte.writeByte(lod);
		if (lod > 0)
		{
			for (i in 0...lod)
			{
				var levels:Vector<UInt> = mesh.getLodLevel(i);
				writeInts(byte, levels);
			}
		}
		else
		{
			writeInts(byte, mesh.getIndices());
		}
		
		var vertices:Vector<Float> = mesh.getVertexBuffer(BufferType.POSITION).getData();
		writeFloats(byte, vertices);
		
		if (mesh.getVertexBuffer(BufferType.TEXCOORD) != null)
		{
			flags = flags.add(AngFlag.UV);
			writeFloats(byte, mesh.getVertexBuffer(BufferType.TEXCOORD).getData());
		}
		
		if (mesh.getVertexBuffer(BufferType.COLOR) != null)
		{
			flags = flags.add(AngFlag.COLOR);
			writeFloats(byte, mesh.getVertexBuffer(BufferType.COLOR).getData());
		}
		
		if (mesh.getVertexBuffer(BufferType.NORMAL) != null)
		{
			flags = flags.add(AngFlag.NORMAL);
			writeFloats(byte, mesh.getVertexBuffer(BufferType.NORMAL).getData());
		}
		
		if (mesh.getVertexBuffer(BufferType.TANGENT) != null)
		{
			flags = flags.add(AngFlag.TANGENT);
			writeFloats(byte, mesh.getVertexBuffer(BufferType.TANGENT).getData());
		}
		
		if (mesh.getVertexBuffer(BufferType.BINORMAL) != null)
		{
			flags = flags.add(AngFlag.BINORMAL);
			writeFloats(byte, mesh.getVertexBuffer(BufferType.BINORMAL).getData());
		}
		
		if (mesh.extra != null)
		{
			flags = flags.add(AngFlag.EXTRA);
			
			var len:Int = mesh.extra.length;
			byte.writeUnsignedInt(len);
			byte.writeUTFBytes(mesh.extra);
		}
		
		byte.position = pos;
		byte.writeUnsignedInt(flags.toInt());//real flags
		
		byte.position = byte.length;
	}
	
	private inline function writeFloats(byte:ByteArray,datas:Vector<Float>):Void
	{
		var count:Int = datas.length;
		byte.writeUnsignedInt(count);
		for (i in 0...count)
		{
			byte.writeFloat(datas[i]);
		}
	}
	
	private inline function writeInts(byte:ByteArray,datas:Vector<UInt>):Void
	{
		var count:Int = datas.length;
		byte.writeUnsignedInt(count);
		for (i in 0...count)
		{
			byte.writeInt(datas[i]);
		}
	}
	
}