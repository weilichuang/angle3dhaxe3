package angle3d.io.parser.ms3d;



class MS3DVertex
{
	public var x:Float;
	public var y:Float;
	public var z:Float;

	public var bones:Array<Int>;
	public var weights:Array<Float>;

	public function new()
	{
		bones = new Array<Int>(4);
		weights = new Array<Float>(4);
		weights[0] = 1.0;
		weights[1] = 0.0;
		weights[2] = 0.0;
		weights[3] = 0.0;
	}
}