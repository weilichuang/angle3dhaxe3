package org.angle3d.io.parser.max3ds;

import flash.geom.Matrix3D;
import flash.utils.ByteArray;
import flash.Vector;
import org.angle3d.ds.FastStringMap;

class Max3DSMeshParser extends AbstractMax3DSParser
{
	private static var TRANSFORM:Matrix3D = new Matrix3D(Vector.ofArray([1., 0., 0., 0., 
																		0., 0., -1., 0., 
																		0., 1., 0., 0., 
																		0., 0., 0., 1.]));

	private var _vertices:Vector<Float>;
	private var _indices:Vector<UInt>;
	private var _uvData:Vector<Float>;
	private var _matrix:Matrix3D;

	private var _materials:FastStringMap<Dynamic>;

	private var _mappedFaces:Vector<Int>;

	private var _name:String;

	public function new(chunk:Max3DSChunk, name:String)
	{
		super(chunk);
		this.name = name;
	}
	
	override private function initialize():Void
	{
		super.initialize();
		
		_matrix = new Matrix3D();
		_materials = new FastStringMap<Dynamic>();
		_mappedFaces = new Vector<Int>();
		
		parseFunctions[Max3DSChunk.MESH] = enterChunk;
		parseFunctions[Max3DSChunk.MESH_VERTICES] = parseVertices;
		parseFunctions[Max3DSChunk.MESH_INDICES] = parseIndices;
		parseFunctions[Max3DSChunk.MESH_MAPPING] = parseUVData;
		parseFunctions[Max3DSChunk.MESH_MATERIAL] = parseMaterial;
		parseFunctions[Max3DSChunk.MESH_MATRIX] = parseMatrix;
	}

	public var name(get, set):String;
	private function get_name():String
	{
		return _name;
	}

	private function set_name(value:String):String
	{
		return _name = value;
	}

	public var vertices(get, null):Vector<Float>;
	private function get_vertices():Vector<Float>
	{
		return _vertices;
	}

	public var uvData(get, null):Vector<Float>;
	private function get_uvData():Vector<Float>
	{
		return _uvData;
	}

	public var indices(get, null):Vector<UInt>;
	private function get_indices():Vector<UInt>
	{
		return _indices;
	}

	public var materials(get, null):FastStringMap<Dynamic>;
	private function get_materials():FastStringMap<Dynamic>
	{
		return _materials;
	}

	override private function finalize():Void
	{
		super.finalize();

		var tmpVertices:Vector<Float> = new Vector<Float>();

		TRANSFORM.transformVectors(_vertices, tmpVertices);
		/*_vertices.length = 0;
		_matrix.transformVectors(tmpVertices, _vertices);*/
		_vertices = tmpVertices;
	}

	private function parseVertices(chunk:Max3DSChunk):Void
	{
		var data:ByteArray = chunk.data;

		var nbVertices:Int = data.readUnsignedShort() * 3;

		_vertices = new Vector<Float>(nbVertices,true);
		var i:Int = 0;
		while(i < nbVertices)
		{
			_vertices[i] = data.readFloat();
			_vertices[i + 1] = data.readFloat();
			_vertices[i + 2] = data.readFloat();
			i += 3;
		}
	}

	private function parseIndices(chunk:Max3DSChunk):Void
	{
		var data:ByteArray = chunk.data;
		var nbFaces:Int = data.readUnsignedShort() * 3;

		_indices = new Vector<UInt>(nbFaces, true);
		var i:Int = 0;
		while(i < nbFaces)
		{
			_indices[i] = data.readUnsignedShort();
			_indices[i + 1] = data.readUnsignedShort();
			_indices[i + 2] = data.readUnsignedShort();

			data.position += 2;
			i += 3;
		}
	}

	private function parseUVData(chunk:Max3DSChunk):Void
	{
		var data:ByteArray = chunk.data;

		var nbCoordinates:Int = data.readUnsignedShort() * 2;

		_uvData = new Vector<Float>(nbCoordinates, true);
		var i:Int = 0;
		while(i < nbCoordinates)
		{
			_uvData[i] = data.readFloat();
			_uvData[i + 1] = 1. - data.readFloat();
			i += 2;
		}
	}

	private function parseMaterial(chunk:Max3DSChunk):Void
	{
		var data:ByteArray = chunk.data;

		var name:String = chunk.readString();

		var nbFaces:Int = data.readUnsignedShort();
		var indices:Vector<UInt> = new Vector<UInt>();
		for (i in 0...nbFaces)
		{
			var faceId:Int = data.readUnsignedShort() * 3;
			indices.push(_indices[faceId]);
			indices.push(_indices[faceId + 1]);
			indices.push(_indices[faceId + 2]);
		}

		if (nbFaces > 0)
			_materials.set(name,indices);
	}

	private function parseMatrix(chunk:Max3DSChunk):Void
	{
		var data:ByteArray = chunk.data;
		var tmp:Vector<Float> = new Vector<Float>(16, true);

		for (j in 0...12)
			tmp[j] = data.readFloat();

		tmp[15] = 1.;
		_matrix.copyRawDataFrom(tmp);
		//_matrix.transpose();
	}
}
