package org.angle3d.light;


/**
 * Describes the light type.
 */
enum LightType
{
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
	
	/**
	 * Ambient light
	 * 
	 * @see AmbientLight
	 */
	Ambient;
}

