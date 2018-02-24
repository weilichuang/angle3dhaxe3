package angle3d.texture;

/**
 * ...
 * @author
 */
enum ImageFormat {
	/**
	 * 8-bit alpha
	 */
	Alpha8;

	/**
	 * 8-bit grayscale/luminance.
	 */
	Luminance8;

	/**
	 * half-precision floating-point grayscale/luminance.
	 *
	 * Requires {@link Caps#FloatTexture}.
	 */
	Luminance16F;

	/**
	 * single-precision floating-point grayscale/luminance.
	 *
	 * Requires {@link Caps#FloatTexture}.
	 */
	Luminance32F;

	/**
	 * 8-bit luminance/grayscale and 8-bit alpha.
	 */
	Luminance8Alpha8;

	/**
	 * half-precision floating-point grayscale/luminance and alpha.
	 *
	 * Requires {@link Caps#FloatTexture}.
	 */
	Luminance16FAlpha16F;

	/**
	 * 8-bit blue, green, and red.
	 */
	BGR8;// BGR and ABGR formats are often used on windows systems

	/**
	 * 8-bit red, green, and blue.
	 */
	RGB8;

	/**
	 * 5-bit red, 6-bit green, and 5-bit blue.
	 */
	RGB565;

	/**
	 * 5-bit red, green, and blue with 1-bit alpha.
	 */
	RGB5A1;

	/**
	 * 8-bit red, green, blue, and alpha.
	 */
	RGBA8;

	/**
	 * 8-bit alpha, blue, green, and red.
	 */
	ABGR8;

	/**
	 * 8-bit alpha, red, blue and green
	 */
	ARGB8;

	/**
	 * 8-bit blue, green, red and alpha.
	 */
	BGRA8;

	/**
	 * S3TC compression DXT1.
	 */
	DXT1;

	/**
	 * S3TC compression DXT1 with 1-bit alpha.
	 */
	DXT1A;

	/**
	 * S3TC compression DXT3 with 4-bit alpha.
	 */
	DXT3;

	/**
	 * S3TC compression DXT5 with interpolated 8-bit alpha.
	 *
	 */
	DXT5;

	/**
	 * Arbitrary depth format. The precision is chosen by the video
	 * hardware.
	 */
	Depth;

	/**
	 * 16-bit depth.
	 */
	Depth16;

	/**
	 * 24-bit depth.
	 */
	Depth24;

	/**
	 * 32-bit depth.
	 */
	Depth32;

	/**
	 * single-precision floating point depth.
	 *
	 * Requires {@link Caps#FloatDepthBuffer}.
	 */
	Depth32F;

	/**
	 * Texture data is stored as {@link Format#RGB16F} in system memory,
	 * but will be converted to {@link Format#RGB111110F} when sent
	 * to the video hardware.
	 *
	 * Requires {@link Caps#FloatTexture} and {@link Caps#PackedFloatTexture}.
	 */
	RGB16F_to_RGB111110F;

	/**
	 * unsigned floating-point red, green and blue that uses 32 bits.
	 *
	 * Requires {@link Caps#PackedFloatTexture}.
	 */
	RGB111110F;

	/**
	 * Texture data is stored as {@link Format#RGB16F} in system memory,
	 * but will be converted to {@link Format#RGB9E5} when sent
	 * to the video hardware.
	 *
	 * Requires {@link Caps#FloatTexture} and {@link Caps#SharedExponentTexture}.
	 */
	RGB16F_to_RGB9E5;

	/**
	 * 9-bit red, green and blue with 5-bit exponent.
	 *
	 * Requires {@link Caps#SharedExponentTexture}.
	 */
	RGB9E5;,

	/**
	 * half-precision floating point red, green, and blue.
	 *
	 * Requires {@link Caps#FloatTexture}.
	 */
	RGB16F;

	/**
	 * half-precision floating point red, green, blue, and alpha.
	 *
	 * Requires {@link Caps#FloatTexture}.
	 */
	RGBA16F;

	/**
	 * single-precision floating point red, green, and blue.
	 *
	 * Requires {@link Caps#FloatTexture}.
	 */
	RGB32F;

	/**
	 * single-precision floating point red, green, blue and alpha.
	 *
	 * Requires {@link Caps#FloatTexture}.
	 */
	RGBA32F;

	/**
	 * 24-bit depth with 8-bit stencil.
	 * Check the cap {@link Caps#PackedDepthStencilBuffer}.
	 */
	Depth24Stencil8;

	/**
	 * Ericsson Texture Compression. Typically used on Android.
	 *
	 * Requires {@link Caps#TextureCompressionETC1}.
	 */
	ETC1;
}