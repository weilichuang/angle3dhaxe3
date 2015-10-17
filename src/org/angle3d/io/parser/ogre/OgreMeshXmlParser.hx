package org.angle3d.io.parser.ogre;
import flash.Vector;
import haxe.ds.IntMap;
import haxe.xml.Fast;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;

/**
 * ...
 * @author 
 */
class OgreMeshXmlParser
{
	private var mesh:Mesh;
	
	private var meshes:Vector<Mesh>;
	
	private var usesSharedVerts:Bool = false;
	private var usesSharedMesh:Vector<Bool>;
	
	private var texCoordIndex:Int;
	
	private var lodLevels:IntMap<Vector<Vector<UInt>>>;

	public function new() 
	{
		
	}
	
	private function start():Void
	{
		texCoordIndex = 0;
		usesSharedVerts = false;
		meshes = new Vector<Mesh>();
		usesSharedMesh = new Vector<Bool>();
	}
	
	public function parse(data:String):Vector<Mesh>
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
				lodLevels = new IntMap<Vector<Vector<UInt>>>();
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
		
		var faces:Fast = subMesh.node.faces;
		var indices:Vector<UInt> = new Vector<UInt>();
		
		var faceCount:Int = Std.parseInt(faces.att.count);
		for (face in faces.nodes.face)
		{
			indices.push(Std.parseInt(face.att.v3));
			indices.push(Std.parseInt(face.att.v2));
			indices.push(Std.parseInt(face.att.v1));
		}
		
		mesh.setIndices(indices);
		
		startGeometry(subMesh.node.geometry);
		
		mesh.updateCounts();
		mesh.updateBound();
		mesh.setStatic();

		meshes.push(mesh);
	}
	
	private function startGeometry(geometry:Fast):Void
	{
		var vertexCount:Int;
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
		
		var vertices:Vector<Float> = null;
		var normals:Vector<Float> = null;
		var tangents:Vector<Float> = null;
		var binormals:Vector<Float> = null;
		var colors:Vector<Float> = null;
		if (hasPosition)
		{
			vertices = new Vector<Float>();
		}
		
		if (hasNormal)
		{
			normals = new Vector<Float>();
		}
		
		if (hasTangent)
		{
			if (vertexbuffer.has.tangent_dimensions)
				tangentDimensions = Std.parseInt(vertexbuffer.att.tangent_dimensions);
			tangents = new Vector<Float>();
		}
		
		if (hasBinormal)
		{
			binormals = new Vector<Float>();
		}
		
		if (hasColor)
		{
			colors = new Vector<Float>();
		}
		
		
		var texCoords:Vector<Vector<Float>> = new Vector<Vector<Float>>();
		if (textureCoordNum > 0)
		{
			for (i in 0...textureCoordNum)
			{
				texCoords[i] = new Vector<Float>();
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
						case "binormal":
							binormals.push(Std.parseFloat(elem.att.x));
							binormals.push(Std.parseFloat(elem.att.y));
							binormals.push(Std.parseFloat(elem.att.z));
						case "colours_diffuse":
							colors.push(Std.parseFloat(elem.att.x));
							colors.push(Std.parseFloat(elem.att.y));
							colors.push(Std.parseFloat(elem.att.z));
							colors.push(Std.parseFloat(elem.att.w));
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
			mesh.setVertexBuffer(BufferType.TANGENT, tangentDimensions, tangents);
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
		
		var levels:Vector<Vector<UInt>> = lodLevels.get(submeshindex);
		if (levels == null)
		{
			levels = new Vector<Vector<UInt>>();
			lodLevels.set(submeshindex, levels);
		}
		
		var indices:Vector<UInt> = new Vector<UInt>();
		for (face in faceList.nodes.face)
		{
			indices.push(Std.parseInt(face.att.v3));
			indices.push(Std.parseInt(face.att.v2));
			indices.push(Std.parseInt(face.att.v1));
		}
		levels.push(indices);
	}
}