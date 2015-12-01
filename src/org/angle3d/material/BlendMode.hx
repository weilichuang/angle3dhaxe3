package org.angle3d.material;

/**
 * <code>BlendMode</code> specifies the blending operation to use.
 *
 * @see RenderState#setBlendMode(org.angle3d.material.RenderState.BlendMode)
 */
class BlendMode
{

	/**
	 * No blending mode is used.
	 */
	public static inline var Off:Int = 0;

	/**
	 * Additive blending. For use with glows and particle emitters.
	 * <p>
	 * Result = Source Color + Destination Color
	 */
	public static inline var Additive:Int = 1;

	/**
	 * Premultiplied alpha blending, for use with premult alpha textures.
	 * <p>
	 * Result = Source Color + (Dest Color * (1 - Source Alpha) )
	 */
	public static inline var PremultAlpha:Int = 2;

	/**
	 * Additive blending that is multiplied with source alpha.
	 * For use with glows and particle emitters.
	 * <p>
	 * Result = (Source Alpha * Source Color) + Dest Color
	 */
	public static inline var AlphaAdditive:Int = 3;

	/**
	 * Color blending, blends in color from dest color
	 * using source color.
	 * <p>
	 * Result = Source Color + (1 - Source Color) * Dest Color
	 */
	public static inline var Color:Int = 4;

	/**
	 * Alpha blending, interpolates to source color from dest color
	 * using source alpha.
	 * <p>
	 * Result = Source Alpha * Source Color +
	 *          (1 - Source Alpha) * Dest Color
	 */
	public static inline var Alpha:Int = 5;

	/**
	 * Multiplies the source and dest colors.
	 * <p>
	 * Result = Source Color * Dest Color
	 */
	public static inline var Modulate:Int = 6;

	/**
	 * Multiplies the source and dest colors then doubles the result.
	 * <p>
	 * Result = 2 * Source Color * Dest Color
	 */
	public static inline var ModulateX2:Int = 7;
	
	public static function getBlendModeBy(name:String):Int
	{
		switch(name)
		{
			case "Off":
				return Off;
			case "Additive":
				return Additive;
			case "PremultAlpha":
				return PremultAlpha;
			case "AlphaAdditive":
				return AlphaAdditive;
			case "Color":
				return Color;
			case "Alpha":
				return Alpha;
			case "Modulate":
				return Modulate;
			case "ModulateX2":
				return ModulateX2;
		}
		return -1;
	}

}

