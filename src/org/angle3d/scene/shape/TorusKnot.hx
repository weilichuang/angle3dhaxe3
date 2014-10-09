package org.angle3d.scene.shape;

import flash.Vector;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.mesh.MeshHelper;

class TorusKnot extends Mesh
{
	public function new(radius:Float = 100.0, tubeRadius:Float = 40.0, 
						segmentsR:Int = 8, segmentsT:Int = 6, 
						yUp:Bool = false, p:Int = 2, 
						q:Int = 3, heightScale:Float = 1)
	{
		super();

		createKnotTorus(radius, tubeRadius, segmentsR, segmentsT, yUp, p, q, heightScale);
	}

	private function createKnotTorus(radius:Float, tubeRadius:Float, 
									segmentsR:Int, segmentsT:Int, 
									yUp:Bool, p:Int, 
									q:Int, heightScale:Float):Void
	{
		var verticesIndex:Int = 0;
		var _indiceIndex:Int = 0;
		var _grid:Vector<Vector<Int>> = new Vector<Vector<Int>>(segmentsR);
		var _tang:Vector3f = new Vector3f();
		var _n:Vector3f = new Vector3f();
		var _bitan:Vector3f = new Vector3f();

		var vertices:Vector<Float> = new Vector<Float>(segmentsR * segmentsT * 3);
		for (i in 0...segmentsR)
		{
			_grid[i] = new Vector<Int>(segmentsT);
			for (j in 0...segmentsT)
			{
				var u:Float = i / segmentsR * 2 * p * Math.PI;
				var v:Float = j / segmentsT * 2 * Math.PI;
				var vec:Vector3f = getPos(radius, p, q, heightScale, u, v);
				var vec2:Vector3f = getPos(radius, p, q, heightScale, u + .01, v);
				var cx:Float, cy:Float;

				_tang.x = vec2.x - vec.x;
				_tang.y = vec2.y - vec.y;
				_tang.z = vec2.z - vec.z;
				_n.x = vec2.x + vec.x;
				_n.y = vec2.y + vec.y;
				_n.z = vec2.z + vec.z;
				_bitan = _n.cross(_tang);
				_n = _tang.cross(_bitan);
				_bitan.normalizeLocal();
				_n.normalizeLocal();

				cx = tubeRadius * Math.cos(v);
				cy = tubeRadius * Math.sin(v);
				vec.x += cx * _n.x + cy * _bitan.x;
				vec.y += cx * _n.y + cy * _bitan.y;
				vec.z += cx * _n.z + cy * _bitan.z;

				
				vertices[verticesIndex] = vec.x;
				if (yUp)
				{
					vertices[verticesIndex + 1] = vec.z;
					vertices[verticesIndex + 2] = vec.y;
				}
				else 
				{
					vertices[verticesIndex + 1] = -vec.y;
					vertices[verticesIndex + 2] = vec.z;
				}
				_grid[i][j] = _indiceIndex;
				_indiceIndex++;
				verticesIndex += 3;
			}
		}

		var uvt:Vector<Float> = new Vector<Float>(_indiceIndex * 2);
		var indices:Vector<UInt> = new Vector<UInt>(segmentsR * segmentsT * 6);
		var indicesSize:Int = 0;
		for (i in 0...segmentsR)
		{
			for (j in 0...segmentsT)
			{
				var ip:Int = (i + 1) % segmentsR;
				var jp:Int = (j + 1) % segmentsT;
				var a:Int = _grid[i][j];
				var b:Int = _grid[ip][j];
				var c:Int = _grid[i][jp];
				var d:Int = _grid[ip][jp];

				// uvt
				uvt[a * 2] = i / segmentsR;
				uvt[a * 2 + 1] = j / segmentsT;

				uvt[b * 2] = (i + 1) / segmentsR;
				uvt[b * 2 + 1] = j / segmentsT;

				uvt[c * 2] = i / segmentsR;
				uvt[c * 2 + 1] = (j + 1) / segmentsT;

				uvt[d * 2] = (i + 1) / segmentsR;
				uvt[d * 2 + 1] = (j + 1) / segmentsT;

				//indices
				indices[indicesSize] = a;
				indices[indicesSize + 1] = c;
				indices[indicesSize + 2] = b;
				indices[indicesSize + 3] = d;
				indices[indicesSize + 4] = b;
				indices[indicesSize + 5] = c;
				indicesSize += 6;
			}
		}

		var normals:Vector<Float> = MeshHelper.buildVertexNormals(indices, vertices);
		setVertexBuffer(BufferType.POSITION, 3, vertices);
		setVertexBuffer(BufferType.TEXCOORD, 2, uvt);
		setVertexBuffer(BufferType.NORMAL, 3, normals);
		setIndices(indices);
		validate();
	}

	private function getPos(radius:Float, p:Int, q:Int, heightScale:Float, u:Float, v:Float):Vector3f
	{
		var cu:Float = Math.cos(u);
		var su:Float = Math.sin(u);
		var quOverP:Float = q / p * u;
		var cs:Float = Math.cos(quOverP);
		var pos:Vector3f = new Vector3f();

		pos.x = radius * (2 + cs) * .5 * cu;
		pos.y = radius * (2 + cs) * su * .5;
		pos.z = heightScale * radius * Math.sin(quOverP) * .5;

		return pos;
	}
}

