package org.angle3d.scene.mesh;

import org.angle3d.math.Vector3f;
import flash.Vector;

class MeshHelper
{
	public function new()
	{
	}

	/**
	 * 计算一个Mesh的顶点法向量
	 */
	public static function buildVertexNormals(indices:Vector<UInt>, vertices:Vector<Float>):Vector<Float>
	{
		var normals:Vector<Float> = new Vector<Float>(vertices.length);

		var adjs:Array<Array<UInt>> = buildVertexAdjancency(indices, vertices);
		var faceNormals:Vector<Float> = buildFaceNormal(indices, vertices);

		var i:Int;
		var index:Int;
		var refIndex:Int;
		var adj:Array<UInt>;
		var iLength:Int = indices.length;
		for (i in 0...iLength)
		{
			adj = adjs[indices[i]];

			_v0.setTo(0.0, 0.0, 0.0);

			for (n in 0...adj.length)
			{
				index = adj[n] * 3;
				_v0.x += faceNormals[index + 0];
				_v0.y += faceNormals[index + 1];
				_v0.z += faceNormals[index + 2];
			}

			_v0.normalizeLocal();

			refIndex = indices[i] * 3;
			normals[refIndex + 0] = _v0.x;
			normals[refIndex + 1] = _v0.y;
			normals[refIndex + 2] = _v0.z;
		}

		return normals;
	}

	public static function buildVertexAdjancency(indices:Vector<UInt>, vertices:Vector<Float>):Array<Array<UInt>>
	{
		var i:Int, j:Int, m:Int;

		var adjs:Array<Array<UInt>> = new Array<Array<UInt>>();

		i = 0;
		j = 0;
		while (i < indices.length)
		{
			for (m in 0...3)
			{
				var index:Int = indices[i + m];
				if (adjs[index] == null)
					adjs[index] = new Array<UInt>();
				//对应一个三角形
				adjs[index].push(j);
			}
			i += 3;
			j++;
		}

		return adjs;
	}

	private static var _v0:Vector3f = new Vector3f();
	private static var _v1:Vector3f = new Vector3f();
	private static var _v2:Vector3f = new Vector3f();

	public static function buildFaceNormal(indices:Vector<UInt>, vertices:Vector<Float>):Vector<Float>
	{
		var iLength:Int = indices.length;
		var faceNormals:Vector<Float> = new Vector<Float>(iLength);

		var index:Int;
		var p0x:Float, p0y:Float, p0z:Float;
		var p1x:Float, p1y:Float, p1z:Float;
		var p2x:Float, p2y:Float, p2z:Float;
		var i:Int = 0;
		while (i < iLength)
		{
			index = indices[i] * 3;
			p0x = vertices[index];
			p0y = vertices[index + 1];
			p0z = vertices[index + 2];

			index = indices[i + 1] * 3;
			p1x = vertices[index];
			p1y = vertices[index + 1];
			p1z = vertices[index + 2];

			index = indices[i + 2] * 3;
			p2x = vertices[index];
			p2y = vertices[index + 1];
			p2z = vertices[index + 2];

			_v0.setTo(p1x - p0x, p1y - p0y, p1z - p0z);
			_v1.setTo(p2x - p1x, p2y - p1y, p2z - p1z);

			_v2 = _v0.cross(_v1, _v2);
			_v2.normalizeLocal();

			faceNormals[i + 0] = _v2.x;
			faceNormals[i + 1] = _v2.y;
			faceNormals[i + 2] = _v2.z;
			
			i += 3;
		}

		return faceNormals;
	}


	public static function calculateFaceNormal(v0x:Float, v0y:Float, v0z:Float, v1x:Float, v1y:Float, v1z:Float, v2x:Float, v2y:Float, v2z:Float):Vector3f
	{
		_v0.setTo(v1x - v0x, v1y - v0y, v1z - v0z);
		_v1.setTo(v2x - v1x, v2y - v1y, v2z - v1z);

		_v2 = _v0.cross(_v1, _v2);
		_v2.normalizeLocal();

		return _v2.clone();
	}

	public static function buildVerexTangents(normals:Vector<Float>):Vector<Float>
	{
		var normalSize:Int = normals.length;

		var tangents:Vector<Float> = new Vector<Float>(normalSize);

		var tangent:Vector3f = new Vector3f();
		var normal:Vector3f = new Vector3f();
		var c1:Vector3f = new Vector3f();
		var c2:Vector3f = new Vector3f();
		var i:Int = 0;
		while (i < normalSize)
		{
			normal.setTo(normals[i], normals[i + 1], normals[i + 2]);
			normal.cross(Vector3f.UNIT_Z, c1);
			normal.cross(Vector3f.UNIT_Y, c2);

			if (c1.lengthSquared > c2.lengthSquared)
			{
				tangent.copyFrom(c1);
			}
			else
			{
				tangent.copyFrom(c2);
			}

			tangent.normalizeLocal();

			tangents[i] = tangent.x;
			tangents[i + 1] = tangent.y;
			tangents[i + 2] = tangent.z;
			
			i += 3;
		}
		return tangents;
	}
}
