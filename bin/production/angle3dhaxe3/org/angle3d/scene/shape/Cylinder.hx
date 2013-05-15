package org.angle3d.scene.shape;

import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.mesh.MeshHelper;
import org.angle3d.scene.mesh.SubMesh;
import flash.Vector;

/**
 * A simple cylinder, defined by it's height and radius.
 */
class Cylinder extends Mesh
{

	public function new(radius:Float = 5.0, height:Float = 10.0, parallels:Int = 1, meridians:Int = 16)
	{
		super();

		createCylinder(radius, height, parallels, meridians);
	}

	private function createCylinder(radius:Float, height:Float, parallels:Int, meridians:Int):Void
	{
		//var _verticesLength : int	= _meridians * (_parallels + 1) + 2;

		var _vertices:Vector<Float> = new Vector<Float>();
		var _indices:Vector<UInt> = new Vector<UInt>();
		var _uvt:Vector<Float> = new Vector<Float>();

		_vertices[0] = 0;
		_vertices[1] = 0;
		_vertices[2] = 0;

		for (j in 0...parallels + 1)
		{
			for (i in 0...meridians)
			{
				_vertices.push(radius * Math.cos(Math.PI * 2 / meridians * i));
				_vertices.push(j * (height / parallels));
				_vertices.push(radius * Math.sin(Math.PI * 2 / meridians * i));
			}
		}

		_vertices.push(0);
		_vertices.push(height);
		_vertices.push(0);


		for (i in 0..._vertices.length)
		{
			_vertices[i] = Std.int(_vertices[i] * 100) / 100;
		}

		////////
		for (i in 0...meridians - 1)
		{
			_indices.push(0);
			_indices.push(i + 1);
			_indices.push(i + 2);
		}

		_indices.push(0);
		_indices.push(meridians);
		_indices.push(1);

		////////

		for (j in 0...parallels)
		{
			for (i in 0...meridians - 1)
			{
				_indices.push(i + 1 + (j * meridians));
				_indices.push(i + meridians + 1 + (j * meridians));
				_indices.push(i + 2 + (j * meridians));
			}

			_indices.push(meridians + (j * meridians));
			_indices.push(meridians * 2 + (j * meridians));
			_indices.push(1 + (j * meridians));


			for (i in 0...meridians - 1)
			{
				_indices.push(i + meridians + 2 + (j * meridians));
				_indices.push(i + 2 + (j * meridians));
				_indices.push(i + meridians + 1 + (j * meridians));
			}

			_indices.push(meridians + 1 + (j * meridians));
			_indices.push(1 + (j * meridians));
			_indices.push(meridians * 2 + (j * meridians));
		}

		//////////
		for (i in 0...meridians - 1)
		{
			_indices.push((meridians * (parallels + 1)) + 1);
			_indices.push((meridians * parallels) + i + 2);
			_indices.push((meridians * parallels) + i + 1);
		}

		_indices.push((meridians * (parallels + 1)) + 1);
		_indices.push(meridians * parallels + 1);
		_indices.push(meridians * (parallels + 1));



		//	Lib.trace(_indices);
		//	Lib.trace(i);

		_uvt.push(0.5);
		_uvt.push(0.5);
		//_uvt.push(0);

		for (j in 0...parallels+1)
		{
			for (i in 0...meridians)
			{
				_uvt.push(i / meridians);
				_uvt.push(j / parallels);
					//_uvt.push(0);
			}
		}

		_uvt.push(0.5);
		_uvt.push(0.5);
		//_uvt.push(0);

		/*for(i = 0; i < _vertices.length; i++)
		{
		_uvt.push(i/_vertices.length);
		_uvt.push(i/_vertices.length);
		_uvt.push(0);
		}*/

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

