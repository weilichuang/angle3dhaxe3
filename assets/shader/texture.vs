attribute vec3 a_position(POSITION);
attribute vec2 a_texCoord(TEXCOORD);

varying vec4 v_texCoord;

#ifdef(lightmap && useTexCoord2)
{
   attribute vec2 a_texCoord2(TEXCOORD2);
   varying vec4 v_texCoord2;
}

uniform mat4 u_WorldViewProjectionMatrix(WorldViewProjectionMatrix);

#ifdef(USE_KEYFRAME)
{
   attribute vec3 a_position1(POSITION1);
   uniform vec4 u_influences;
} 
#elseif(USE_SKINNING)
{
	attribute vec4 a_boneWeights(BONE_WEIGHTS);
	attribute vec4 a_boneIndices(BONE_INDICES);
	uniform vec4 u_boneMatrixs[{0}];
}

void function main()
{
	#ifdef(USE_KEYFRAME)
	{
		vec4 morphed;
		morphed.xyz = a_position*u_influences.x + a_position1 * u_influences.y;
		morphed.w = 1.0;
		output = m44(morphed,u_WorldViewProjectionMatrix);
	}
	#elseif(USE_SKINNING)
	{
		mat34 t_skinTransform;
		vec4 t_vec; 		
		vec4 t_vec1;
		vec4 t_boneIndexVec = mul(a_boneIndices,3);

		//计算最终蒙皮矩阵
		t_vec1 = mul(a_boneWeights.x,u_boneMatrixs[t_boneIndexVec.x]);
		t_vec  = mul(a_boneWeights.y,u_boneMatrixs[t_boneIndexVec.y]);
		t_vec1 = add(t_vec1,t_vec);
		t_vec  = mul(a_boneWeights.z,u_boneMatrixs[t_boneIndexVec.z]);
		t_vec1 = add(t_vec1,t_vec);
		t_vec  = mul(a_boneWeights.w,u_boneMatrixs[t_boneIndexVec.w]);
		t_skinTransform[0] = add(t_vec1,t_vec);

		t_vec1 = mul(a_boneWeights.x,u_boneMatrixs[t_boneIndexVec.x + 1]);
		t_vec  = mul(a_boneWeights.y,u_boneMatrixs[t_boneIndexVec.y + 1]);
		t_vec1 = add(t_vec1,t_vec);
		t_vec  = mul(a_boneWeights.z,u_boneMatrixs[t_boneIndexVec.z + 1]);
		t_vec1 = add(t_vec1,t_vec);
		t_vec  = mul(a_boneWeights.w,u_boneMatrixs[t_boneIndexVec.w + 1]);
		t_skinTransform[1] = add(t_vec1,t_vec);

		t_vec1 = mul(a_boneWeights.x,u_boneMatrixs[t_boneIndexVec.x + 2]);
		t_vec  = mul(a_boneWeights.y,u_boneMatrixs[t_boneIndexVec.y + 2]);
		t_vec1 = add(t_vec1,t_vec);
		t_vec  = mul(a_boneWeights.z,u_boneMatrixs[t_boneIndexVec.z + 2]);
		t_vec1 = add(t_vec1,t_vec);
		t_vec  = mul(a_boneWeights.w,u_boneMatrixs[t_boneIndexVec.w + 2]);
		t_skinTransform[2] = add(t_vec1,t_vec);

		vec4 t_localPos;
		t_localPos.xyz = m34(a_position,t_skinTransform);
		t_localPos.w = 1.0;
		output = m44(t_localPos,u_WorldViewProjectionMatrix);
	}
	#else
	{
		output = m44(a_position,u_WorldViewProjectionMatrix);
	}
	v_texCoord = a_texCoord;
	#ifdef( lightmap && useTexCoord2)
	{
		v_texCoord2 = a_texCoord2;
	}
}