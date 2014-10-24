package org.angle3d.scene.shape;

import de.polygonal.core.math.Mathematics;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;
import flash.Vector;

/**
 * A UV Sphere primitive mesh.
 */
class Sphere extends Mesh
{
	/**
	 * The radius of the sphere.
	 */
	public var radius(get, set):Float;
	
	/**
	 * Defines the number of horizontal segments that make up the sphere. Defaults to 16.
	 */
	public var segmentsW(get, set):Int;
	
	/**
	 * Defines the number of vertical segments that make up the sphere. Defaults to 12.
	 */
	public var segmentsH(get, set):Int;
	
	/**
	 * Defines whether the sphere poles should lay on the Y-axis (true) or on the Z-axis (false).
	 */
	public var yUp(get, set):Bool;
	
	private var _radius:Float;
	private var _segmentsW:Int;
	private var _segmentsH:Int;
	private var _yUp:Bool;

	/**
	 * Creates a new Sphere object.
	 * @param radius The radius of the sphere.
	 * @param segmentsW Defines the number of horizontal segments that make up the sphere. Defaults to 16.
	 * @param segmentsH Defines the number of vertical segments that make up the sphere. Defaults to 12.
	 * @param yUp Defines whether the sphere poles should lay on the Y-axis (true) or on the Z-axis (false).
	 */
	public function new(radius:Float = 50, segmentsW:Int = 16, segmentsH:Int = 12, yUp:Bool = true)
	{
		super();

		_radius = radius;
		_segmentsW = segmentsW;
		_segmentsH = segmentsH;
		_yUp = yUp;


		buildGeometry();
	}

	/**
	 * @inheritDoc
	 */
	private function buildGeometry():Void
	{
		var triIndex:Int = 0;
		var numVerts:Int = (_segmentsH + 1) * (_segmentsW + 1);

		var vertices:Vector<Float> = new Vector<Float>(numVerts * 3);
		var vertexNormals:Vector<Float> = new Vector<Float>(numVerts * 3);
		var vertexTangents:Vector<Float> = new Vector<Float>(numVerts * 3);
		var indices:Vector<UInt> = new Vector<UInt>((_segmentsH - 1) * _segmentsW * 6);

		numVerts = 0;
		for (j in 0..._segmentsH + 1)
		{
			var horangle:Float = Math.PI * j / _segmentsH;
			var z:Float = -_radius * Math.cos(horangle);
			var ringradius:Float = _radius * Math.sin(horangle);

			for (i in 0..._segmentsW + 1)
			{
				var verangle:Float = 2 * Math.PI * i / _segmentsW;
				var x:Float = ringradius * Math.cos(verangle);
				var y:Float = ringradius * Math.sin(verangle);
				var normLen:Float = Mathematics.invSqrt(x * x + y * y + z * z);
				var tanLen:Float = Math.sqrt(y * y + x * x);

				if (_yUp)
				{
					vertexNormals[numVerts] = x * normLen;
					vertexTangents[numVerts] = tanLen > .007 ? -y / tanLen : 1;
					vertices[numVerts++] = x;
					
					vertexNormals[numVerts] = -z * normLen;
					vertexTangents[numVerts] = 0;
					vertices[numVerts++] = -z;
					
					vertexNormals[numVerts] = y * normLen;
					vertexTangents[numVerts] = tanLen > .007 ? x / tanLen : 0;
					vertices[numVerts++] = y;
				}
				else
				{
					vertexNormals[numVerts] = x * normLen;
					vertexTangents[numVerts] = tanLen > .007 ? -y / tanLen : 1;
					vertices[numVerts++] = x;
					
					vertexNormals[numVerts] = y * normLen;
					vertexTangents[numVerts] = tanLen > .007 ? x / tanLen : 0;
					vertices[numVerts++] = y;
					
					vertexNormals[numVerts] = z * normLen;
					vertexTangents[numVerts] = 0;
					vertices[numVerts++] = z;
				}

				if (i > 0 && j > 0)
				{
					var a:Int = (_segmentsW + 1) * j + i;
					var b:Int = (_segmentsW + 1) * j + i - 1;
					var c:Int = (_segmentsW + 1) * (j - 1) + i - 1;
					var d:Int = (_segmentsW + 1) * (j - 1) + i;

					if (j == _segmentsH)
					{
						indices[triIndex++] = d;
						indices[triIndex++] = c;
						indices[triIndex++] = a;
					}
					else if (j == 1)
					{
						indices[triIndex++] = c;
						indices[triIndex++] = b;
						indices[triIndex++] = a;
					}
					else
					{
						indices[triIndex++] = c;
						indices[triIndex++] = b;
						indices[triIndex++] = a;
						indices[triIndex++] = d;
						indices[triIndex++] = c;
						indices[triIndex++] = a;
					}
				}
			}
		}

		var numUvs:Int = (_segmentsH + 1) * (_segmentsW + 1) * 2;
		var uvData:Vector<Float> = new Vector<Float>(numUvs);
		numUvs = 0;
		for (j in 0..._segmentsH+1)
		{
			for (i in 0..._segmentsW+1)
			{
				uvData[numUvs++] = i / _segmentsW;
				uvData[numUvs++] = j / _segmentsH;
			}
		}

		setVertexBuffer(BufferType.POSITION, 3, vertices);
		setVertexBuffer(BufferType.TEXCOORD, 2, uvData);
		setVertexBuffer(BufferType.NORMAL, 3, vertexNormals);
		setVertexBuffer(BufferType.TANGENT, 3, vertexTangents);
		setIndices(indices);
		validate();
	}

	private function get_radius():Float
	{
		return _radius;
	}
	
	private function set_radius(value:Float):Float
	{
		_radius = value;
		buildGeometry();
		return _radius;
	}

	private function get_segmentsW():Int
	{
		return _segmentsW;
	}
	
	private function set_segmentsW(value:Int):Int
	{
		_segmentsW = value;
		buildGeometry();
		return _segmentsW;
	}

	private function get_segmentsH():Int
	{
		return _segmentsH;
	}
	
	private function set_segmentsH(value:Int):Int
	{
		_segmentsH = value;
		buildGeometry();
		return _segmentsH;
	}

	private function get_yUp():Bool
	{
		return _yUp;
	}
	
	private function set_yUp(value:Bool):Bool
	{
		_yUp = value;
		buildGeometry();
		return _yUp;
	}
}
