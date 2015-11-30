package org.angle3d.scene.mesh;

/**
 * Type of buffer. Specifies the actual attribute it defines.
 */
class BufferType
{
	public static var VERTEX_TYPES:Array<Int> = [POSITION, TEXCOORD,
		NORMAL, TANGENT, BINORMAL,
		COLOR,
		BONE_WEIGHTS, BONE_INDICES, 
		BIND_POSE_POSITION,BIND_POSE_TANGENT,BIND_POSE_NORMAL,
		TEXCOORD2, TEXCOORD3, TEXCOORD4,
		POSITION1,NORMAL1,
		PARTICLE_VELOCITY,
		PARTICLE_LIFE_SCALE_ANGLE];
		
	private static var _typeNames:Array<String> = ["POSITION", "TEXCOORD",
	"NORMAL", "TANGENT",
	"BINORMAL", "COLOR",
	"BONE_WEIGHTS", "BONE_INDICES",
	"BIND_POSE_POSITION", "BIND_POSE_TANGENT",
	"BIND_POSE_NORMAL", "TEXCOORD2",
	"TEXCOORD3", "TEXCOORD4",
	"POSITION1", "NORMAL1",
	"PARTICLE_VELOCITY","PARTICLE_LIFE_SCALE_ANGLE","PARTICLE_ACCELERATION"];
		
	public static function getBufferType(typeName:String):Int
	{
		return _typeNames.indexOf(typeName);
	}
	
	public static function getBufferTypeName(type:Int):String
	{
		return _typeNames[type];
	}

	/**
	 * Position of the vertex (3 floats)
	 */
	public static inline var POSITION:Int = 0;

	/**
	 * Texture coordinate
	 */
	public static inline var TEXCOORD:Int = 1;

	/**
	 * Normal vector, normalized.
	 */
	public static inline var NORMAL:Int = 2;

	/**
	 * Tangent vector, normalized.
	 */
	public static inline var TANGENT:Int = 3;

	/**
	 * Binormal vector, normalized.
	 */
	public static inline var BINORMAL:Int = 4;

	/**
	 * Color
	 */
	public static inline var COLOR:Int = 5;

	/**
	 * Bone weights, used with animation (4 floats)
	 */
	public static inline var BONE_WEIGHTS:Int = 6;

	/**
	 * Bone indices, used with animation (4 floats)
	 */
	public static inline var BONE_INDICES:Int = 7;

	/**
	 * 只在CPU计算骨骼动画时使用
	 */
	public static inline var BIND_POSE_POSITION:Int = 8;
	public static inline var BIND_POSE_TANGENT:Int = 9;
	public static inline var BIND_POSE_NORMAL:Int = 10;

	/**
	 * Texture coordinate #2
	 */
	public static inline var TEXCOORD2:Int = 11;

	/**
	 * Texture coordinate #3
	 */
	public static inline var TEXCOORD3:Int = 12;

	/**
	 * Texture coordinate #4
	 */
	public static inline var TEXCOORD4:Int = 13;

	/**
	 * Position of the vertex (3 floats)
	 * wireframe时使用4个float,最后一个是thickness
	 * keyframe animation时使用3个float
	 */
	public static inline var POSITION1:Int = 14;

	/**
	 * Normal vector, normalized. (3 floats)
	 * keyframe animation
	 */
	public static inline var NORMAL1:Int = 15;

	/**
	 * particle translate and rotation velocity. (4 floats)
	 * particle 移动速度和旋转速度
	 */
	public static inline var PARTICLE_VELOCITY:Int = 16;

	/**
	 * particle Life , Scale and Spin. (4 floats)
	 * particle
	 */
	public static inline var PARTICLE_LIFE_SCALE_ANGLE:Int = 17;

	/**
	 * particle acceleration. (3 floats)
	 * particle 加速度
	 */
	public static inline var PARTICLE_ACCELERATION:Int = 18;
}

