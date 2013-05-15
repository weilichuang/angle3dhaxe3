package org.angle3d.io.parser.ms3d;

import flash.Vector;

class MS3DKeyframe
{
	public var time:Float;
	public var data:Vector<Float>;

	public function new()
	{
		data = new Vector<Float>(3);
	}
}
