package angle3d.math;

@:enum abstract PlaneSide(Int) {
	var Off = -1;
	var None = 0;
	var Positive = 1;
	var Negative = 2;

	inline function new(v:Int)
	this = v;

	public inline function toInt():Int
	return this;
}