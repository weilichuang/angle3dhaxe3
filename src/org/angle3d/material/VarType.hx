package org.angle3d.material;


class VarType
{
	public static inline var FLOAT:String = "Float";
	//public static inline var INT:String = "Int";
	//public static inline var BOOL:String = "Bool";

	public static inline var VECTOR2:String = "Vector2";
	public static inline var VECTOR3:String = "Vector3";
	public static inline var VECTOR4:String = "Vector4";
	
	public static inline var QUATERNION:String = "Quaternion";
	
	public static inline var COLOR:String = "Color";
	
	public static inline var VECTOR:String = "Vector";

	public static inline var MATRIX3:String = "Matrix3";
	public static inline var MATRIX4:String = "Matrix4";

	public static inline var TEXTURE2D:String = "Texture2D";
	public static inline var TEXTURECUBEMAP:String = "TextureCubeMap";

	public static function isTextureType(type:String):Bool
	{
		return type == TEXTURE2D || type == TEXTURECUBEMAP;
	}
}
