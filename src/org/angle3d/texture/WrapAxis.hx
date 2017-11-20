package org.angle3d.texture;

/**
 * ...
 * @author
 */
@:enum abstract WrapAxis(Int) {
	/**
	 * S wrapping (u or "horizontal" wrap)
	 */
	var S = 0;
	/**
	 * T wrapping (v or "vertical" wrap)
	 */
	var T = 1;
	/**
	 * R wrapping (w or "depth" wrap)
	 */
	var R = 2;
}