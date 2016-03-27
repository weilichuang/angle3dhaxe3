package org.angle3d.material;

/**
 * <code>BlendMode</code> specifies the blending operation to use.
 *
 * @see RenderState#setBlendMode(org.angle3d.material.RenderState.BlendMode)
 */
@:enum abstract BlendMode(Int)   
{

	/**
	 * No blending mode is used.
	 */
	var Off = 0;

	/**
	 * Additive blending. For use with glows and particle emitters.
	 * <p>
	 * Result = Source Color + Destination Color
	 */
	var Additive = 1;

	/**
	 * Premultiplied alpha blending, for use with premult alpha textures.
	 * <p>
	 * Result = Source Color + (Dest Color * (1 - Source Alpha) )
	 */
	var PremultAlpha = 2;

	/**
	 * Additive blending that is multiplied with source alpha.
	 * For use with glows and particle emitters.
	 * <p>
	 * Result = (Source Alpha * Source Color) + Dest Color
	 */
	var AlphaAdditive = 3;

	/**
	 * Color blending, blends in color from dest color
	 * using source color.
	 * <p>
	 * Result = Source Color + (1 - Source Color) * Dest Color
	 */
	var COLOR = 4;

	/**
	 * Alpha blending, interpolates to source color from dest color
	 * using source alpha.
	 * <p>
	 * Result = Source Alpha * Source Color +
	 *          (1 - Source Alpha) * Dest Color
	 */
	var Alpha = 5;

	/**
	 * Multiplies the source and dest colors.
	 * <p>
	 * Result = Source Color * Dest Color
	 */
	var Modulate = 6;

	/**
	 * Multiplies the source and dest colors then doubles the result.
	 * <p>
	 * Result = 2 * Source Color * Dest Color
	 */
	var ModulateX2 = 7;
	
	public static function getBlendModeBy(name:String):BlendMode
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
				return COLOR;
			case "Alpha":
				return Alpha;
			case "Modulate":
				return Modulate;
			case "ModulateX2":
				return ModulateX2;
			default:
				return Off;
		}
	}

}

