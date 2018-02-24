package angle3d.io.parser.ogre;

import haxe.ds.IntMap;
import haxe.xml.Fast;
import angle3d.math.FastMath;
import angle3d.scene.mesh.BufferType;
import angle3d.scene.mesh.Mesh;
import angle3d.utils.Logger;

class OgreMeshXmlParser
{
	private var mesh:Mesh;
	
	private var meshes:Array<Mesh>;
	
	private var usesSharedVerts:Bool = false;
	private var usesSharedMesh:Array<Bool>;
	
	private var texCoordIndex:Int;
	
	private var lodLevels:IntMap<Array<Array<UInt>>>;

	public function new() 
	{
		
	}
	
	private function start():Void
	{
		texCoordIndex = 0;
		usesSharedVerts = false;
		meshes = new Array<Mesh>();
		usesSharedMesh = new Array<Bool>();
	}
	
	public function parse(data:String):Array<Mesh>
	{
		start();
		
		var xml:Xml = Xml.parse(data);
		var fast:Fast = new Fast(xml.firstElement());
		var submeshes:Fast = fast.node.submeshes;
		for (submesh in submeshes.nodes.submesh)
		{
			startSubMesh(submesh);
		}
		
		//lod
		if (fast.hasNode.levelofdetail)
		{
			if (lodLevels == null)
			{
				lodLevels = new IntMap<Array<Array<UInt>>>();
			}
			var lod:Fast = fast.node.levelofdetail;
			for (generated in lod.nodes.lodgenerated)
			{
				for (faceList in generated.nodes.lodfacelist)
				{
					startLodFaceList(faceList);
				}
			}
			
			for (i in 0...meshes.length)
			{
				var m:Mesh = meshes[i];
				if (lodLevels.exists(i))
				{
					m.setLodLevels(lodLevels.get(i));
				}
			}
		}
		
		return meshes;
	}
	
	private function startSubMesh(subMesh:Fast):Void
	{
		if (subMesh.has.operationtype && subMesh.att.operationtype != "triangle_list")
		{
			return;
		}
		
		if (subMesh.has.use32bitindexes && subMesh.att.use32bitindexes == "true")
			return;
			
		usesSharedVerts = subMesh.has.usesharedvertices ? subMesh.att.usesharedvertices == "true" : false;
		if (usesSharedVerts)
		{
			usesSharedMesh.push(true);
		}
		else
		{
			usesSharedMesh.push(false);
		}
		
		mesh = new Mesh();
		
		if (subMesh.has.material)
			mesh.id = subMesh.att.material;
		
		var faces:Fast = subMesh.node.faces;
		var indices:Array<UInt> = new Array<UInt>();
		
		var faceCount:Int = Std.parseInt(faces.att.count);
		for (face in faces.nodes.face)
		{
			indices.push(Std.parseInt(face.att.v3));
			indices.push(Std.parseInt(face.att.v2));
			indices.push(Std.parseInt(face.att.v1));
		}
		
		mesh.setIndices(indices);
		
		startGeometry(subMesh.node.geometry);
		
		var actuallyHasWeights:Bool = false;
		if (subMesh.hasNode.boneassignments)
		{
			var weights:Array<Float> = new Array<Float>(vertexCount * 4, true);
			var boneIndices:Array<Float> = new Array<Float>(vertexCount * 4, true);
			
			var boneassignments:Fast = subMesh.node.boneassignments;
			for (vertexbone in boneassignments.nodes.vertexboneassignment)
			{
				var vertexindex:Int = Std.parseInt(vertexbone.att.vertexindex);
				var boneindex:Int = Std.parseInt(vertexbone.att.boneindex);
				var weight:Float = Std.parseFloat(vertexbone.att.weight);
				
				var v:Float = 0;
				// see which weights are unused for a given bone
				var i:Int = vertexindex * 4;
				while (i < vertexindex * 4 + 4)
				{
					v = weights[i];
					if (v == 0)
					{
						break;
					}
					i++;
				}

				if (v != 0)
				{
					Logger.warn("Vertex ${vertexindex} has more than 4 weights per vertex! Ignoring..");
					continue;
				}
				
				weights[i] = weight;
				boneIndices[i] = boneindex;
				actuallyHasWeights = true;
			}
			
			
			if (actuallyHasWeights)
			{
				var maxWeightsPerVert:Int = 0;

				for (v in 0...vertexCount)
				{
					var w0:Float = weights[v * 4 + 0];
					var w1:Float = weights[v * 4 + 1];
					var w2:Float = weights[v * 4 + 2];
					var w3:Float = weights[v * 4 + 3];

					if (w3 != 0) 
					{
						maxWeightsPerVert = FastMath.maxInt(maxWeightsPerVert, 4);
					} 
					else if (w2 != 0)
					{
						maxWeightsPerVert = FastMath.maxInt(maxWeightsPerVert, 3);
					}
					else if (w1 != 0) 
					{
						maxWeightsPerVert = FastMath.maxInt(maxWeightsPerVert, 2);
					} 
					else if (w0 != 0)
					{
						maxWeightsPerVert = FastMath.maxInt(maxWeightsPerVert, 1);
					}

					var sum:Float = w0 + w1 + w2 + w3;
					if (sum != 1) 
					{
						// compute new vals based on sum
						var sumToB:Float = sum == 0 ? 0 : 1 / sum;
						weights[v * 4 + 0] = w0 * sumToB;
						weights[v * 4 + 1] = w1 * sumToB;
						weights[v * 4 + 2] = w2 * sumToB;
						weights[v * 4 + 3] = w3 * sumToB;
					}
				}
				
				mesh.setMaxNumWeights(maxWeightsPerVert);

				mesh.setVertexBuffer(BufferType.BONE_WEIGHTS,4, weights);
				mesh.setVertexBuffer(BufferType.BONE_INDICES,4, boneIndices);
			}
			
		}
		
		
		mesh.updateCounts();
		mesh.updateBound();
		mesh.setStatic();

		meshes.push(mesh);
	}
	
	private var vertexCount:Int;
	private function startGeometry(geometry:Fast):Void
	{
		if(geometry.has.vertexcount)
			vertexCount = Std.parseInt(geometry.att.vertexcount);
		else
			vertexCount = Std.parseInt(geometry.att.count);
		
		var vertexbuffer:Fast = geometry.node.vertexbuffer;
		
		var hasPosition:Bool = vertexbuffer.has.positions ? vertexbuffer.att.positions == "true" : false;
		var hasNormal:Bool = vertexbuffer.has.normals ? vertexbuffer.att.normals == "true" : false;
		var hasTangent:Bool = vertexbuffer.has.tangents ? vertexbuffer.att.tangents == "true" : false;
		var hasBinormal:Bool = vertexbuffer.has.binormals ? vertexbuffer.att.binormals == "true" : false;
		var hasColor:Bool = vertexbuffer.has.colours_diffuse ? vertexbuffer.att.colours_diffuse == "true" : false;
		var texCoordDimension:Int = vertexbuffer.has.texture_coord_dimensions_0 ? Std.parseInt(vertexbuffer.att.texture_coord_dimensions_0) : 2;
		var textureCoordNum:Int = vertexbuffer.has.texture_coords ? Std.parseInt(vertexbuffer.att.texture_coords) : 0;
		if (textureCoordNum > 4)
			textureCoordNum = 4;
			
		var tangentDimensions:Int = 3;
		
		var vertices:Array<Float> = null;
		var normals:Array<Float> = null;
		var tangents:Array<Float> = null;
		var binormals:Array<Float> = null;
		var colors:Array<Float> = null;
		if (hasPosition)
		{
			vertices = new Array<Float>();
		}
		
		if (hasNormal)
		{
			normals = new Array<Float>();
		}
		
		if (hasTangent)
		{
			if (vertexbuffer.has.tangent_dimensions)
				tangentDimensions = Std.parseInt(vertexbuffer.att.tangent_dimensions);
			tangents = new Array<Float>();
		}
		
		if (hasBinormal)
		{
			binormals = new Array<Float>();
		}
		
		if (hasColor)
		{
			colors = new Array<Float>();
		}
		
		
		var texCoords:Array<Array<Float>> = new Array<Array<Float>>();
		if (textureCoordNum > 0)
		{
			for (i in 0...textureCoordNum)
			{
				texCoords[i] = new Array<Float>();
			}
		}
			
		for (vertex in vertexbuffer.nodes.vertex)
		{
			texCoordIndex = 0;
			
			for (elem in vertex.elements)
			{
				if (elem.x.nodeType == Xml.Element)
				{
					switch(elem.x.nodeName)
					{
						case "position":
							vertices.push(Std.parseFloat(elem.att.x));
							vertices.push(Std.parseFloat(elem.att.y));
							vertices.push(Std.parseFloat(elem.att.z));
						case "normal":
							normals.push(Std.parseFloat(elem.att.x));
							normals.push(Std.parseFloat(elem.att.y));
							normals.push(Std.parseFloat(elem.att.z));
						case "tangent":
							tangents.push(Std.parseFloat(elem.att.x));
							tangents.push(Std.parseFloat(elem.att.y));
							tangents.push(Std.parseFloat(elem.att.z));
							if (tangentDimensions == 4)
								tangents.push(Std.parseFloat(elem.att.w));
							else
								tangents.push(1);
						case "binormal":
							binormals.push(Std.parseFloat(elem.att.x));
							binormals.push(Std.parseFloat(elem.att.y));
							binormals.push(Std.parseFloat(elem.att.z));
						case "colour_diffuse":
							var colorTxt:String = elem.att.value;
							var colorArrays:Array<String> = colorTxt.split(" ");
							colors.push(Std.parseFloat(colorArrays[0]));
							colors.push(Std.parseFloat(colorArrays[1]));
							colors.push(Std.parseFloat(colorArrays[2]));
							if(colorArrays.length == 4)
								colors.push(Std.parseFloat(colorArrays[3]));
							else
								colors.push(1);
						case "texcoord":
							if (texCoordIndex < textureCoordNum)
							{
								if (texCoordDimension >= 2)
								{
									texCoords[texCoordIndex].push(Std.parseFloat(elem.att.u));
									texCoords[texCoordIndex].push(Std.parseFloat(elem.att.v));
									
									if (texCoordDimension >= 3)
									{
										texCoords[texCoordIndex].push(Std.parseFloat(elem.att.w));
										if (texCoordDimension >= 4)
										{
											texCoords[texCoordIndex].push(Std.parseFloat(elem.att.x));
										}
									}
								}
							}
							texCoordIndex++;
					}
				}
			}
		}
		
		if (hasPosition)
		{
			mesh.setVertexBuffer(BufferType.POSITION, 3, vertices);
		}
		
		if (hasNormal)
		{
			mesh.setVertexBuffer(BufferType.NORMAL, 3, normals);
		}
		
		if (hasTangent)
		{
			mesh.setVertexBuffer(BufferType.TANGENT, 4, tangents);
		}
		
		if (hasBinormal)
		{
			mesh.setVertexBuffer(BufferType.BINORMAL, 3, binormals);
		}
		
		if (hasColor)
		{
			mesh.setVertexBuffer(BufferType.COLOR, 4, colors);
		}
		
		if (textureCoordNum > 0)
		{
			for (i in 0...textureCoordNum)
			{
				switch(i)
				{
					case 0:
						mesh.setVertexBuffer(BufferType.TEXCOORD, texCoordDimension, texCoords[i]);
					case 1:
						mesh.setVertexBuffer(BufferType.TEXCOORD2, texCoordDimension, texCoords[i]);
					case 2:
						mesh.setVertexBuffer(BufferType.TEXCOORD3, texCoordDimension, texCoords[i]);
					case 3:
						mesh.setVertexBuffer(BufferType.TEXCOORD4, texCoordDimension, texCoords[i]);
				}
				
			}
		}
	}
	
	private function startLodFaceList(faceList:Fast):Void
	{
		var submeshindex:Int = Std.parseInt(faceList.att.submeshindex);
		
		var levels:Array<Array<UInt>> = lodLevels.get(submeshindex);
		if (levels == null)
		{
			levels = new Array<Array<UInt>>();
			lodLevels.set(submeshindex, levels);
		}
		
		var indices:Array<UInt> = new Array<UInt>();
		for (face in faceList.nodes.face)
		{
			indices.push(Std.parseInt(face.att.v3));
			indices.push(Std.parseInt(face.att.v2));
			indices.push(Std.parseInt(face.att.v1));
		}
		levels.push(indices);
	}
}