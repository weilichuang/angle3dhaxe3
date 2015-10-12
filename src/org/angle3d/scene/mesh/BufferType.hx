package org.angle3d.scene.mesh;

/**
 * Type of buffer. Specifies the actual attribute it defines.
 */
class BufferType
{
	public static var VERTEX_TYPES:Array<String> = [POSITION, TEXCOORD,
		NORMAL, TANGENT, BINORMAL,
		COLOR,
		BONE_WEIGHTS, BONE_INDICES, 
		BIND_POSE_POSITION,BIND_POSE_TANGENT,BIND_POSE_NORMAL,
		TEXCOORD2, TEXCOORD3, TEXCOORD4,
		POSITION1,NORMAL1,
		PARTICLE_VELOCITY,
		PARTICLE_LIFE_SCALE_ANGLE];

	/**
	 * Position of the vertex (3 floats)
	 */
	public static inline var POSITION:String = "POSITION";

	/**
	 * Texture coordinate
	 */
	public static inline var TEXCOORD:String = "TEXCOORD";

	/**
	 * Normal vector, normalized.
	 */
	public static inline var NORMAL:String = "NORMAL";

	/**
	 * Tangent vector, normalized.
	 */
	public static inline var TANGENT:String = "TANGENT";

	/**
	 * Binormal vector, normalized.
	 */
	public static inline var BINORMAL:String = "BINORMAL";

	/**
	 * Color
	 */
	public static inline var COLOR:String = "COLOR";

	/**
	 * Bone weights, used with animation (4 floats)
	 */
	public static inline var BONE_WEIGHTS:String = "BONE_WEIGHTS";

	/**
	 * Bone indices, used with animation (4 floats)
	 */
	public static inline var BONE_INDICES:String = "BONE_INDICES";

	/**
	 * 只在CPU计算骨骼动画时使用
	 */
	public static inline var BIND_POSE_POSITION:String = "BIND_POSE_POSITION";
	public static inline var BIND_POSE_TANGENT:String = "BIND_POSE_TANGENT";
	public static inline var BIND_POSE_NORMAL:String = "BIND_POSE_NORMAL";

	/**
	 * Texture coordinate #2
	 */
	public static inline var TEXCOORD2:String = "TEXCOORD2";

	/**
	 * Texture coordinate #3
	 */
	public static inline var TEXCOORD3:String = "TEXCOORD3";

	/**
	 * Texture coordinate #4
	 */
	public static inline var TEXCOORD4:String = "TEXCOORD4";

	/**
	 * Position of the vertex (3 floats)
	 * wireframe时使用4个float,最后一个是thickness
	 * keyframe animation时使用3个float
	 */
	public static inline var POSITION1:String = "POSITION1";

	/**
	 * Normal vector, normalized. (3 floats)
	 * keyframe animation
	 */
	public static inline var NORMAL1:String = "NORMAL1";

	/**
	 * particle translate and rotation velocity. (4 floats)
	 * particle 移动速度和旋转速度
	 */
	public static inline var PARTICLE_VELOCITY:String = "PARTICLE_VELOCITY";

	/**
	 * particle Life , Scale and Spin. (4 floats)
	 * particle
	 */
	public static inline var PARTICLE_LIFE_SCALE_ANGLE:String = "PARTICLE_LIFE_SCALE_ANGLE";

	/**
	 * particle acceleration. (3 floats)
	 * particle 加速度
	 */
	public static inline var PARTICLE_ACCELERATION:String = "PARTICLE_ACCELERATION";
}

