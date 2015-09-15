package org.angle3d.io.parser.obj;
import flash.utils.ByteArray;
import flash.Vector;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.utils.Logger;

typedef MeshInfo = {
	name:String,
	vertexIndices:Vector<UInt>,
	uvIndices:Vector<UInt>,
	normalIndices:Vector<UInt>
}

class ObjParser
{
	static var indexedVertices:Vector<Float>;
	static var indexedUVs:Vector<Float>;
	static var indexedNormals:Vector<Float>;
	static var index:Int;

	public var indices:Vector<UInt>;
	
	public function new() 
	{
		
	}
	
	public function parse(objData:String):Vector<Mesh>
	{
		var tempVertices:Vector<Float> = new Vector<Float>();
		var tempUVs:Vector<Float> = new Vector<Float>();
		var tempNormals:Vector<Float> = new Vector<Float>();
		
		var mtlNames:Vector<String> = new Vector<String>();
		
		var mtlFileName:String;
		
		var meshInfos:Vector<MeshInfo> = new Vector<MeshInfo>();
		
		var curMeshInfo:MeshInfo = null;
		
		objData = ~/\n{2,}/g.replace(objData, "\n");
		
		var lines:Array<String> = objData.split("\n");
		for (i in 0...lines.length) 
		{
			var line:String = lines[i];
			
			line = ~/\s{2,}/g.replace(line, " ");
			line = ~/\r/g.replace(line, "");
			
			var words:Array<String> = line.split(" ");
			
			if (words[0] == "v") 
			{
				tempVertices.push(Std.parseFloat(words[1]));
				tempVertices.push(Std.parseFloat(words[2]));
				tempVertices.push(Std.parseFloat(words[3]));
			}
			else if (words[0] == "vt")
			{
				tempUVs.push(Std.parseFloat(words[1]));
				tempUVs.push(Std.parseFloat(words[2]));
			}
			else if (words[0] == "vn") 
			{
				tempNormals.push(Std.parseFloat(words[1]));
				tempNormals.push(Std.parseFloat(words[2]));
				tempNormals.push(Std.parseFloat(words[3]));
			}
			else if (words[0] == "f")
			{
				//还没有MeshInfo，则创建一个
				if (curMeshInfo == null)
				{
					curMeshInfo = { name:"default",
								vertexIndices:new Vector<UInt>(),
								uvIndices:new Vector<UInt>(),
								normalIndices:new Vector<UInt>()
								};
					meshInfos.push(curMeshInfo);
				}
				
				var sec1:Array<String> = words[1].split("/");
				var sec2:Array<String> = words[2].split("/");
				var sec3:Array<String> = words[3].split("/");

				curMeshInfo.vertexIndices.push(Std.parseInt(sec1[0]));
				curMeshInfo.vertexIndices.push(Std.parseInt(sec2[0]));
				curMeshInfo.vertexIndices.push(Std.parseInt(sec3[0]));

				curMeshInfo.uvIndices.push(Std.parseInt(sec1[1]));
				curMeshInfo.uvIndices.push(Std.parseInt(sec2[1]));
				curMeshInfo.uvIndices.push(Std.parseInt(sec3[1]));
				
				curMeshInfo.normalIndices.push(Std.parseInt(sec1[2]));
				curMeshInfo.normalIndices.push(Std.parseInt(sec2[2]));
				curMeshInfo.normalIndices.push(Std.parseInt(sec3[2]));
			}
			else if (words[0] == "usemtl")
			{
				mtlNames.push(words[1]);
			}
			else if (words[0] == "mtllib")
			{
				mtlFileName = words[1];
			}
			else if (words[0] == "g")
			{
				curMeshInfo = { name:words[1],
								vertexIndices:new Vector<UInt>(),
								uvIndices:new Vector<UInt>(),
								normalIndices:new Vector<UInt>()
								};
				meshInfos.push(curMeshInfo);
			}
		}
		
		var results:Vector<Mesh> = new Vector<Mesh>();
		for (m in 0...meshInfos.length)
		{
			var info:MeshInfo = meshInfos[m];
			
			var mesh:Mesh = new Mesh();
		
			var vertices:Vector<Float> = new Vector<Float>();
			var uvs:Vector<Float> = new Vector<Float>();
			var normals:Vector<Float> = new Vector<Float>();
			
			var hasNormal:Bool = tempNormals.length > 0;

			for (i in 0...info.vertexIndices.length)
			{
				var vertexIndex:Int = (info.vertexIndices[i] - 1) * 3;
				var uvIndex:Int = (info.uvIndices[i] - 1) * 2;

				vertices.push(tempVertices[vertexIndex]);
				vertices.push(tempVertices[vertexIndex + 1]);
				vertices.push(tempVertices[vertexIndex + 2]);
				uvs.push(tempUVs[uvIndex]);
				uvs.push(tempUVs[uvIndex + 1]);
				
				if (hasNormal)
				{
					var normalIndex:Int = (info.normalIndices[i] - 1) * 3;
					normals.push(tempNormals[normalIndex]);
					normals.push(tempNormals[normalIndex + 1]);
					normals.push(tempNormals[normalIndex + 2]);
				}
				
			}

			build(vertices, uvs, normals);

			mesh.setVertexBuffer(BufferType.POSITION, 3, indexedVertices);
			mesh.setVertexBuffer(BufferType.TEXCOORD, 2, indexedUVs);
			if(hasNormal)
				mesh.setVertexBuffer(BufferType.NORMAL, 3, indexedNormals);
			mesh.setIndices(indices);
			mesh.setStatic();
			mesh.validate();
			
			results.push(mesh);
		}

		return results;
	}
	
	private function build(vertices:Vector<Float>, uvs:Vector<Float>, normals:Vector<Float>):Void 
	{
		indexedVertices = new Vector<Float>();
		indexedUVs = new Vector<Float>();
		indexedNormals =new Vector<Float>();
		indices = new Vector<UInt>();
		
		var hasNormal:Bool = normals.length > 0;

		// For each input vertex
		var count:Int = Std.int(vertices.length / 3);
		for (i in 0...count)
		{
			var i3:Int = i * 3;
			var i2:Int = i * 2;
			// Try to find a similar vertex in out_XXXX
			var found:Bool = false;
			
			//TODO 太耗时，容易超出时间限制
			//if (hasNormal)
				//found = getSimilarVertexIndex(vertices[i3], vertices[i3 + 1], vertices[i3 + 2],
													//uvs[i2], uvs[i2 + 1],
													//normals[i3], normals[i3 + 1], normals[i3 + 2]);
			//else
				//found = getSimilarVertexIndexNoNormal(vertices[i3], vertices[i3 + 1], vertices[i3 + 2],
													//uvs[i2], uvs[i2 + 1]);

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
				
				if (hasNormal)
				{
					indexedNormals.push(normals[i3]);
					indexedNormals.push(normals[i3 + 1]);
					indexedNormals.push(normals[i3 + 2]);
				}
				
				indices.push(Std.int(indexedVertices.length / 3) - 1);
			}
		}
		
		count = Std.int(indices.length / 3);
		for (i in 0...count)
		{
			var index0:Int = indices[i * 3];
			var index2:Int = indices[i * 3 + 2];
			indices[i * 3] = index2;
			indices[i * 3 + 2] = index0;
		}
	}

	// Returns true if v1 can be considered equal to v2
	private inline function isNear(v1:Float, v2:Float):Bool 
	{
		return Math.abs(v1 - v2) < 0.01;
	}
	
	private function getSimilarVertexIndexNoNormal( vertexX:Float, vertexY:Float, vertexZ:Float,
											uvX:Float, uvY:Float):Bool
	{
		// Lame linear search
		var count:Int = Std.int(indexedVertices.length / 3);
		for (i in 0...count)
		{
			var i3:Int = i * 3;
			var i2:Int = i * 2;
			if (isNear(vertexX, indexedVertices[i3]) &&
				isNear(vertexY, indexedVertices[i3 + 1]) &&
				isNear(vertexZ, indexedVertices[i3 + 2]) &&
				isNear(uvX    , indexedUVs     [i2]) &&
				isNear(uvY    , indexedUVs     [i2 + 1])) 
			{
				index = i;
				return true;
			}
		}
		// No other vertex could be used instead.
		// Looks like we'll have to add it to the VBO.
		return false;
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