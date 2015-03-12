attribute vec3 a_Position(POSITION);

#ifdef(DIFFUSEMAP)
{
   attribute vec2 a_TexCoord(TEXCOORD);
   varying vec4 v_TexCoord;
   
   #ifdef(LIGHTMAP && SeparateTexCoord)
	{
	   attribute vec2 a_TexCoord2(TEXCOORD2);
	}
}

#ifdef(VERTEX_COLOR){
	attribute vec4 a_Color(COLOR);
}

#ifdef(MATERIAL_COLORS){
	uniform vec4 u_MaterialColor;
}

#ifdef(VERTEX_COLOR || MATERIAL_COLORS){
	varying vec4 v_Color;
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
	
	output = t_ModelSpacePos * u_WorldViewProjectionMatrix;
	
	#ifdef(DIFFUSEMAP)
	{
	   v_TexCoord = a_TexCoord.xy;
	   
	    #ifdef(LIGHTMAP && SeparateTexCoord)
		{
		   v_TexCoord.zw = a_TexCoord2.xy;
		}
	}
	
	#ifdef(VERTEX_COLOR && MATERIAL_COLORS)
	{
		v_Color = a_Color * u_MaterialColor;
	}
	#elseif(VERTEX_COLOR)
	{
		v_Color = a_Color;
	}
	#elseif(MATERIAL_COLORS)
	{
		v_Color = u_MaterialColor;
	}
}