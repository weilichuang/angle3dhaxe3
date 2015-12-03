package org.angle3d.material.shader;

class UniformBinding
{

	/**
	 * The world matrix. Converts Model space to World space.
	 * Type: mat4
	 */
	public static inline var WorldMatrix:Int = 0;

	/**
	 * The view matrix. Converts World space to View space.
	 * Type: mat4
	 */
	public static inline var ViewMatrix:Int = 1;

	/**
	 * The projection matrix. Converts View space to Clip/Projection space.
	 * Type: mat4
	 */
	public static inline var ProjectionMatrix:Int = 2;

	/**
	 * The world view matrix. Converts Model space to View space.
	 * Type: mat4
	 */
	public static inline var WorldViewMatrix:Int = 3;

	/**
	 * The normal matrix. The inverse transpose of the worldview matrix.
	 * Converts normals from model space to view space.
	 * Type: mat3
	 */
	public static inline var NormalMatrix:Int = 4;

	/**
	 * The world view projection matrix. Converts Model space to Clip/Projection space.
	 * Type: mat4
	 */
	public static inline var WorldViewProjectionMatrix:Int = 5;

	/**
	 * The view projection matrix. Converts Model space to Clip/Projection space.
	 * Type: mat4
	 */
	public static inline var ViewProjectionMatrix:Int = 6;


	public static inline var WorldMatrixInverse:Int = 7;
	public static inline var ViewMatrixInverse:Int = 8;
	public static inline var ProjectionMatrixInverse:Int = 9;
	public static inline var ViewProjectionMatrixInverse:Int = 10;
	public static inline var WorldViewMatrixInverse:Int = 11;
	public static inline var NormalMatrixInverse:Int = 12;
	public static inline var WorldViewProjectionMatrixInverse:Int = 13;

	/**
	 * Camera position in world space.
	 * Type: vec4
	 */
	public static inline var CameraPosition:Int = 14;

	/**
	 * Direction of the camera.
	 * Type: vec4
	 */
	public static inline var CameraDirection:Int = 15;

	/**
	 * ViewPort of the camera.
	 * Type: vec4
	 */
	public static inline var ViewPort:Int = 16;
	
	/**
	 * near far of the camera.
	 * Type: vec4
	 */
	public static inline var NearFar:Int = 17;
	
	public static function getUniformBindingBy(name:String):Int
	{
		switch(name)
		{
			case "WorldMatrix":
				return WorldMatrix;
			case "ViewMatrix":
				return ViewMatrix;
			case "ProjectionMatrix":
				return ProjectionMatrix;
			case "WorldViewMatrix":
				return WorldViewMatrix;
			case "NormalMatrix":
				return NormalMatrix;
			case "WorldViewProjectionMatrix":
				return WorldViewProjectionMatrix;
			case "ViewProjectionMatrix":
				return ViewProjectionMatrix;
			case "WorldMatrixInverse":
				return WorldMatrixInverse;
			case "ViewMatrixInverse":
				return ViewMatrixInverse;
			case "ProjectionMatrixInverse":
				return ProjectionMatrixInverse;
			case "ViewProjectionMatrixInverse":
				return ViewProjectionMatrixInverse;
			case "WorldViewMatrixInverse":
				return WorldViewMatrixInverse;
			case "NormalMatrixInverse":
				return NormalMatrixInverse;
			case "WorldViewProjectionMatrixInverse":
				return WorldViewProjectionMatrixInverse;
			case "CameraPosition":
				return CameraPosition;
			case "CameraDirection":
				return CameraDirection;
			case "ViewPort":
				return ViewPort;
			case "NearFar":
				return NearFar;
		}
		return -1;
	}
	
	public static function getUniformBindingNameBy(type:Int):String
	{
		switch(type)
		{
			case WorldMatrix:
				return "WorldMatrix";
			case ViewMatrix:
				return "ViewMatrix";
			case ProjectionMatrix:
				return "ProjectionMatrix";
			case WorldViewMatrix:
				return "WorldViewMatrix";
			case NormalMatrix:
				return "NormalMatrix";
			case WorldViewProjectionMatrix:
				return "WorldViewProjectionMatrix";
			case ViewProjectionMatrix:
				return "ViewProjectionMatrix";
			case WorldMatrixInverse:
				return "WorldMatrixInverse";
			case ViewMatrixInverse:
				return "ViewMatrixInverse";
			case ProjectionMatrixInverse:
				return "ProjectionMatrixInverse";
			case ViewProjectionMatrixInverse:
				return "ViewProjectionMatrixInverse";
			case WorldViewMatrixInverse:
				return "WorldViewMatrixInverse";
			case NormalMatrixInverse:
				return "NormalMatrixInverse";
			case WorldViewProjectionMatrixInverse:
				return "WorldViewProjectionMatrixInverse";
			case CameraPosition:
				return "CameraPosition";
			case CameraDirection:
				return "CameraDirection";
			case ViewPort:
				return "ViewPort";
			case NearFar:
				return "NearFar";
		}
		return "";
	}
}

