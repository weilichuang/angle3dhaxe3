package org.angle3d.light;


/**
 * Describes the light type.
 */
enum LightType
{
	None;

	/**
	 * Directional light
	 *
	 * @see DirectionalLight
	 */
	Directional;

	/**
	 * Point light
	 *
	 * @see PointLight
	 */
	Point;

	/**
	 * Spot light.
	 *
	 * @see SpotLight
	 */
	Spot;
}

