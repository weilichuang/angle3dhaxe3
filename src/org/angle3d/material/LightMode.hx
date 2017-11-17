package org.angle3d.material;

/**
 * Describes light rendering mode.
 */
@:enum abstract LightMode(Int) {

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

	/**
	 * Similar to `SinglePass` except the type of each light is known
	 * at shader compile time.
	 * <p>
	 * The advantage is that the shader can be much more efficient, i.e. not
	 * do operations required for spot and point lights if it knows the
	 * light is a directional light. The disadvantage is that the number of
	 * shaders used balloons because of the variations in the number of
	 * lights used by objects.
	 */
	var StaticPass = 3;

	/**
	 * Enable light rendering by using a single pass, and also uses Image based lighting for global lighting
	 * Usually used for PBR
	 * <p>
	 * An array of light positions and light colors is passed to the shader
	 * containing the world light list for the geometry being rendered.
	 * Also Light probes are passed to the shader.
	 */
	var SinglePassAndImageBased = 4;

	public static function getLightModeBy(name:String):LightMode {
		if (name == "SinglePass") {
			return SinglePass;
		} else if (name == "MultiPass") {
			return MultiPass;
		} else if (name == "StaticPass") {
			return StaticPass;
		} else if (name == "SinglePassAndImageBased") {
			return SinglePassAndImageBased;
		} else
		{
			return Disable;
		}
	}

	public static function getLightModeName(model:LightMode):String {
		if (model == SinglePass) {
			return "SinglePass";
		} else if (model == MultiPass) {
			return "MultiPass";
		} else if (model == StaticPass) {
			return "StaticPass";
		} else if (model == SinglePassAndImageBased) {
			return "SinglePassAndImageBased";
		} else
		{
			return "Disable";
		}
	}
}