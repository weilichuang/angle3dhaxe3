package org.angle3d.material;


class VarType
{
	public static inline var FLOAT:Int = 0;
	public static inline var INT:Int = 1;
	public static inline var BOOL:Int = 2;

	public static inline var VECTOR2:Int = 3;
	public static inline var VECTOR3:Int = 4;
	public static inline var VECTOR4:Int = 5;
	public static inline var QUATERNION:Int = 6;
	public static inline var COLOR:Int = 7;
	
	public static inline var Vector4Array:Int = 8;

	public static inline var MATRIX3:Int = 9;
	public static inline var MATRIX4:Int = 10;

	public static inline var TEXTURE2D:Int = 11;
	public static inline var TEXTURECUBEMAP:Int = 12;

	public static function isTextureType(type:Int):Bool
	{
		return type == TEXTURE2D || type == TEXTURECUBEMAP;
	}
	
	public static function getVarTypeBy(name:String):Int
	{
		switch(name)
		{
			case "Float":
				return FLOAT;
			case "Int":
				return INT;
			case "Bool":
				return BOOL;
			case "Vector2":
				return VECTOR2;
			case "Vector3":
				return VECTOR3;
			case "Vector4":
				return VECTOR4;
			case "Quaterion":
				return QUATERNION;
			case "Vector4Array":
				return Vector4Array;
			case "Color":
				return COLOR;
			case "Matrix3":
				return MATRIX3;
			case "Matrix4":
				return MATRIX4;
			case "Texture2D":
				return TEXTURE2D;
			case "TextureCubeMap":
				return TEXTURECUBEMAP;
		}
		return -1;
	}
}
