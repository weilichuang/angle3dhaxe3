package org.angle3d.texture;

@:enum abstract TextureType(Int) {
	/**
	 * Two dimensional texture (default). A rectangle.
	 */
	var TwoDimensional = 0;

	/**
	 * A set_of 6 TwoDimensional textures arranged as faces of a cube facing
	 * inwards.
	 */
	var CubeMap = 1;

	/**
	 * Three dimensional texture.
	 */
	//var ThreeDimensional = 2;
}

