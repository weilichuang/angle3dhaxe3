package org.angle3d.scene.control;

/**
 * The type of control.
 *
 */
@:enum abstract ControlType(Int) {
	/**
	 * Manages the level of detail for the model.
	 */
	var LevelOfDetail = 0;

	/**
	 * Provides methods to manipulate the skeleton and bones.
	 */
	var BoneControl = 1;

	/**
	 * Handles the bone animation and skeleton updates.
	 */
	var BoneAnimation = 2;

	/**
	 * Handles attachments to bones
	 */
	var Attachment = 3;

	/**
	 * Handles vertex/morph animation.
	 */
	var VertexAnimation = 4;

	/**
	 * Handles poses or morph keys.
	 */
	var Pose = 5;

	/**
	 * Handles particle updates
	 */
	var Particle = 6;
}

