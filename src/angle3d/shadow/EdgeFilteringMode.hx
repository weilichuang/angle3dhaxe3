package angle3d.shadow;

/**
 * ShadowEdgeFiltering specifies how shadows are filtered
 */
@:enum abstract EdgeFilteringMode(Int) {
	/**
	 * Shadows are not filtered. Nearest sample is used, causing in blocky
	 * shadows.
	 */
	var Nearest = 0;
	/**
	 * Bilinear filtering is used.
	 */
	var Bilinear = 1;
	/**
	 * 3x3 percentage-closer filtering is used. Shadows will be smoother at the
	 * cost of performance
	 */
	var PCF = 2;

	inline function new(v:Int)
	this = v;

	public inline function toInt():Int
	return this;
}