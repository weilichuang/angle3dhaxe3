package org.angle3d.scene.shape;

import flash.Vector;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.mesh.MeshHelper;
import org.angle3d.scene.mesh.SubMesh;

class Cone extends Mesh
{
	public function new(radius:Float = 5.0, height:Float = 10.0, meridians:Int = 16)
	{
		super();

		createCone(radius, height, meridians);
	}

	private function createCone(radius:Float, height:Float, meridians:Int):Void
	{
		var vertex_no:Int = 0;

		var verticesLength:Int = meridians + 2;
		var indicesLength:Int = meridians * 2;

		var _vertices:Vector<Float> = new Vector<Float>();
		var _indices:Vector<UInt> = new Vector<UInt>();
		var _uvt:Vector<Float> = new Vector<Float>();

		_vertices[0] = 0;
		_vertices[1] = 0;
		_vertices[2] = 0;

		for (i in 0...meridians)
		{
			_vertices.push(radius * Math.cos(Math.PI * 2 / meridians * vertex_no));
			_vertices.push(0);
			_vertices.push(radius * Math.sin(Math.PI * 2 / meridians * vertex_no));
			vertex_no++;
		}

		_vertices.push(0);
		_vertices.push(height);
		_vertices.push(0);

		vertex_no = 0;

		for (i in 0...meridians - 1)
		{
			_indices.push(0);
			_indices.push(vertex_no + 1);
			_indices.push(vertex_no + 2);
			vertex_no++;
		}

		_indices.push(0);
		_indices.push(vertex_no + 1);
		_indices.push(1);

		vertex_no = 1;

		for (i in 0...meridians - 1)
		{
			_indices.push(vertex_no);
			_indices.push(meridians + 1);
			_indices.push(vertex_no + 1);
			vertex_no++;
		}

		_indices.push(vertex_no);
		_indices.push(meridians + 1);
		_indices.push(1);

		_uvt.push(0.5);
		_uvt.push(0.5);
		//_uvt.push(0);

		for (i in 0...Std.int(verticesLength / 2))
		{
			_uvt.push(1);
			_uvt.push(0);
				//_uvt.push(0);
		}

		for (i in 0...Std.int(verticesLength / 2))
		{
			_uvt.push(i / meridians);
			_uvt.push(0);
				//_uvt.push(0);
		}

		_uvt.push(0.5);
		_uvt.push(1);
		//_uvt.push(0);

		var _normals:Vector<Float> = MeshHelper.buildVertexNormals(_indices, _vertices);

		var subMesh:SubMesh = new SubMesh();
		subMesh.setVertexBuffer(BufferType.POSITION, 3, _vertices);
		subMesh.setVertexBuffer(BufferType.TEXCOORD, 2, _uvt);
		subMesh.setVertexBuffer(BufferType.NORMAL, 3, _normals);
		subMesh.setIndices(_indices);
		subMesh.validate();
		this.addSubMesh(subMesh);
		validate();
	}
}

