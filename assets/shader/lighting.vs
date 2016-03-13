//MultiPass Lighting
attribute vec3 a_Position(POSITION);
attribute vec2 a_TexCoord(TEXCOORD);
attribute vec3 a_Normal(NORMAL);

uniform mat4 u_WorldViewProjectionMatrix(WorldViewProjectionMatrix);
uniform mat4 u_WorldViewMatrix(WorldViewMatrix);
uniform mat3 u_NormalMatrix(NormalMatrix);
uniform mat4 u_ViewMatrix(ViewMatrix);

#ifdef(MATERIAL_COLORS)
{
	uniform vec4 u_Ambient;
	uniform vec4 u_Diffuse;
	uniform vec4 u_Specular;
}

uniform vec4 gu_LightColor;
uniform vec4 gu_LightPosition;
uniform vec4 gu_AmbientLightColor;

varying vec4 v_TexCoord;
#ifdef(SEPARATE_TEXCOORD)
{
  attribute vec2 a_TexCoord2(TEXCOORD2);
}

varying vec3 v_AmbientSum;
varying vec4 v_DiffuseSum;
varying vec3 v_SpecularSum;

#ifdef(VERTEX_COLOR)
{
  attribute vec4 a_Color(COLOR);
}

#ifdef(VERTEX_LIGHTING)
{
  varying vec4 v_VertexLightValues;
  uniform vec4 gu_LightDirection;
  uniform vec4 u_Shininess;
} 
#else 
{
	varying vec3 v_LightVec;
	varying vec4 v_ViewDir;
	varying vec4 v_LightDir;
	
    #ifdef(NORMALMAP)
    {
		attribute vec4 a_Tangent(TANGENT);
		uniform mat3 u_TbnMat;
    }
	#else
	{
		varying vec3 v_Normal;
	}
}

#ifdef(NUM_BONES)
{
	attribute vec4 a_boneWeights(BONE_WEIGHTS);
	attribute vec4 a_boneIndices(BONE_INDICES);
	uniform vec4 u_BoneMatrices[NUM_BONES];
}
#elseif(KEYFRAME)
{
	attribute vec3 a_Position1(POSITION1);
	//attribute vec3 a_Normal1(NORMAL);
	uniform vec2 u_Interpolate;
}

#ifdef(USE_REFLECTION)
{
    uniform vec3 u_CameraPosition(CameraPosition);
    uniform mat4 u_WorldMatrix(WorldMatrix);

    uniform vec3 u_FresnelParams;
    varying vec4 v_RefVec;
}

void function main()
{
    vec4 t_ModelSpacePos.xyz = a_Position;
	t_ModelSpacePos.w = 1.0;

    vec3 t_ModelSpaceNorm = a_Normal;
   
    #ifndef(VERTEX_LIGHTING)
	{
		#ifdef(NORMALMAP)
		{
			vec3 t_ModelSpaceTan = a_Tangent.xyz;
		}
    }

    #ifdef(NUM_BONES)
	{
        #ifndef(VERTEX_LIGHTING)
		{
			#ifdef(NORMALMAP)
			{
				skinning_Compute(a_boneIndices,a_boneWeights,u_BoneMatrices,t_ModelSpacePos, t_ModelSpaceNorm, t_ModelSpaceTan);
			}
			#else
			{
				skinning_Compute(a_boneIndices,a_boneWeights,u_BoneMatrices,t_ModelSpacePos, t_ModelSpaceNorm);
			}
		}
        #else
		{
			skinning_Compute(a_boneIndices,a_boneWeights,u_BoneMatrices,t_ModelSpacePos, t_ModelSpaceNorm);
        }
    }
	#elseif(KEYFRAME)
	{
		t_ModelSpacePos.xyz = a_Position.xyz * u_Interpolate.x + a_Position1.xyz * u_Interpolate.y;
		//t_ModelSpaceNorm.xyz = a_Normal.xyz * u_Interpolate.x + a_Normal1.xyz * u_Interpolate.y;
	}
	
    output = t_ModelSpacePos * u_WorldViewProjectionMatrix;
	
    v_TexCoord = a_TexCoord;
    #ifdef(SEPARATE_TEXCOORD)
	{
        v_TexCoord.zw = a_TexCoord2;
    }
	
    vec3 t_WvPosition = (t_ModelSpacePos * u_WorldViewMatrix).xyz;
    vec3 t_WvNormal  = t_ModelSpaceNorm * u_NormalMatrix;
	t_WvNormal = normalize(t_WvNormal);
	
  
	vec4 t_LightColor = gu_LightColor;
	//t_LightColor.w -- lightType 0--directional,1--point,2--spotlight
	//t_WvLightPos对于方向光来说，这里算出的是方向，点光源和聚光灯算出的是位置
	vec4 t_WvLightPos.xyz = gu_LightPosition.xyz;
	t_WvLightPos.w = saturate(t_LightColor.w);
    t_WvLightPos *= u_ViewMatrix;
	//gu_LightPosition.w -- invRadius
    t_WvLightPos.w = gu_LightPosition.w;
    
    #ifndef(VERTEX_LIGHTING)
	{
		#ifdef(NORMALMAP)
		{
			vec3 t_WvTangent = normalize(t_ModelSpaceTan * u_NormalMatrix);
			vec3 t_WvBinormal = crossProduct(t_WvNormal.xyz, t_WvTangent);
			
			//TODO need test function Mat3 
			//mat3 t_TbnMat = Mat3(t_WvTangent, t_WvBinormal * a_Tangent.w,t_WvNormal.xyz);
			//mat3 t_TbnMat;
			//t_TbnMat[0].xyz = t_WvTangent;
			//t_TbnMat[1].xyz = t_WvBinormal * a_Tangent.w;
			//t_TbnMat[2].xyz = t_WvNormal.xyz;
			
			//使用一个uniform，这样就不会报错
			mat3 t_TbnMat = u_TbnMat;
			t_TbnMat[0].xyz = t_WvTangent;
			t_TbnMat[1].xyz = t_WvBinormal * a_Tangent.w;
			t_TbnMat[2].xyz = t_WvNormal.xyz;
			
			vec3 t_ViewDir.xyz = -m33(t_WvPosition,t_TbnMat);
			v_ViewDir = t_ViewDir;
			
			vec4 t_LightDir;
			vec3 t_LightVec;
			lightComputeDir(t_WvPosition, t_LightColor.w, t_WvLightPos, t_LightDir, t_LightVec);
			v_LightDir.xyz = (t_LightDir.xyz * t_TbnMat).xyz;
			v_LightDir.w = t_LightDir.w;
			
			v_LightVec = t_LightVec;
		}
		#else 
		{
			v_Normal = t_WvNormal;

			vec3 t_ViewDir = -t_WvPosition;
			t_ViewDir = normalize(t_ViewDir);
			v_ViewDir = t_ViewDir;
			
			vec3 t_LightVec;
			vec4 t_LightDir;
			lightComputeDir(t_WvPosition, t_LightColor.w, t_WvLightPos, t_LightDir, t_LightVec);
			v_LightDir = t_LightDir;
			v_LightVec = t_LightVec;
		}
    }

	vec3 t_AmbientSum;
	vec4 t_DiffuseSum;
    #ifdef(MATERIAL_COLORS)
	{
		t_AmbientSum  = u_Ambient.rgb;
		t_AmbientSum *= gu_AmbientLightColor.rgb;
        t_DiffuseSum.rgb  =  u_Diffuse.rgb * t_LightColor.rgb;
		t_DiffuseSum.a = u_Diffuse.a;
        v_SpecularSum = u_Specular.rgb * t_LightColor.rgb;
    } 
	#else
	{
	    // Default: ambient color is dark gray
        t_AmbientSum      = gu_AmbientLightColor.rgb; 
        t_DiffuseSum.rgb  = t_LightColor.rgb;
		t_DiffuseSum.a    = 1.0;
        v_SpecularSum     = 0.0;
    }

    #ifdef(VERTEX_COLOR)
	{
        t_AmbientSum *= a_Color.rgb;
        t_DiffuseSum *= a_Color;
    }
	
	v_AmbientSum = t_AmbientSum;
	v_DiffuseSum = t_DiffuseSum;

    #ifdef(VERTEX_LIGHTING)
	{
		vec4 t_LightDir;
		vec3 t_LightVec;
		lightComputeDir(t_WvPosition, t_LightColor.w, t_WvLightPos, t_LightDir, t_LightVec);
		
		vec4 t_LightDirection = gu_LightDirection;
		float t_SpotFallOff = computeSpotFalloff(t_LightDirection, t_LightVec);
		//判断是否是聚光灯, t_LightColor.w == 2 时才是聚光灯
		float t_IsSpotLight = sne(t_LightColor.w,2.0); //聚光灯时:0,非聚光灯时:1
		t_SpotFallOff = add(t_SpotFallOff,t_IsSpotLight);//聚光灯时:+0,非聚光灯时:+1
		t_SpotFallOff = min(t_SpotFallOff,1.0);//大于1时为1
		
		vec3 t_ViewDir = -t_WvPosition;
		t_ViewDir = normalize(t_ViewDir);
		
		float t_shininess = u_Shininess.x;
		vec2 t_Light;
        computeLighting(t_WvNormal.xyz, t_ViewDir, t_LightDir.xyz, t_LightDir.w * t_SpotFallOff, t_shininess, t_Light);
		v_VertexLightValues = t_Light.xy;
    }

    #ifdef(USE_REFLECTION)
	{
        vec3 t_WorldPos = (t_ModelSpacePos * u_WorldMatrix).xyz;

        vec3 t_I = normalize( u_CameraPosition - t_WorldPos  );
		
		vec4 t_Normal.xyz = a_Normal;
		t_Normal.w = 0.0;
        vec3 t_N = normalize(t_Normal * u_WorldMatrix);

        v_RefVec.xyz = reflect(t_I, t_N);
        v_RefVec.w   = u_FresnelParams.x + u_FresnelParams.y * pow(1.0 + dot3(t_I, t_N), u_FresnelParams.z);
    } 
}