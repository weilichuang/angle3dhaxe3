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

varying vec2 v_TexCoord;
#ifdef(SEPARATE_TEXCOORD)
{
  varying vec2 v_TexCoord2;
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
	
	//放到sgsl.lib中，目前放到那里会报错，需要修改
	void function skinning_Compute(vec4 boneIndices,vec4 boneWeights,vec4 boneMatrixs,vec4 position){
		mat34 t_skinTransform;
		
		//为什么要乘以3？
		vec4 t_boneIndexVec = mul(boneIndices,3);

		t_skinTransform[0]  = boneMatrixs[t_boneIndexVec.x] * boneWeights.x;
		t_skinTransform[0]  = t_skinTransform[0] + boneMatrixs[t_boneIndexVec.y] * boneWeights.y;
		t_skinTransform[0]  = t_skinTransform[0] + boneMatrixs[t_boneIndexVec.z] * boneWeights.z;
		t_skinTransform[0]  = t_skinTransform[0] + boneMatrixs[t_boneIndexVec.w] * boneWeights.w;

		t_skinTransform[1]  = boneMatrixs[t_boneIndexVec.x + 1] * boneWeights.x;
		t_skinTransform[1]  = t_skinTransform[1] + boneMatrixs[t_boneIndexVec.y + 1] * boneWeights.y;
		t_skinTransform[1]  = t_skinTransform[1] + boneMatrixs[t_boneIndexVec.z + 1] * boneWeights.z;
		t_skinTransform[1]  = t_skinTransform[1] + boneMatrixs[t_boneIndexVec.w + 1] * boneWeights.w;

		t_skinTransform[2]  = boneMatrixs[t_boneIndexVec.x + 2] * boneWeights.x;
		t_skinTransform[2]  = t_skinTransform[2] + boneMatrixs[t_boneIndexVec.y + 2] * boneWeights.y;
		t_skinTransform[2]  = t_skinTransform[2] + boneMatrixs[t_boneIndexVec.z + 2] * boneWeights.z;
		t_skinTransform[2]  = t_skinTransform[2] + boneMatrixs[t_boneIndexVec.w + 2] * boneWeights.w;
		
		position.xyz = m34(position,t_skinTransform);
	}
	 
	void function skinning_Compute(vec4 boneIndices,vec4 boneWeights,vec4 boneMatrixs,vec4 position, vec3 normal){
		mat34 t_skinTransform;
		
		//为什么要乘以3？
		vec4 t_boneIndexVec = mul(boneIndices,3);

		t_skinTransform[0]  = boneMatrixs[t_boneIndexVec.x] * boneWeights.x;
		t_skinTransform[0]  = t_skinTransform[0] + boneMatrixs[t_boneIndexVec.y] * boneWeights.y;
		t_skinTransform[0]  = t_skinTransform[0] + boneMatrixs[t_boneIndexVec.z] * boneWeights.z;
		t_skinTransform[0]  = t_skinTransform[0] + boneMatrixs[t_boneIndexVec.w] * boneWeights.w;

		t_skinTransform[1]  = boneMatrixs[t_boneIndexVec.x + 1] * boneWeights.x;
		t_skinTransform[1]  = t_skinTransform[1] + boneMatrixs[t_boneIndexVec.y + 1] * boneWeights.y;
		t_skinTransform[1]  = t_skinTransform[1] + boneMatrixs[t_boneIndexVec.z + 1] * boneWeights.z;
		t_skinTransform[1]  = t_skinTransform[1] + boneMatrixs[t_boneIndexVec.w + 1] * boneWeights.w;

		t_skinTransform[2]  = boneMatrixs[t_boneIndexVec.x + 2] * boneWeights.x;
		t_skinTransform[2]  = t_skinTransform[2] + boneMatrixs[t_boneIndexVec.y + 2] * boneWeights.y;
		t_skinTransform[2]  = t_skinTransform[2] + boneMatrixs[t_boneIndexVec.z + 2] * boneWeights.z;
		t_skinTransform[2]  = t_skinTransform[2] + boneMatrixs[t_boneIndexVec.w + 2] * boneWeights.w;
		
		position.xyz = m34(position,t_skinTransform);
		normal.xyz = m33(normal.xyz,t_skinTransform);
	}
	 
	void function skinning_Compute(vec4 boneIndices,vec4 boneWeights,vec4 boneMatrixs,vec4 position, vec3 normal, vec3 tangent){
		mat34 t_skinTransform;
		
		//为什么要乘以3？
		vec4 t_boneIndexVec = mul(boneIndices,3);

		t_skinTransform[0]  = boneMatrixs[t_boneIndexVec.x] * boneWeights.x;
		t_skinTransform[0]  = t_skinTransform[0] + boneMatrixs[t_boneIndexVec.y] * boneWeights.y;
		t_skinTransform[0]  = t_skinTransform[0] + boneMatrixs[t_boneIndexVec.z] * boneWeights.z;
		t_skinTransform[0]  = t_skinTransform[0] + boneMatrixs[t_boneIndexVec.w] * boneWeights.w;

		t_skinTransform[1]  = boneMatrixs[t_boneIndexVec.x + 1] * boneWeights.x;
		t_skinTransform[1]  = t_skinTransform[1] + boneMatrixs[t_boneIndexVec.y + 1] * boneWeights.y;
		t_skinTransform[1]  = t_skinTransform[1] + boneMatrixs[t_boneIndexVec.z + 1] * boneWeights.z;
		t_skinTransform[1]  = t_skinTransform[1] + boneMatrixs[t_boneIndexVec.w + 1] * boneWeights.w;

		t_skinTransform[2]  = boneMatrixs[t_boneIndexVec.x + 2] * boneWeights.x;
		t_skinTransform[2]  = t_skinTransform[2] + boneMatrixs[t_boneIndexVec.y + 2] * boneWeights.y;
		t_skinTransform[2]  = t_skinTransform[2] + boneMatrixs[t_boneIndexVec.z + 2] * boneWeights.z;
		t_skinTransform[2]  = t_skinTransform[2] + boneMatrixs[t_boneIndexVec.w + 2] * boneWeights.w;
		
		position.xyz = m34(position,t_skinTransform);
		normal.xyz = m33(normal.xyz,t_skinTransform);
		tangent.xyz = m33(tangent.xyz,t_skinTransform);
	}
}

#ifdef(USE_REFLECTION)
{
    uniform vec3 u_CameraPosition(CameraPosition);
    uniform mat4 u_WorldMatrix(WorldMatrix);

    uniform vec3 u_FresnelParams;
    varying vec4 v_RefVec;
}

/*
* Computes light direction 
* @param worldPos 
* @param lightType
* @param lightPosition
* @param lightDir
* @param lightVec
* lightType should be 0.0,1.0,2.0, repectively for Directional, point and spot lights.
* Outputs the light direction and the light half vector. 
*/
void function lightComputeDir(vec3 worldPos, float lightType, vec4 lightPosition, vec4 lightDir, vec3 lightVec)
{
	float t_PosLight = saturate(lightType);
	vec3 t_TempVec = lightPosition.xyz * sign(t_PosLight - 0.5) - (worldPos * t_PosLight);
	lightVec = t_TempVec;  
	
	float t_Dist = length(t_TempVec);
	#ifdef(SRGB)
	{
		lightDir.w = (1.0 - position.w * t_Dist) / (1.0 + lightPosition.w * t_Dist * t_Dist);
		lightDir.w = clamp(lightDir.w, 1.0 - t_PosLight, 1.0);
	} 
	#else 
	{
		lightDir.w = saturate(1.0 - lightPosition.w * t_Dist * t_PosLight);
	}
	lightDir.xyz = t_TempVec / t_Dist;
}

#ifdef(VERTEX_LIGHTING)
{
	/*
	* @param lightDirection 前三位是方向，最后一位是InnerAngleCos和OuterAngleCos结合起来的数字，需要分解开
	* Computes the spot falloff for a spotlight
	*/
	float function computeSpotFalloff(vec4 lightDirection, vec3 lightVector){
		vec3 t_L = normalize(lightVector);
		vec3 t_Spotdir = normalize(lightDirection.xyz);
		float t_CurAngleCos = dot3(-t_L, t_Spotdir);
		
		float t_OuterAngleCos = fract(lightDirection.w);
		float t_InnerAngleCos = lightDirection.w - t_OuterAngleCos;
		t_InnerAngleCos = t_InnerAngleCos * 0.001;
		
		float t_InnerMinusOuter = t_InnerAngleCos - t_OuterAngleCos;
		
		float t_Value = (t_CurAngleCos - t_OuterAngleCos) / t_InnerMinusOuter;
		return clamp(t_Value, step(lightDirection.w, 0.001), 1.0);
	}

	/*
	* Computes diffuse factor (Lambert)
	*/
	//float function lightComputeDiffuse(vec3 norm, vec3 lightdir){
		//return max(0.0, dot3(norm, lightdir));
	//}

	/*
	* Computes specular factor   (blinn phong) 
	*/
	//float function lightComputeSpecular(vec3 norm, vec3 viewdir, vec3 lightdir, float shiny)
	//{
		//vec3 H = normalize(viewdir + lightdir);
		//float HdotN = max(0.0, dot3(H, norm));
		//return pow(HdotN, shiny);
	//}

	/*
	* Computes diffuse and specular factors and pack them in a vec2 (x=diffuse, y=specular)
	*/
	void function computeLighting(vec3 norm, vec3 viewDir, vec3 lightDir, float attenuation, float shininess,vec2 result)
	{
		//float diffuseFactor = lightComputeDiffuse(norm,lightDir);
	    //float specularFactor = lightComputeSpecular(norm, viewDir, lightDir, shininess); 
		
	    //Computes diffuse factor (Lambert)
	    float diffuseFactor = max(0.0, dot3(norm, lightDir));
	    
		//Computes specular factor   (blinn phong) 
	    vec3 H = normalize(viewDir + lightDir);
	    float HdotN = max(0.0, dot3(H, norm));
	    float specularFactor = pow(HdotN, shininess);
	   
	    //小于等于1时忽略specular
	    specularFactor = step(1.0, shininess) * specularFactor;
	   
	    result.x = diffuseFactor * attenuation;
	    result.y = specularFactor * diffuseFactor * attenuation;
	}
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
	
    output = t_ModelSpacePos * u_WorldViewProjectionMatrix;
	
    v_TexCoord = a_TexCoord;
    #ifdef(SEPARATE_TEXCOORD)
	{
      v_TexCoord2 = a_TexCoord2;
    }
	
    vec3 t_WvPosition = (t_ModelSpacePos * u_WorldViewMatrix).xyz;
    vec3 t_WvNormal  = normalize((t_ModelSpaceNorm * u_NormalMatrix).xyz);
    vec3 t_ViewDir = normalize(-t_WvPosition);
  
	vec4 t_LightColor = gu_LightColor;
	//t_LightColor.w -- lightType 0--directional,1--point,2--spotlight
	//t_WvLightPos对于方向光来说，这里算出的是方向，点光源和聚光灯算出的是位置
	vec4 t_WvLightPos.xyz = gu_LightPosition.xyz;
	t_WvLightPos.w = saturate(t_LightColor.w);
    t_WvLightPos = t_WvLightPos * u_ViewMatrix;
	//gu_LightPosition.w -- invRadius
    t_WvLightPos.w = gu_LightPosition.w;
    
    #ifndef(VERTEX_LIGHTING)
	{
		#ifdef(NORMALMAP)
		{
			vec3 t_WvTangent = normalize(t_ModelSpaceTan * u_NormalMatrix);
			vec3 t_WvBinormal = crossProduct(t_WvNormal, t_WvTangent);
			//TODO need test function Mat3 
			mat3 t_TbnMat = Mat3(t_WvTangent, t_WvBinormal * a_Tangent.w,t_WvNormal);
			 
			v_ViewDir  = -t_WvPosition * t_TbnMat;
			vec4 t_LightDir;
			lightComputeDir(t_WvPosition, t_LightColor.w, t_WvLightPos, t_LightDir, v_LightVec);
			v_LightDir.xyz = (t_LightDir.xyz * t_TbnMat).xyz;
			v_LightDir.w = t_LightDir.w;
		}
		#else 
		{
			v_Normal = t_WvNormal;
			v_ViewDir = t_ViewDir;
			lightComputeDir(t_WvPosition, t_LightColor.w, t_WvLightPos, v_LightDir, v_LightVec);
		}
    }

	vec3 t_AmbientSum;
	vec4 t_DiffuseSum;
    #ifdef(MATERIAL_COLORS)
	{
		t_AmbientSum  = u_Ambient.rgb;
		t_AmbientSum  = t_AmbientSum * gu_AmbientLightColor.rgb;
        t_DiffuseSum.rgb  =  u_Diffuse.rgb * t_LightColor.rgb;
		t_DiffuseSum.a = u_Diffuse.a;
        v_SpecularSum = (u_Specular * t_LightColor).rgb;
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
        t_AmbientSum = t_AmbientSum * a_Color.rgb;
        t_DiffuseSum = t_DiffuseSum * a_Color;
    }
	
	v_AmbientSum = t_AmbientSum;
	v_DiffuseSum = t_DiffuseSum;

    #ifdef(VERTEX_LIGHTING)
	{
		vec4 t_LightDir;
		vec3 t_LightVec;
		lightComputeDir(t_WvPosition, t_LightColor.w, t_WvLightPos, t_LightDir, t_LightVec);
		
		//TODO try replace condition
		float t_SpotFallOff = 1.0;
		if(t_LightColor.w > 1.0)
		{
			vec4 t_LightDirection = gu_LightDirection;
			t_SpotFallOff = computeSpotFalloff(t_LightDirection, t_LightVec);
		}
		
		float t_shininess = u_Shininess.x;
		vec2 t_Light;
        computeLighting(t_WvNormal, t_ViewDir, t_LightDir.xyz, t_LightDir.w * t_SpotFallOff, t_shininess,t_Light);
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