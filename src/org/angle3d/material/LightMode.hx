package org.angle3d.material;

/**
 * Describes light rendering mode.
 */
@:enum abstract LightMode(Int)  
{

	/**
	 * Disable light-based rendering
	 */
	var Disable = 0;
	
	/**
	 * Enable light rendering by using a single pass. 
	 * <p>
	 * An array of light positions and light colors is passed to the shader
	 * containing the world light list for the geometry being rendered.
	 */
	var SinglePass = 1;
	
	/**
	 * Enable light rendering by using multi-pass rendering.
	 * <p>
	 * The geometry will be rendered once for each light. Each time the
	 * light position and light color uniforms are updated to contain
	 * the values for the current light. The ambient light color uniform
	 * is only set_to the ambient light color on the first pass, future
	 * passes have it set_to black.
	 */
	var MultiPass = 2;
	
	public static function getLightModeBy(name:String):LightMode
	{
		if (name == "SinglePass")
		{
			return SinglePass;
		}
		else if (name == "MultiPass")
		{
			return MultiPass;
		}
		else
		{
			return Disable;
		}
	}
}