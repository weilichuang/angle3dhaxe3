package org.angle3d.scene.control;


/**
 * Determines how the billboard is aligned to the screen/camera.
 */
enum Alignment
{

	/**
	 * Aligns this Billboard to the screen.
	 */
	Screen;

	/**
	 * Aligns this Billboard to the camera position.
	 */
	Camera;

	/**
	 * Aligns this Billboard to the screen, but keeps the Y axis fixed.
	 */
	AxialY;

	/**
	 * Aligns this Billboard to the screen, but keeps the Z axis fixed.
	 */
	AxialZ;

}

