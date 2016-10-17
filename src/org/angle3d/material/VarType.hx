package org.angle3d.material;

@:enum abstract VarType(Int)
{
	var NONE = -1;
	var FLOAT = 0;
	var INT = 1;
	var BOOL = 2;

	var VECTOR2 = 3;
	var VECTOR3 = 4;
	var VECTOR4 = 5;
	var QUATERNION = 6;
	var COLOR = 7;
	
	var Vector4Array = 8;

	var MATRIX3 = 9;
	var MATRIX4 = 10;

	var TEXTURE2D = 11;
	var TEXTURECUBEMAP = 12;
	
	inline function new(v:Int)
        this = v;

    inline function toInt():Int
    	return this;
	
	inline public static function isTextureType(type:VarType):Bool
	{
		return type == TEXTURE2D || type == TEXTURECUBEMAP;
	}
	
	inline public static function getVarTypeBy(name:String):VarType
	{
		switch(name)
		{
			case "Float":
				return FLOAT;
			case "Int":
				return INT;
			case "Bool","Boolean":
				return BOOL;
			case "Vector2","Vec2":
				return VECTOR2;
			case "Vector3","Vec3":
				return VECTOR3;
			case "Vector4","Vec4":
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
			default:
				return NONE;
		}
	}
}
