package org.angle3d.material.sgsl;

import de.polygonal.ds.error.Assert;
import org.angle3d.utils.FastStringMap;

class DataType
{
	public static inline var VOID:String = "void";
	public static inline var FLOAT:String = "float";
	public static inline var VEC2:String = "vec2";
	public static inline var VEC3:String = "vec3";
	public static inline var VEC4:String = "vec4";
	public static inline var MAT3:String = "mat3";
	public static inline var MAT34:String = "mat34";
	public static inline var MAT4:String = "mat4";

	public static inline var SAMPLER2D:String = "sampler2D";
	public static inline var SAMPLERCUBE:String = "samplerCube";
	public static inline var SAMPLER3D:String = "sampler3D";

	public static var sizeDic:FastStringMap<Int>;
	
	/**
	 * 特殊函数，用于执行一些static变量的定义等(有这个函数时，static变量预先赋值必须也放到这里面)
	 */
	public static function __init__():Void
	{
		sizeDic = new FastStringMap<Int>();
		sizeDic.set(FLOAT, 1);
		sizeDic.set(VEC2, 2);
		sizeDic.set(VEC3, 3);
		sizeDic.set(VEC4, 4);
		sizeDic.set(MAT3, 12);
		sizeDic.set(MAT34, 12);
		sizeDic.set(MAT4, 16);
		sizeDic.set(SAMPLER2D, 0);
		sizeDic.set(SAMPLERCUBE, 0);
		sizeDic.set(SAMPLER3D, 0);
	}

	/**
	 *
	 * @param dataType
	 * @return
	 *
	 */
	public static function isSampler(dataType:String):Bool
	{
		return dataType == SAMPLER2D || dataType == SAMPLERCUBE || dataType == SAMPLERCUBE;
	}

	/**
	 * 类型是否是矩阵
	 * @param	type
	 * @return
	 */
	public static function isMat(dataType:String):Bool
	{
		return dataType == MAT3 || dataType == MAT34 || dataType == MAT4;
	}

	/**
	 * 需要偏移
	 * @param	type
	 * @return
	 */
	public static function isNeedOffset(dataType:String):Bool
	{
		return dataType == FLOAT || dataType == VEC2 || dataType == VEC3;
	}

	public static function getSize(dataType:String):Int
	{
		#if debug
		Assert.assert(sizeDic.exists(dataType), dataType + "是未知类型");
		#end
		return sizeDic.get(dataType);
	}

	/**
	 * 获取其占用寄存器数量
	 * @param	varType
	 * @return
	 */
	public static function getRegisterCount(dataType:String):Int
	{
		switch (dataType)
		{
			case DataType.MAT3:
				return 3;
			case DataType.MAT34:
				return 3;
			case DataType.MAT4:
				return 4;
			default:
				return 1;
		}
	}
}

