package org.angle3d.material;

/**
 * Describes light rendering mode.
 */
class LightMode
{

	/**
	 * Disable light-based rendering
	 */
	public static inline var Disable:Int = 0;
	
	/**
	 * Enable light rendering by using a single pass. 
	 * <p>
	 * An array of light positions and light colors is passed to the shader
	 * containing the world light list for the geometry being rendered.
	 */
	public static inline var SinglePass:Int = 1;
	
	/**
	 * Enable light rendering by using multi-pass rendering.
	 * <p>
	 * The geometry will be rendered once for each light. Each time the
	 * light position and light color uniforms are updated to contain
	 * the values for the current light. The ambient light color uniform
	 * is only set_to the ambient light color on the first pass, future
	 * passes have it set_to black.
	 */
	public static inline var MultiPass:Int = 2;
	
	public static function getLightModeBy(name:String):Int
	{
		if (name == "Disable")
		{
			return Disable;
		}
		else if (name == "SinglePass")
		{
			return SinglePass;
		}
		else if (name == "MultiPass")
		{
			return MultiPass;
		}
		else
		{
			return -1;
		}
	}
}