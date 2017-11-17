package org.angle3d.light;

/**
 * Describes the light type.
 */
@:enum abstract LightType(Int) {
	var None = -1;
	/**
	 * Directional light
	 *
	 * @see `DirectionalLight`
	 */
	var Directional = 0;

	/**
	 * Point light
	 *
	 * @see `PointLight`
	 */
	var Point = 1;

	/**
	 * Spot light.
	 *
	 * @see `SpotLight`
	 */
	var Spot = 2;

	/**
	 * Ambient light
	 *
	 * @see `AmbientLight`
	 */
	var Ambient = 3;

	/**
	 * Light probe
	 *
	 * @see `LightProbe`
	 */
	var Probe = 4;

	inline function new(v:Int)
	this = v;

	inline public function toInt():Int
	return this;

	public static function getLightTypeBy(name:String):LightType {
		if (name == "Directional") {
			return Directional;
		} else if (name == "Point") {
			return Point;
		} else if (name == "Spot") {
			return Spot;
		} else if (name == "Ambient") {
			return Ambient;
		} else if (name == "Probe") {
			return Probe;
		} else
		{
			return None;
		}
	}
}

