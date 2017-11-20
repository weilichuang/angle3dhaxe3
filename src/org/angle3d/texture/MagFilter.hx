package org.angle3d.texture;

/**
 * ...
 * @author
 */
@:enum abstract MagFilter(Int) {
	/**
	 * Nearest neighbor interpolation is the fastest and crudest filtering
	 * mode - it simply uses the color of the texel closest to the pixel
	 * center for the pixel color. While fast, this results in texture
	 * 'blockiness' during magnification. (GL equivalent: GL_NEAREST)
	 */
	var Nearest = 0;

	/**
	 * In this mode the four nearest texels to the pixel center are sampled
	 * (at the closest mipmap level), and their colors are combined by
	 * weighted average according to distance. This removes the 'blockiness'
	 * seen during magnification, as there is now a smooth gradient of color
	 * change from one texel to the next, instead of an abrupt jump as the
	 * pixel center crosses the texel boundary. (GL equivalent: GL_LINEAR)
	 */
	var Bilinear = 1;
}