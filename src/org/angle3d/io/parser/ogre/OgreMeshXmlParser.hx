package org.angle3d.io.parser.ogre;
import flash.Vector;
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
			
		}
		return meshes;
	}
	
	private function startSubMesh(subMesh:Fast):Void
	{
		if (!subMesh.has.operationtype || subMesh.att.operationtype != "triangle_list")
		{
			return;
		}
		
		if (subMesh.att.use32bitindexes == "true")
			return;
			
		usesSharedVerts = subMesh.att.usesharedvertices == "true";
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
		
		var vertices:Vector<Float>;
		var normals:Vector<Float>;
		var tangents:Vector<Float>;
		var binormals:Vector<Float>;
		var colors:Vector<Float>;
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
			mesh.setVertexBuffer(BufferType.TANGENT, 3, tangents);
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
}