package org.angle3d.scene.shape;

import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;


class Cube extends Mesh
{
	public function new(width:Float = 10.0, height:Float = 10.0, depth:Float = 10.0, widthSegments:Int = 1, heightSegments:Int = 1, depthSegments:Int = 1)
	{
		super();
		createBox(width, height, depth, widthSegments, heightSegments, depthSegments);
	}

	private function createBox(width:Float, height:Float, depth:Float, widthSegments:Int, heightSegments:Int, depthSegments:Int):Void
	{
		var widthSegments1:Int = widthSegments + 1;
		var heightSegments1:Int = heightSegments + 1;
		var depthSegments1:Int = depthSegments + 1;

		var numVertices:Int = (widthSegments1 * heightSegments1 + widthSegments1 * depthSegments1 + heightSegments1 * depthSegments1) * 2;
		var _vertices:Array<Float> = new Array<Float>(numVertices * 3);
		var _normals:Array<Float> = new Array<Float>(numVertices * 3);
		var _tangents:Array<Float> = new Array<Float>(numVertices * 3);

		var _indices:Array<UInt> = new Array<UInt>((widthSegments * heightSegments + widthSegments * depthSegments + heightSegments * depthSegments) * 12);

		var topLeft:Int, topRight:Int, bottomLeft:Int, bottomRight:Int;
		var vertexIndex:Int = 0, indiceIndex:Int = 0;
		var outerPosition:Float;
		var increment:Int = 0;

		var deltaW:Float = width / widthSegments;
		var deltaH:Float = height / heightSegments;
		var deltaD:Float = depth / depthSegments;
		var halW:Float = width / 2, halH:Float = height / 2, halD:Float = depth / 2;

		// Front & Back faces
		for (i in 0...widthSegments1)
		{
			outerPosition = -halW + i * deltaW;
			for (j in 0...heightSegments1)
			{
				_normals[vertexIndex] = 0;
				_normals[vertexIndex + 1] = 0;
				_normals[vertexIndex + 2] = -1;
				_normals[vertexIndex + 3] = 0;
				_normals[vertexIndex + 4] = 0;
				_normals[vertexIndex + 5] = 1;

				_tangents[vertexIndex] = 1;
				_tangents[vertexIndex + 1] = 0;
				_tangents[vertexIndex + 2] = 0;
				_tangents[vertexIndex + 3] = -1;
				_tangents[vertexIndex + 4] = 0;
				_tangents[vertexIndex + 5] = 0;

				_vertices[vertexIndex] = outerPosition;
				_vertices[vertexIndex + 1] = -halH + j * deltaH;
				_vertices[vertexIndex + 2] = -halD;
				_vertices[vertexIndex + 3] = outerPosition;
				_vertices[vertexIndex + 4] = -halH + j * deltaH;
				_vertices[vertexIndex + 5] = halD;

				vertexIndex += 6;

				if (i != 0 && j != 0)
				{
					topLeft = 2 * ((i - 1) * (heightSegments + 1) + (j - 1));

					topRight = 2 * (i * (heightSegments + 1) + (j - 1));

					bottomLeft = topLeft + 2;

					bottomRight = topRight + 2;

					_indices[indiceIndex++] = bottomRight;
					_indices[indiceIndex++] = bottomLeft;
					_indices[indiceIndex++] = topLeft;
					
					_indices[indiceIndex++] = topRight;
					_indices[indiceIndex++] = bottomRight;
					_indices[indiceIndex++] = topLeft;
					
					_indices[indiceIndex++] = bottomLeft + 1;
					_indices[indiceIndex++] = bottomRight + 1;
					_indices[indiceIndex++] = topRight + 1;
					
					_indices[indiceIndex++] = topLeft + 1;
					_indices[indiceIndex++] = bottomLeft + 1;
					_indices[indiceIndex++] = topRight + 1;
				}
			}
		}

		increment += 2 * widthSegments1 * heightSegments1;

		// Top & Bottom faces
		for (i in 0...widthSegments1)
		{
			outerPosition = -halW + i * deltaW;
			for (j in 0...depthSegments1)
			{
				_normals[vertexIndex] = 0;
				_normals[vertexIndex + 1] = 1;
				_normals[vertexIndex + 2] = 0;
				_normals[vertexIndex + 3] = 0;
				_normals[vertexIndex + 4] = -1;
				_normals[vertexIndex + 5] = 0;

				_tangents[vertexIndex] = 1;
				_tangents[vertexIndex + 1] = 0;
				_tangents[vertexIndex + 2] = 0;
				_tangents[vertexIndex + 3] = 1;
				_tangents[vertexIndex + 4] = 0;
				_tangents[vertexIndex + 5] = 0;

				_vertices[vertexIndex] = outerPosition;
				_vertices[vertexIndex + 1] = halH;
				_vertices[vertexIndex + 2] = -halD + j * deltaD;
				_vertices[vertexIndex + 3] = outerPosition;
				_vertices[vertexIndex + 4] = -halH;
				_vertices[vertexIndex + 5] = -halD + j * deltaD;

				vertexIndex += 6;

				if (i != 0 && j != 0)
				{
					topLeft = increment + 2 * ((i - 1) * (depthSegments + 1) + (j - 1));
					topRight = increment + 2 * (i * (depthSegments + 1) + (j - 1));
					bottomLeft = topLeft + 2;
					bottomRight = topRight + 2;

					_indices[indiceIndex++] = bottomRight ;
					_indices[indiceIndex++] = bottomLeft;
					_indices[indiceIndex++] = topLeft;
					
					_indices[indiceIndex++] = topRight ;
					_indices[indiceIndex++] = bottomRight;
					_indices[indiceIndex++] = topLeft;
					
					_indices[indiceIndex++] = bottomLeft  + 1;
					_indices[indiceIndex++] = bottomRight + 1;
					_indices[indiceIndex++] = topRight + 1;
					
					_indices[indiceIndex++] = topLeft  + 1;
					_indices[indiceIndex++] = bottomLeft + 1;
					_indices[indiceIndex++] = topRight + 1;
				}
			}
		}

		increment += 2 * widthSegments1 * depthSegments1;

		//Left & Right faces
		for (i in 0...heightSegments1)
		{
			outerPosition = -halH + i * deltaH;
			for (j in 0...depthSegments1)
			{
				_normals[vertexIndex] = -1;
				_normals[vertexIndex + 1] = 0;
				_normals[vertexIndex + 2] = 0;
				_normals[vertexIndex + 3] = 1;
				_normals[vertexIndex + 4] = 0;
				_normals[vertexIndex + 5] = 0;

				_tangents[vertexIndex] = 0;
				_tangents[vertexIndex + 1] = 0;
				_tangents[vertexIndex + 2] = -1;
				_tangents[vertexIndex + 3] = 0;
				_tangents[vertexIndex + 4] = 0;
				_tangents[vertexIndex + 5] = 1;

				_vertices[vertexIndex] = -halW;
				_vertices[vertexIndex + 1] = outerPosition;
				_vertices[vertexIndex + 2] = -halD + j * deltaD;
				_vertices[vertexIndex + 3] = halW;
				_vertices[vertexIndex + 4] = outerPosition;
				_vertices[vertexIndex + 5] = -halD + j * deltaD;

				vertexIndex += 6;

				if (i != 0 && j != 0)
				{
					topLeft = increment + 2 * ((i - 1) * (depthSegments + 1) + (j - 1));
					topRight = increment + 2 * (i * (depthSegments + 1) + (j - 1));
					bottomLeft = topLeft + 2;
					bottomRight = topRight + 2;

					_indices[indiceIndex++] = bottomRight ;
					_indices[indiceIndex++] = bottomLeft;
					_indices[indiceIndex++] = topLeft;
					
					_indices[indiceIndex++] = topRight ;
					_indices[indiceIndex++] = bottomRight;
					_indices[indiceIndex++] = topLeft;
					
					_indices[indiceIndex++] = bottomLeft  + 1;
					_indices[indiceIndex++] = bottomRight + 1;
					_indices[indiceIndex++] = topRight + 1;
					
					_indices[indiceIndex++] = topLeft  + 1;
					_indices[indiceIndex++] = bottomLeft + 1;
					_indices[indiceIndex++] = topRight + 1;
				}
			}
		}

		//UVTs
		var numUvs:Int = (widthSegments1 * heightSegments1 + widthSegments1 * depthSegments1 + heightSegments1 * depthSegments1) * 4;
		var _uvt:Array<Float> = new Array<Float>(numUvs, true);
		var uvIndex:Int = 0;
		for (i in 0...widthSegments1)
		{
			outerPosition = (i / widthSegments);

			for (j in 0...heightSegments1)
			{
				_uvt[uvIndex++] = outerPosition;
				_uvt[uvIndex++] = 1 - (j / heightSegments);
				_uvt[uvIndex++] = 1 - outerPosition;
				_uvt[uvIndex++] = 1 - (j / heightSegments);
			}
		}

		for (i in 0...widthSegments1)
		{
			outerPosition = (i / widthSegments);

			for (j in 0...depthSegments1)
			{
				_uvt[uvIndex++] = outerPosition;
				_uvt[uvIndex++] = 1 - (j / depthSegments);
				_uvt[uvIndex++] = outerPosition;
				_uvt[uvIndex++] = j / depthSegments;
			}
		}

		for (i in 0...heightSegments1)
		{
			outerPosition = (i / heightSegments);
			for (j in 0...depthSegments1)
			{
				_uvt[uvIndex++] = 1 - (j / depthSegments);
				_uvt[uvIndex++] = 1 - outerPosition;
				_uvt[uvIndex++] = j / depthSegments;
				_uvt[uvIndex++] = 1 - outerPosition;
			}
		}

		setVertexBuffer(BufferType.POSITION, 3, _vertices);
		setVertexBuffer(BufferType.TEXCOORD, 2, _uvt);
		setVertexBuffer(BufferType.NORMAL, 3, _normals);
		setVertexBuffer(BufferType.TANGENT, 3, _tangents);
		setIndices(_indices);
		validate();
	}
}

