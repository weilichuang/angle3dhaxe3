package org.angle3d.material.shader;

enum UniformBinding
{

	/**
	 * The world matrix. Converts Model space to World space.
	 * Type: mat4
	 */
	WorldMatrix;

	/**
	 * The view matrix. Converts World space to View space.
	 * Type: mat4
	 */
	ViewMatrix;

	/**
	 * The projection matrix. Converts View space to Clip/Projection space.
	 * Type: mat4
	 */
	ProjectionMatrix;

	/**
	 * The world view matrix. Converts Model space to View space.
	 * Type: mat4
	 */
	WorldViewMatrix;

	/**
	 * The normal matrix. The inverse transpose of the worldview matrix.
	 * Converts normals from model space to view space.
	 * Type: mat3
	 */
	NormalMatrix;

	/**
	 * The world view projection matrix. Converts Model space to Clip/Projection space.
	 * Type: mat4
	 */
	WorldViewProjectionMatrix;

	/**
	 * The view projection matrix. Converts Model space to Clip/Projection space.
	 * Type: mat4
	 */
	ViewProjectionMatrix;


	WorldMatrixInverse;
	ViewMatrixInverse;
	ProjectionMatrixInverse;
	ViewProjectionMatrixInverse;
	WorldViewMatrixInverse;
	NormalMatrixInverse;
	WorldViewProjectionMatrixInverse;

	/**
	 * Camera position in world space.
	 * Type: vec4
	 */
	CameraPosition;

	/**
	 * Direction of the camera.
	 * Type: vec4
	 */
	CameraDirection;

	/**
	 * ViewPort of the camera.
	 * Type: vec4
	 */
	ViewPort;
}

