package angle3d.collision.bih;

class BIHStackData {
	public var node:BIHNode;
	public var min:Float;
	public var max:Float;

	public function new(node:BIHNode, min:Float, max:Float) {
		this.node = node;
		this.min = min;
		this.max = max;
	}
}

