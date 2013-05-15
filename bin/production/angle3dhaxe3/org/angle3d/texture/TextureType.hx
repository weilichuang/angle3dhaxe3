package org.angle3d.texture;

enum TextureType
{
	/**
	 * Two dimensional texture (default). A rectangle.
	 */
	TwoDimensional;

	/**
	 * Three dimensional texture. (A cube)
	 */
	ThreeDimensional;

	/**
	 * A set_of 6 TwoDimensional textures arranged as faces of a cube facing
	 * inwards.
	 */
	CubeMap;
}

