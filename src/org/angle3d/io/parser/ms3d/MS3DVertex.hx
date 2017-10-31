package org.angle3d.io.parser.ms3d;



class MS3DVertex
{
	public var x:Float;
	public var y:Float;
	public var z:Float;

	public var bones:Vector<Int>;
	public var weights:Vector<Float>;

	public function new()
	{
		bones = new Vector<Int>(4);
		weights = new Vector<Float>(4);
		weights[0] = 1.0;
		weights[1] = 0.0;
		weights[2] = 0.0;
		weights[3] = 0.0;
	}
}