package angle3d.scene.shape;

class WireframeLineSet {
	public var sx:Float;
	public var sy:Float;
	public var sz:Float;

	public var ex:Float;
	public var ey:Float;
	public var ez:Float;

	public var r:Float;
	public var g:Float;
	public var b:Float;

	public function new(sx:Float, sy:Float, sz:Float, ex:Float, ey:Float, ez:Float, r:Float = 0, g:Float = 0, b:Float = 0) {
		this.sx = sx;
		this.sy = sy;
		this.sz = sz;

		this.ex = ex;
		this.ey = ey;
		this.ez = ez;

		this.r = r;
		this.g = g;
		this.b = b;
	}

	public function setTo(sx:Float, sy:Float, sz:Float, ex:Float, ey:Float, ez:Float, r:Float = 0, g:Float = 0, b:Float = 0):Void {
		this.sx = sx;
		this.sy = sy;
		this.sz = sz;

		this.ex = ex;
		this.ey = ey;
		this.ez = ez;

		this.r = r;
		this.g = g;
		this.b = b;
	}
}

