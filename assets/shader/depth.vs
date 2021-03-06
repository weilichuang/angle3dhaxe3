attribute vec3 a_Position(POSITION);

#ifdef(DISCARD_ALPHA && COLOR_MAP)
{
	attribute vec2 a_TexCoord(TEXCOORD);
	varying vec2 v_TexCoord;
}

uniform mat4 u_WorldViewProjectionMatrix(WorldViewProjectionMatrix);

#ifdef(NUM_BONES)
{
	attribute vec4 a_boneWeights(BONE_WEIGHTS);
	attribute vec4 a_boneIndices(BONE_INDICES);
	uniform vec4 u_BoneMatrices[NUM_BONES];
}
#elseif(KEYFRAME)
{
	attribute vec3 a_Position1(POSITION1);
	uniform vec2 u_Interpolate;
}

varying vec4 v_Pos;

void function main()
{
	vec4 t_ModelSpacePos.xyz = a_Position;
	t_ModelSpacePos.w = 1.0;
	#ifdef(NUM_BONES)
	{
		skinning_Compute(a_boneIndices,a_boneWeights,u_BoneMatrices,t_ModelSpacePos);
    }
	#elseif(KEYFRAME)
	{
		t_ModelSpacePos.xyz = a_Position.xyz * u_Interpolate.x + a_Position1.xyz * u_Interpolate.y;
	}
	
	vec4 t_Pos = t_ModelSpacePos * u_WorldViewProjectionMatrix;
	output = t_Pos;
	t_Pos /= t_Pos.w;
	//从-1~1转换为0~1
	t_Pos.z *= 0.5;
	t_Pos.z += 0.5;
	v_Pos = t_Pos;

	#ifdef(DISCARD_ALPHA && COLOR_MAP)
	{
		v_TexCoord = a_TexCoord;
	}
}