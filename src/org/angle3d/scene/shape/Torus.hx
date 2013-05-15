package org.angle3d.scene.shape;

import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.mesh.MeshHelper;
import org.angle3d.scene.mesh.SubMesh;
import flash.Vector;

class Torus extends Mesh
{
	public function new(radius:Float = 100.0, tubeRadius:Float = 40.0, segmentsR:UInt = 8, segmentsT:UInt = 6, yUp:Bool = false)
	{
		super();

		createTorus(radius, tubeRadius, segmentsR, segmentsT, yUp);
	}

	private function createTorus(radius:Float, tubeRadius:Float, segmentsR:UInt, segmentsT:UInt, yUp:Bool):Void
	{

		var _vertices:Vector<Float> = new Vector<Float>(segmentsR * segmentsT * 3, true);
		var _indices:Vector<UInt> = new Vector<UInt>(segmentsR * segmentsT * 6, true);
		var _verticesIndex:Int = 0;
		var _indiceIndex:Int = 0;
		var _grid:Vector<Vector<Int>> = new Vector<Vector<Int>>(segmentsR);


		for (i in 0...segmentsR)
		{
			_grid[i] = new Vector<Int>(segmentsT);
			for (j in 0...segmentsT)
			{
				var u:Float = i / segmentsR * 2 * Math.PI;
				var v:Float = j / segmentsT * 2 * Math.PI;
				if (yUp)
				{
					_vertices[_verticesIndex] = (radius + tubeRadius * Math.cos(v)) * Math.cos(u);
					_vertices[_verticesIndex + 1] = tubeRadius * Math.sin(v);
					_vertices[_verticesIndex + 2] = (radius + tubeRadius * Math.cos(v)) * Math.sin(u);

					_grid[i][j] = _indiceIndex;
					_indiceIndex++;
					_verticesIndex += 3;
				}
				else
				{
					_vertices[_verticesIndex] = (radius + tubeRadius * Math.cos(v)) * Math.cos(u);
					_vertices[_verticesIndex + 1] = -(radius + tubeRadius * Math.cos(v)) * Math.sin(u);
					_vertices[_verticesIndex + 2] = tubeRadius * Math.sin(v);

					_grid[i][j] = _indiceIndex;
					_indiceIndex++;
					_verticesIndex += 3;
				}
			}
		}

		var _uvt:Vector<Float> = new Vector<Float>(_indiceIndex * 2);

		var indiceIndex:Int = 0;
		for (i in 0...segmentsR)
		{
			for (j in 0...segmentsT)
			{
				var ip:Int = (i + 1) % segmentsR;
				var jp:Int = (j + 1) % segmentsT;
				var a:UInt = _grid[i][j];
				var b:UInt = _grid[ip][j];
				var c:UInt = _grid[i][jp];
				var d:UInt = _grid[ip][jp];

				// uvt
				_uvt[a * 2] = i / segmentsR;
				_uvt[a * 2 + 1] = j / segmentsT;

				_uvt[b * 2] = (i + 1) / segmentsR;
				_uvt[b * 2 + 1] = j / segmentsT;

				_uvt[c * 2] = i / segmentsR;
				_uvt[c * 2 + 1] = (j + 1) / segmentsT;

				_uvt[d * 2] = (i + 1) / segmentsR;
				_uvt[d * 2 + 1] = (j + 1) / segmentsT;

				//indices
				_indices[indiceIndex] = a;
				_indices[indiceIndex+1] = c;
				_indices[indiceIndex+2] = b;
				
				_indices[indiceIndex+3] = d;
				_indices[indiceIndex+4] = b;
				_indices[indiceIndex+5] = c;

				indiceIndex += 6;
			}
		}

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
