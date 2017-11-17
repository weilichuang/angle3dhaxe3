package org.angle3d.shader;

@:enum abstract VarType(Int)
{
	var FLOAT = 1;
	var INT = 2;
	var BOOL = 3;

	var Vector2 = 4;
	var Vector3 = 5;
	var Vector4 = 6;
	
	var IntArray = 7;
	var FloatArray = 8;
	var Vector2Array = 9;
	var Vector3Array = 10;
	var Vector4Array = 11;
	
	var Matrix3 = 12;
	var Matrix4 = 13;
	
	var Matrix3Array = 14;
	var Matrix4Array = 15;

	var TEXTURE2D = 16;
	var Texture3D = 17;
	var TextureArray = 18;
	var TextureCubeMap = 19;
	
	inline function new(v:Int)
        this = v;

    inline function toInt():Int
    	return this;
}
