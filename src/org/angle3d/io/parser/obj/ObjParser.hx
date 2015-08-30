package org.angle3d.io.parser.obj;
import flash.utils.ByteArray;
import flash.Vector;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;

/**
 * ...
 * @author 
 */
class ObjParser
{
	static var indexedVertices:Vector<Float>;
	static var indexedUVs:Vector<Float>;
	static var indexedNormals:Vector<Float>;
	static var index:Int;

	public var data:Vector<Float>;
	public var indices:Vector<UInt>;
	
	public function new() 
	{
		
	}
	
	public function parse(objData:String):Mesh
	{
		var mesh:Mesh = new Mesh();
		
		var vertices:Vector<Float> = new Vector<Float>();
		var uvs:Vector<Float> = new Vector<Float>();
		var normals:Vector<Float> = new Vector<Float>();

		var vertexIndices:Vector<UInt> =  new Vector<UInt>();
		var uvIndices:Vector<UInt> = new Vector<UInt>();
		var normalIndices:Vector<UInt> = new Vector<UInt>();

		var tempVertices:Array<Array<Float>> = [];
		var tempUVs:Array<Array<Float>> = [];
		var tempNormals:Array<Array<Float>> = [];

		var lines:Array<String> = objData.split("\n");

		for (i in 0...lines.length) 
		{
			var line:String = lines[i];
			
			var words:Array<String> = line.split(" ");

			if (words[0] == "v") 
			{
				var vector:Array<Float> = [];
				vector.push(Std.parseFloat(words[1]));
				vector.push(Std.parseFloat(words[2]));
				vector.push(Std.parseFloat(words[3]));
				tempVertices.push(vector);
			}
			else if (words[0] == "vt")
			{
				var vector:Array<Float> = [];
				vector.push(Std.parseFloat(words[1]));
				vector.push(Std.parseFloat(words[2]));
				tempUVs.push(vector);
			}
			else if (words[0] == "vn") 
			{
				var vector:Array<Float> = [];
				vector.push(Std.parseFloat(words[1]));
				vector.push(Std.parseFloat(words[2]));
				vector.push(Std.parseFloat(words[3]));
				tempNormals.push(vector);
			}
			else if (words[0] == "f")
			{
				var sec1:Array<String> = words[1].split("/");
				var sec2:Array<String> = words[2].split("/");
				var sec3:Array<String> = words[3].split("/");

				vertexIndices.push(Std.parseInt(sec1[0]));
				vertexIndices.push(Std.parseInt(sec2[0]));
				vertexIndices.push(Std.parseInt(sec3[0]));

				uvIndices.push(Std.parseInt(sec1[1]));
				uvIndices.push(Std.parseInt(sec2[1]));
				uvIndices.push(Std.parseInt(sec3[1]));
				
				normalIndices.push(Std.parseInt(sec1[2]));
				normalIndices.push(Std.parseInt(sec2[2]));
				normalIndices.push(Std.parseInt(sec3[2]));
			}
		}

		for (i in 0...vertexIndices.length)
		{
			var vertex:Array<Float> = tempVertices[vertexIndices[i] - 1];
			var uv:Array<Float> = tempUVs[uvIndices[i] - 1];
			var normal:Array<Float> = tempNormals[normalIndices[i] - 1];

			vertices.push(vertex[0]);
			vertices.push(vertex[1]);
			vertices.push(vertex[2]);
			uvs.push(uv[0]);
			uvs.push(uv[1]);
			normals.push(normal[0]);
			normals.push(normal[1]);
			normals.push(normal[2]);
		}

		build(vertices, uvs, normals);

		mesh.setVertexBuffer(BufferType.POSITION, 3, indexedVertices);
		mesh.setVertexBuffer(BufferType.TEXCOORD, 2, indexedUVs);
		mesh.setVertexBuffer(BufferType.NORMAL, 2, indexedNormals);
		mesh.setIndices(indices);
		mesh.validate();

		return mesh;
	}
	
	private function build(vertices:Vector<Float>, uvs:Vector<Float>, normals:Vector<Float>):Void 
	{
		indexedVertices = new Vector<Float>();
		indexedUVs = new Vector<Float>();
		indexedNormals =new Vector<Float>();
		indices = new Vector<UInt>();

		// For each input vertex
		var count:Int = Std.int(vertices.length / 3);
		for (i in 0...count)
		{
			var i3:Int = i * 3;
			var i2:Int = i * 2;
			// Try to find a similar vertex in out_XXXX
			var found:Bool = getSimilarVertexIndex(vertices[i3], vertices[i3 + 1], vertices[i3 + 2],
													uvs[i2], uvs[i2 + 1],
													normals[i3], normals[i3 + 1], normals[i3 + 2]);

			// A similar vertex is already in the VBO, use it instead !
			if (found) 
			{ 
				indices.push(index);
			}
			else // If not, it needs to be added in the output data.
			{
				indexedVertices.push(vertices[i3]);
				indexedVertices.push(vertices[i3 + 1]);
				indexedVertices.push(vertices[i3 + 2]);
				indexedUVs.push(uvs[i2 ]);
				indexedUVs.push(1 - uvs[i2 + 1]);
				indexedNormals.push(normals[i3]);
				indexedNormals.push(normals[i3 + 1]);
				indexedNormals.push(normals[i3 + 2]);
				indices.push(Std.int(indexedVertices.length / 3) - 1);
			}
		}
	}

	// Returns true if v1 can be considered equal to v2
	private inline function isNear(v1:Float, v2:Float):Bool 
	{
		return Math.abs(v1 - v2) < 0.01;
	}

	// Searches through all already-exported vertices for a similar one.
	// Similar = same position + same UVs + same normal
	private function getSimilarVertexIndex( vertexX:Float, vertexY:Float, vertexZ:Float,
											uvX:Float, uvY:Float,
											normalX:Float, normalY:Float, normalZ:Float):Bool
	{
		// Lame linear search
		var count:Int = Std.int(indexedVertices.length / 3);
		for (i in 0...count)
		{
			var i3:Int = i * 3;
			if (isNear(vertexX, indexedVertices[i3]) &&
				isNear(vertexY, indexedVertices[i3 + 1]) &&
				isNear(vertexZ, indexedVertices[i3 + 2]) &&
				isNear(uvX    , indexedUVs     [i * 2]) &&
				isNear(uvY    , indexedUVs     [i * 2 + 1]) &&
				isNear(normalX, indexedNormals [i3]) &&
				isNear(normalY, indexedNormals [i3 + 1]) &&
				isNear(normalZ, indexedNormals [i3 + 2])) 
			{
				index = i;
				return true;
			}
		}
		// No other vertex could be used instead.
		// Looks like we'll have to add it to the VBO.
		return false;
	}
	
}