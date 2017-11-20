package org.angle3d.texture;

/**
* If this texture is a depth texture (the format is Depth*) then
* this value may be used to compare the texture depth to the R texture
* coordinate.
*/
@:enum abstract ShadowCompareMode(Int) {
	/**
	 * Shadow comparison mode is disabled.
	 * Texturing is done normally.
	 */
	var Off = 0;

	/**
	 * Compares the 3rd texture coordinate R to the value
	 * in this depth texture. If R <= texture value then result is 1.0,
	 * otherwise, result is 0.0. If filtering is set to bilinear or trilinear
	 * the implementation may sample the texture multiple times to provide
	 * smoother results in the range [0, 1].
	 */
	var LessOrEqual = 1;

	/**
	 * Compares the 3rd texture coordinate R to the value
	 * in this depth texture. If R >= texture value then result is 1.0,
	 * otherwise, result is 0.0. If filtering is set to bilinear or trilinear
	 * the implementation may sample the texture multiple times to provide
	 * smoother results in the range [0, 1].
	 */
	var GreaterOrEqual = 2;
}