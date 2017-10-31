package org.angle3d.io.parser.ms3d;

import org.angle3d.math.Vector3f;


class MS3DTriangle
{
	public var indices:Array<Int>;
	public var normals:Array<Vector3f>;
	public var tUs:Array<Float>;
	public var tVs:Array<Float>;
	public var groupIndex:Int;

	public function new()
	{
		indices = new Array<Int>(3);
		normals = new Array<Vector3f>(3);
		for (i in 0...3)
		{
			normals[i] = new Vector3f();
		}
		tUs = new Array<Float>(3);
		tVs = new Array<Float>(3);
	}
}
