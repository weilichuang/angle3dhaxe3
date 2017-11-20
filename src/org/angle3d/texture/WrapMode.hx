package org.angle3d.texture;

@:enum abstract WrapMode(Int) {
	/**
	 * Only the fractional portion of the coordinate is considered.
	 */
	var Repeat = 0;

	/**
	 * Only the fractional portion of the coordinate is considered, but if
	 * the integer portion is odd, we'll use 1 - the fractional portion.
	 * (Introduced around OpenGL1.4) Falls back on Repeat if not supported.
	 */
	var MirroredRepeat = 1;

	/**
	 * coordinate will be clamped to the range [1/(2N), 1 - 1/(2N)] where N
	 * is the size of the texture in the direction of clamping. Falls back
	 * on Clamp if not supported.
	 */
	var EdgeClamp = 2;

	/**
	 * mirrors and clamps to edge the texture coordinate, where mirroring
	 * and clamping to edge a value f computes:
	 * <code>mirrorClampToEdge(f) = min(1-1/(2*N), max(1/(2*N), abs(f)))</code>
	 * where N is the size of the one-, two-, or three-dimensional texture
	 * image in the direction of wrapping. (Introduced after OpenGL1.4)
	 * Falls back on EdgeClamp if not supported.
	 *
	 * @deprecated Not supported by OpenGL 3
	 */
	var MirrorEdgeClamp = 3;
}