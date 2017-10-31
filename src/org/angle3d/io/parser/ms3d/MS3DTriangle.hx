package org.angle3d.io.parser.ms3d;

import org.angle3d.math.Vector3f;


class MS3DTriangle
{
	public var indices:Vector<Int>;
	public var normals:Vector<Vector3f>;
	public var tUs:Vector<Float>;
	public var tVs:Vector<Float>;
	public var groupIndex:Int;

	public function new()
	{
		indices = new Vector<Int>(3);
		normals = new Vector<Vector3f>(3);
		for (i in 0...3)
		{
			normals[i] = new Vector3f();
		}
		tUs = new Vector<Float>(3);
		tVs = new Vector<Float>(3);
	}
}
