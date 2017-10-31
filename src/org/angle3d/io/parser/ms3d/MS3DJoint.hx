package org.angle3d.io.parser.ms3d;


import org.angle3d.math.Vector3f;


class MS3DJoint
{
	public var name:String;
	public var parentName:String;
	public var rotation:Vector3f;
	public var translation:Vector3f;

	public var rotationKeys:Vector<MS3DKeyframe>;
	public var positionKeys:Vector<MS3DKeyframe>;

	public function new()
	{
		rotation = new Vector3f();
		translation = new Vector3f();
	}
}
