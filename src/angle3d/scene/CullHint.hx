package angle3d.scene;

/**
 * Specifies how frustum culling should be handled by this spatial.
 */
@:enum abstract CullHint(Int) {
	/**
	 * Do whatever our parent does. If no parent, we'll default to `Auto`.
	 */
	var Inherit = 0;
	/**
	 * Do not draw if we are not at least partially within the view frustum
	 * of the camera. This is determined via the defined
	 * Camera planes whether or not this Spatial should be culled.
	 */
	var Auto = 1;
	/**
	 * Always cull this from the view, throwing away this object
	 * and any children from rendering commands.
	 */
	var Always = 2;
	/**
	 * Never cull this from view, always draw it.
	 * Note that we will still get culled if our parent is culled.
	 */
	var Never = 3;

	inline function new(v:Int)
	this = v;

	public inline function toInt():Int
	return this;

}

