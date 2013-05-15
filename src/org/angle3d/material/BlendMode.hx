package org.angle3d.material;

/**
 * <code>BlendMode</code> specifies the blending operation to use.
 *
 * @see RenderState#setBlendMode(org.angle3d.material.RenderState.BlendMode)
 */
enum BlendMode
{

	/**
	 * No blending mode is used.
	 */
	Off;

	/**
	 * Additive blending. For use with glows and particle emitters.
	 * <p>
	 * Result = Source Color + Destination Color
	 */
	Additive;

	/**
	 * Premultiplied alpha blending, for use with premult alpha textures.
	 * <p>
	 * Result = Source Color + (Dest Color * (1 - Source Alpha) )
	 */
	PremultAlpha;

	/**
	 * Additive blending that is multiplied with source alpha.
	 * For use with glows and particle emitters.
	 * <p>
	 * Result = (Source Alpha * Source Color) + Dest Color
	 */
	AlphaAdditive;

	/**
	 * Color blending, blends in color from dest color
	 * using source color.
	 * <p>
	 * Result = Source Color + (1 - Source Color) * Dest Color
	 */
	Color;

	/**
	 * Alpha blending, interpolates to source color from dest color
	 * using source alpha.
	 * <p>
	 * Result = Source Alpha * Source Color +
	 *          (1 - Source Alpha) * Dest Color
	 */
	Alpha;

	/**
	 * Multiplies the source and dest colors.
	 * <p>
	 * Result = Source Color * Dest Color
	 */
	Modulate;

	/**
	 * Multiplies the source and dest colors then doubles the result.
	 * <p>
	 * Result = 2 * Source Color * Dest Color
	 */
	ModulateX2;

}

