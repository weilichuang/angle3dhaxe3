package org.angle3d.io.parser.obj;
import flash.display.Shape;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.Lib;
import flash.utils.ByteArray;
import flash.utils.Timer;
import flash.Vector;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.utils.Logger;
import org.angle3d.utils.TangentBinormalGenerator;

typedef MeshInfo = {
	mtl:String,
	name:String,
	vertexIndices:Vector<UInt>,
	uvIndices:Vector<UInt>,
	normalIndices:Vector<UInt>
}

class ObjParser extends EventDispatcher
{
	static var indexedVertices:Vector<Float>;
	static var indexedUVs:Vector<Float>;
	static var indexedNormals:Vector<Float>;
	static var index:Int;

	public var indices:Vector<UInt>;
	
	private var meshes:Vector<Dynamic>;
	
	private var tempVertices:Vector<Float>;
	private var tempUVs:Vector<Float>;
	private var tempNormals:Vector<Float>;
	
	private var meshInfos:Vector<MeshInfo>;
	
	private var curMeshInfo:MeshInfo;
	
	private var _curTime:Int;
	private var _timeLimit:Int = 1000;
	
	private var lines:Array<String>;
	private var curLine:Int;
	
	private var meshIndex:Int = 0;
	
	private var shape:Shape;
	
	public function new() 
	{
		super();
	}

	/**
	 * 异步解析
	 * @param	objData
	 */
	public function asyncParse(objData:String):Void
	{
		tempVertices = new Vector<Float>();
		tempUVs = new Vector<Float>();
		tempNormals = new Vector<Float>();
		meshInfos = new Vector<MeshInfo>();
		meshes = new Vector<Dynamic>();
		
		objData = ~/\n{2,}/g.replace(objData, "\n");
		
		lines = objData.split("\n");
		curLine = 0;
		
		meshIndex = 0;
		
		shape = new Shape();
		shape.addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}
	
	/**
	 * 同步解析
	 * @param	objData
	 */
	public function syncParse(objData:String):Vector<Dynamic>
	{
		tempVertices = new Vector<Float>();
		tempUVs = new Vector<Float>();
		tempNormals = new Vector<Float>();
		meshInfos = new Vector<MeshInfo>();
		
		objData = ~/\n{2,}/g.replace(objData, "\n");
		
		lines = objData.split("\n");
		curLine = 0;
		while (curLine < lines.length)
		{
			parseLine(lines[curLine]);
			curLine++;
		}
		
		meshes = new Vector<Dynamic>();
		meshIndex = 0;
		while (meshIndex < meshInfos.length)
		{
			generateMesh(meshInfos[meshIndex]);
			meshIndex++;
		}
		
		return meshes;
	}
	
	public function getMeshes():Vector<Dynamic>
	{
		return this.meshes;
	}
	
	private function onEnterFrame(event:Event):Void
	{
		_curTime = Lib.getTimer();
		proceedParsing();
	}
	
	private function proceedParsing():Void
	{
		while (curLine < lines.length && hasTime())
		{
			parseLine(lines[curLine]);
			curLine++;
		}
		
		while (meshIndex < meshInfos.length && hasTime())
		{
			generateMesh(meshInfos[meshIndex]);
			meshIndex++;
		}
		
		if (hasTime() && meshIndex >= meshInfos.length)
		{
			shape.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			shape = null;
			
			dispatchEvent(new Event(Event.COMPLETE));
		}
	}
	
	private function hasTime():Bool
	{
		return Lib.getTimer() - _curTime < _timeLimit;
	}
	
	private function generateMesh(info:MeshInfo):Void
	{
		var mesh:Mesh = new Mesh();

		var hasNormal:Bool = tempNormals.length > 0;
	
		var vertices:Vector<Float> = new Vector<Float>();
		var uvs:Vector<Float> = new Vector<Float>();
		var normals:Vector<Float> = new Vector<Float>();
		
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
		
		meshes.push({mesh:mesh,name:info.name,mtl:info.mtl});
	}
	
	private function generateMeshes():Void
	{
		var hasNormal:Bool = tempNormals.length > 0;
		
		for (m in 0...meshInfos.length)
		{
			
		}
		
		dispatchEvent(new Event(Event.COMPLETE));
	}
	
	private function parseLine(line:String):Void
	{
		line = ~/\s{2,}/g.replace(line, " ");
		line = ~/\r/g.replace(line, "");
		line = StringTools.trim(line);
		
		var words:Array<String> = line.split(" ");
		
		if (words[0] == "v") 
		{
			tempVertices.push(Std.parseFloat(words[1]));
			tempVertices.push(Std.parseFloat(words[2]));
			tempVertices.push(Std.parseFloat(words[3]));
		}
		else if (words[0] == "vt")
		{
			if (words.length >= 4)
			{
				var nTrunk:Array<Float> = [];
				var val:Float;
				for (i in 1...words.length)
				{
					val = Std.parseFloat(words[i]);
					if (!Math.isNaN(val))
						nTrunk.push(val);
				}
				
				tempUVs.push(nTrunk[0]);
				tempUVs.push(nTrunk[1]);
			}
			else
			{
				tempUVs.push(Std.parseFloat(words[1]));
				tempUVs.push(Std.parseFloat(words[2]));
			}
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
							mtl:"",
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
			
			if (words.length > 4)
			{
				var sec4:Array<String> = words[4].split("/");

				curMeshInfo.vertexIndices.push(Std.parseInt(sec1[0]));
				curMeshInfo.vertexIndices.push(Std.parseInt(sec3[0]));
				curMeshInfo.vertexIndices.push(Std.parseInt(sec4[0]));

				curMeshInfo.uvIndices.push(Std.parseInt(sec1[1]));
				curMeshInfo.uvIndices.push(Std.parseInt(sec3[1]));
				curMeshInfo.uvIndices.push(Std.parseInt(sec4[1]));
				
				curMeshInfo.normalIndices.push(Std.parseInt(sec1[2]));
				curMeshInfo.normalIndices.push(Std.parseInt(sec3[2]));
				curMeshInfo.normalIndices.push(Std.parseInt(sec4[2]));
			}
		}
		else if (words[0] == "usemtl")
		{
			//submesh
			if (curMeshInfo.mtl != "")
			{
				curMeshInfo = { name:curMeshInfo.name+"_"+words[1],
							mtl:words[1],
							vertexIndices:new Vector<UInt>(),
							uvIndices:new Vector<UInt>(),
							normalIndices:new Vector<UInt>()
							};
				meshInfos.push(curMeshInfo);
			}
			else
			{
				curMeshInfo.mtl = words[1];
			}
		}
		else if (words[0] == "mtllib")
		{
			//mtlFileName = words[1];
		}
		else if (words[0] == "g")
		{
			curMeshInfo = { name:words[1],
							mtl:"",
							vertexIndices:new Vector<UInt>(),
							uvIndices:new Vector<UInt>(),
							normalIndices:new Vector<UInt>()
							};
			meshInfos.push(curMeshInfo);
		}
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