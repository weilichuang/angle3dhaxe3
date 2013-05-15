package org.angle3d.scene.mesh;

/**
 * Type of buffer. Specifies the actual attribute it defines.
 */
class BufferType
{
	public static var VERTEX_TYPES:Array<String> = [POSITION, TEXCOORD,
		NORMAL, TANGENT, BINORMAL,
		COLOR,
		BONE_WEIGHTS, BONE_INDICES, BIND_POSE_POSITION,
		TEXCOORD2, TEXCOORD3, TEXCOORD4,
		POSITION1,
		NORMAL1,
		PARTICLE_VELOCITY,
		PARTICLE_LIFE_SCALE_ANGLE];

	/**
	 * Position of the vertex (3 floats)
	 */
	public static inline var POSITION:String = "position";

	/**
	 * Texture coordinate
	 */
	public static inline var TEXCOORD:String = "texCoord";

	/**
	 * Normal vector, normalized.
	 */
	public static inline var NORMAL:String = "normal";

	/**
	 * Tangent vector, normalized.
	 */
	public static inline var TANGENT:String = "tangent";

	/**
	 * Binormal vector, normalized.
	 */
	public static inline var BINORMAL:String = "binormal";

	/**
	 * Color
	 */
	public static inline var COLOR:String = "color";

	/**
	 * Bone weights, used with animation (4 floats)
	 */
	public static inline var BONE_WEIGHTS:String = "boneWeights";

	/**
	 * Bone indices, used with animation (4 floats)
	 */
	public static inline var BONE_INDICES:String = "boneIndices";

	/**
	 * 只在CPU计算骨骼动画时使用
	 */
	public static inline var BIND_POSE_POSITION:String = "bindPosPosition";

	/**
	 * Texture coordinate #2
	 */
	public static inline var TEXCOORD2:String = "texCoord2";

	/**
	 * Texture coordinate #3
	 */
	public static inline var TEXCOORD3:String = "texCoord3";

	/**
	 * Texture coordinate #4
	 */
	public static inline var TEXCOORD4:String = "texCoord4";

	/**
	 * Position of the vertex (3 floats)
	 * wireframe时使用4个float,最后一个是thickness
	 * keyframe animation时使用3个float
	 */
	public static inline var POSITION1:String = "position1";

	/**
	 * Normal vector, normalized. (3 floats)
	 * keyframe animation
	 */
	public static inline var NORMAL1:String = "normal1";

	/**
	 * particle translate and rotation velocity. (4 floats)
	 * particle 移动速度和旋转速度
	 */
	public static inline var PARTICLE_VELOCITY:String = "particle_velocity";

	/**
	 * particle Life , Scale and Spin. (4 floats)
	 * particle
	 */
	public static inline var PARTICLE_LIFE_SCALE_ANGLE:String = "particle_life_scale_angle";

	/**
	 * particle acceleration. (3 floats)
	 * particle 加速度
	 */
	public static inline var PARTICLE_ACCELERATION:String = "particle_acceleration";
}

