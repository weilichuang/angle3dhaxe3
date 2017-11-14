package org.angle3d.material.shader;

@:enum abstract UniformBinding(Int)   
{
	/**
	 * The world matrix. Converts Model space to World space.
	 * Type: mat4
	 */
	var WorldMatrix = 0;

	/**
	 * The view matrix. Converts World space to View space.
	 * Type: mat4
	 */
	var ViewMatrix = 1;

	/**
	 * The projection matrix. Converts View space to Clip/Projection space.
	 * Type: mat4
	 */
	var ProjectionMatrix = 2;

	/**
	 * The world view matrix. Converts Model space to View space.
	 * Type: mat4
	 */
	var WorldViewMatrix = 3;

	/**
	 * The normal matrix. The inverse transpose of the worldview matrix.
	 * Converts normals from model space to view space.
	 * Type: mat3
	 */
	var NormalMatrix = 4;

	/**
	 * The world view projection matrix. Converts Model space to Clip/Projection space.
	 * Type: mat4
	 */
	var WorldViewProjectionMatrix = 5;

	/**
	 * The view projection matrix. Converts Model space to Clip/Projection space.
	 * Type: mat4
	 */
	var ViewProjectionMatrix = 6;


	var WorldMatrixInverse = 7;
	var ViewMatrixInverse = 8;
	var ProjectionMatrixInverse = 9;
	var ViewProjectionMatrixInverse = 10;
	var WorldViewMatrixInverse = 11;
	var NormalMatrixInverse = 12;
	var WorldViewProjectionMatrixInverse = 13;

	/**
	 * Camera position in world space.
	 * Type: vec4
	 */
	var CameraPosition = 14;

	/**
	 * Direction of the camera.
	 * Type: vec4
	 */
	var CameraDirection = 15;

	/**
	 * ViewPort of the camera.
	 * Type: vec4
	 */
	var ViewPort = 16;
	
	/**
	 * near far of the camera.
	 * Type: vec4
	 */
	var NearFar = 17;

	inline function new(v:Int)
        this = v;

    public inline function toInt():Int
    	return this;
}

