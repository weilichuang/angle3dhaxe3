attribute vec3 a_Position(POSITION);

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

uniform mat4 u_WorldMatrix(WorldMatrix);
uniform mat4 u_WorldViewProjectionMatrix(WorldViewProjectionMatrix);

uniform mat4 u_LightViewProjectionMatrix;
uniform mat4 u_BiasMat;

varying vec4 v_ProjCoord;

void function main()
{
    vec4 t_ModelSpacePos = a_Position;
	//t_ModelSpacePos.w = 1.0;
	#ifdef(NUM_BONES)
	{
		skinning_Compute(a_boneIndices,a_boneWeights,u_BoneMatrices,t_ModelSpacePos);
    }
	#elseif(KEYFRAME)
	{
		t_ModelSpacePos.xyz = a_Position.xyz * u_Interpolate.x + a_Position1.xyz * u_Interpolate.y;
	}
	
	output = t_ModelSpacePos * u_WorldViewProjectionMatrix;
	
	// Project the vertex from the light's point of view
	vec4 t_WorldPos = t_ModelSpacePos * u_WorldMatrix;
	vec4 t_Coord = t_WorldPos * u_LightViewProjectionMatrix;
	v_ProjCoord = t_Coord * u_BiasMat;
}