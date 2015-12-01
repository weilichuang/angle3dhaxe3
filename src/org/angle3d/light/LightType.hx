package org.angle3d.light;


/**
 * Describes the light type.
 */
class LightType
{
	/**
	 * Directional light
	 *
	 * @see DirectionalLight
	 */
	public static inline var Directional:Int = 0;

	/**
	 * Point light
	 *
	 * @see PointLight
	 */
	public static inline var Point:Int = 1;

	/**
	 * Spot light.
	 *
	 * @see SpotLight
	 */
	public static inline var Spot:Int = 2;
	
	/**
	 * Ambient light
	 * 
	 * @see AmbientLight
	 */
	public static inline var Ambient:Int = 3;
	
	public static function getLightTypeBy(name:String):Int
	{
		if (name == "Directional")
		{
			return Directional;
		}
		else if (name == "Point")
		{
			return Point;
		}
		else if (name == "Spot")
		{
			return Spot;
		}
		else if (name == "Ambient")
		{
			return Ambient;
		}
		else
		{
			return -1;
		}
	}
}

