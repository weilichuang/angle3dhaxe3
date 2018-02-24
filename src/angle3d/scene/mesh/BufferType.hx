package angle3d.scene.mesh;

/**
 * Type of buffer. Specifies the actual attribute it defines.
 */
enum BufferType {
	/**
	 * Position of the vertex (3 floats)
	 */
	POSITION;

	/**
	 * Texture coordinate
	 */
	TEXCOORD;

	/**
	 * Normal vector, normalized.
	 */
	NORMAL;

	/**
	 * Tangent vector, normalized.
	 */
	TANGENT;

	/**
	 * Binormal vector, normalized.
	 */
	BINORMAL;

	/**
	 * Color
	 */
	COLOR;

	/**
	 * Bone weights, used with animation (4 floats)
	 */
	BONE_WEIGHTS;

	/**
	 * Bone indices, used with animation (4 floats)
	 */
	BONE_INDICES;

	/**
	 * 只在CPU计算骨骼动画时使用
	 */
	BIND_POSE_POSITION;
	BIND_POSE_TANGENT;
	BIND_POSE_NORMAL;

	/**
	 * Texture coordinate #2
	 */
	TEXCOORD2;

	/**
	 * Texture coordinate #3
	 */
	TEXCOORD3;

	/**
	 * Texture coordinate #4
	 */
	TEXCOORD4;

	/**
	 * Position of the vertex (3 floats)
	 * wireframe时使用4个float,最后一个是thickness
	 * keyframe animation时使用3个float
	 */
	POSITION1;

	/**
	 * Normal vector, normalized. (3 floats)
	 * keyframe animation
	 */
	NORMAL1;

	/**
	 * particle translate and rotation velocity. (4 floats)
	 * particle 移动速度和旋转速度
	 */
	PARTICLE_VELOCITY;

	/**
	 * particle Life , Scale and Spin. (4 floats)
	 * particle
	 */
	PARTICLE_LIFE_SCALE_ANGLE;

	/**
	 * particle acceleration. (3 floats)
	 * particle 加速度
	 */
	PARTICLE_ACCELERATION;
}

