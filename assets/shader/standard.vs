attribute vec3 a_position(POSITION);
attribute vec2 a_texCoord(TEXCOORD);
attribute vec3 a_normal(NORMAL);

varying vec4 v_texCoord;

uniform mat4 u_WorldViewProjectionMatrix(WorldViewProjectionMatrix);

#ifdef(REFLECTION)
{
	varying vec4 v_Reflect;
}

#ifdef(REFLECTION || REFRACTION)
{
	uniform mat4 u_worldMatrix(WorldMatrix);
	uniform vec4 u_camPosition(CameraPosition);
}

#ifdef(REFRACTION)
{
	uniform vec4 u_etaRatio;
	varying vec4 v_Refract;
}

#ifdef(lightmap && useTexCoord2)
{
   attribute vec2 a_texCoord2(TEXCOORD2);
   varying vec4 v_texCoord2;
}

#ifdef(USE_KEYFRAME)
{
   attribute vec3 a_position1(POSITION1);
   attribute vec3 a_normal1(NORMAL1);
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
	vec4 t_position;
	#ifdef(USE_KEYFRAME)
	{
		t_position.xyz = a_position * u_influences.x + a_position1 * u_influences.y;
		t_position.w = 1.0;
		output = m44(t_position,u_WorldViewProjectionMatrix);
		
		vec3 normalMorphed0 = mul(a_normal,u_influences.x);
		vec3 normalMorphed1 = mul(a_normal1,u_influences.y);
		vec3 t_normal = add(normalMorphed0,normalMorphed1);
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

		t_position.xyz = m34(a_position,t_skinTransform);
		t_position.w = 1.0;
		output = m44(t_position,u_WorldViewProjectionMatrix);
		
		vec3 t_normal = a_normal;
	}
	#else
	{
		t_position.xyz = a_position;
		t_position.w = 1.0;
		
		output = m44(t_position,u_WorldViewProjectionMatrix);
		
		vec3 t_normal = a_normal;
	}
	
	v_texCoord = a_texCoord;
	
	#ifdef(REFLECTION)
	{
		vec3 t_N = m33(t_normal.xyz,u_worldMatrix);
		t_N = normalize(t_N);

		vec4 t_positionW = m44(t_position,u_worldMatrix);
		vec3 t_I = sub(t_positionW.xyz,u_camPosition.xyz);
		v_Reflect = reflect(t_I,t_N);
	}
	
	#ifdef(REFRACTION)
	{
		vec3 t_N = m33(t_normal.xyz,u_worldMatrix);
		t_N = normalize(t_N);

		vec4 t_positionW = m44(t_position,u_worldMatrix);
		vec3 t_I = sub(t_positionW.xyz,u_camPosition.xyz);
		t_I = normalize(t_I);

		v_Refract = refract(t_I,t_N,u_etaRatio.xyz);
	}
	
	#ifdef( lightmap && useTexCoord2)
	{
		v_texCoord2 = a_texCoord2;
	}
}