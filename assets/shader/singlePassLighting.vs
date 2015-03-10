//SinglePass Lighting
attribute vec3 a_Position(POSITION);
attribute vec2 a_TexCoord(TEXCOORD);
attribute vec3 a_Normal(NORMAL);

#ifdef(VERTEX_COLOR)
{
  attribute vec4 a_Color(COLOR);
}

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

uniform vec4 gu_AmbientLightColor;

varying vec2 v_TexCoord;
#ifdef(SEPARATE_TEXCOORD)
{
  varying vec2 v_TexCoord2;
  attribute vec2 a_TexCoord2(TEXCOORD2);
}

varying vec3 v_AmbientSum;
varying vec4 v_Pos;
#ifdef(VERTEX_LIGHTING)
{
	uniform vec4 gu_LightData[NB_LIGHTS];
	uniform vec4 u_Shininess;
	varying vec4 v_SpecularAccum;
    varying vec4 v_DiffuseAccum;
} 
#else 
{
	varying vec4 v_DiffuseSum;
	varying vec3 v_SpecularSum;
	varying vec3 v_Normal;
	
    #ifdef(NORMALMAP)
    {
		attribute vec4 a_Tangent(TANGENT);
		varying vec3 v_Tangent;
		varying vec3 v_Binormal;
    }
}

#ifdef(USE_REFLECTION)
{
    uniform vec3 u_CameraPosition(CameraPosition);
    uniform mat4 u_WorldMatrix(WorldMatrix);

    uniform vec3 u_FresnelParams;
    varying vec4 v_RefVec;
}

#ifdef(VERTEX_LIGHTING)
{
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
	
	/*
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
  
    #ifndef(VERTEX_LIGHTING)
	{
		#ifdef(NORMALMAP)
		{
			v_Tangent = normalize(t_ModelSpaceTan * u_NormalMatrix);
			v_Binormal = crossProduct(t_WvNormal, t_WvTangent);	
		}
		v_Normal = t_WvNormal;
    }
	v_Pos = t_WvPosition;

	vec3 t_AmbientSum;
	vec4 t_DiffuseSum;
    #ifdef(MATERIAL_COLORS)
	{
		t_AmbientSum  = u_Ambient.rgb;
		t_AmbientSum  = t_AmbientSum * gu_AmbientLightColor.rgb;
		
		#ifndef(VERTEX_LIGHTING)
		{
			t_DiffuseSum  =  u_Diffuse;
			v_SpecularSum = u_Specular.rgb;
		}
    } 
	#else
	{
        t_AmbientSum = gu_AmbientLightColor.rgb; 
		#ifndef(VERTEX_LIGHTING)
		{
			t_DiffuseSum.rgb  = 1.0;
			t_DiffuseSum.a = 0.0;
			v_SpecularSum     = 0.0;
		}
    }

    #ifdef(VERTEX_COLOR)
	{
        t_AmbientSum = t_AmbientSum * a_Color.rgb;
		#ifndef(VERTEX_LIGHTING)
		{
			t_DiffuseSum = t_DiffuseSum * a_Color;
		} 
    }
	
	v_AmbientSum = t_AmbientSum;
	#ifndef(VERTEX_LIGHTING)
	{
		v_DiffuseSum = t_DiffuseSum;
	}
	
    #ifdef(VERTEX_LIGHTING)
	{
		vec4 t_DiffuseAccum = 0.0;
		vec3 t_SpecularAccum = 0.0;
		
		float t_shininess = u_Shininess.x;
		vec4 t_DiffuseColor;
		vec3 t_SpecularColor;

		//----------------light1------------------//
		vec4 t_LightColor = gu_LightData[0];            
		vec4 t_LightData = gu_LightData[1];            

		#ifdef(MATERIAL_COLORS)
		{
			t_DiffuseColor.rgb  = u_Diffuse.rgb * t_LightColor.rgb;
			t_DiffuseColor.a = 1.0;
			t_SpecularColor.rgb = u_Specular.rgb * t_LightColor.rgb;
		}
		#else
		{
			t_DiffuseColor.rgb  = t_LightColor.rgb;
			t_DiffuseColor.a = 1.0;
			t_SpecularColor.rgb = 0.0;
		}

		vec4 t_LightDir;
		vec3 t_LightVec;
		lightComputeDir(t_WvPosition, t_LightColor.w, t_LightData, t_LightDir, t_LightVec);
		
		float t_SpotFallOff = 1.0;
		if(t_LightColor.w > 1.0)
		{
			vec4 t_LightDirection = gu_LightData[2];
			t_SpotFallOff = computeSpotFalloff(t_LightDirection, t_LightVec);
		}

		vec2 t_Light;
        computeLighting(t_WvNormal, t_ViewDir, t_LightDir.xyz, t_LightDir.w * t_SpotFallOff, t_shininess,t_Light);

		#ifdef(COLORRAMP)
		{
			vec2 t_UV;
			t_UV.x = t_Light.x;
			t_UV.y = 0.0;
			t_DiffuseAccum.rgb  = t_DiffuseAccum.rgb  + texture2D(m_ColorRamp, t_UV).rgb * t_DiffuseColor.rgb;
			
			t_UV.x = t_Light.y;
			t_SpecularAccum.rgb = t_SpecularAccum.rgb + texture2D(m_ColorRamp, t_UV).rgb * t_SpecularColor.rgb;
		}
		#else
		{
			t_DiffuseAccum.rgb  = t_DiffuseAccum.rgb  + t_DiffuseColor.rgb  * t_Light.x;
			t_SpecularAccum.rgb = t_SpecularAccum.rgb + t_SpecularColor.rgb * t_Light.y;
		}
		
		//----------------light2------------------//
		#ifdef(SINGLE_PASS_LIGHTING1)
		{
			vec4 t_LightColor2 = gu_LightData[3];            
			vec4 t_LightData2 = gu_LightData[4];            

			#ifdef(MATERIAL_COLORS)
			{
				t_DiffuseColor.rgb  = u_Diffuse.rgb * t_LightColor2.rgb;
				t_DiffuseColor.a = 1.0;
				t_SpecularColor.rgb = u_Specular.rgb * t_LightColor2.rgb;
			}
			#else
			{
				t_DiffuseColor.rgb  = t_LightColor2.rgb;
				t_DiffuseColor.a = 1.0;
				t_SpecularColor.rgb = 0.0;
			}

			vec4 t_LightDir2;
			vec3 t_LightVec2;
			lightComputeDir(t_WvPosition, t_LightColor2.w, t_LightData2, t_LightDir2, t_LightVec2);
			
			float t_SpotFallOff2 = 1.0;
			if(t_SpotFallOff2.w > 1.0)
			{
				vec4 t_LightDirection2 = gu_LightData[5];
				t_SpotFallOff2 = computeSpotFalloff(t_LightDirection2, t_LightVec2);
			}

			vec2 t_Light2;
			computeLighting(t_WvNormal, t_ViewDir, t_LightDir2.xyz, t_LightDir2.w * t_SpotFallOff2, t_shininess, t_Light2);

			#ifdef(COLORRAMP)
			{
				vec2 t_UV2;
				t_UV2.x = t_Light2.x;
				t_UV2.y = 0.0;
				t_DiffuseAccum.rgb  = t_DiffuseAccum.rgb  + texture2D(m_ColorRamp, t_UV2).rgb * t_DiffuseColor.rgb;
				
				t_UV2.x = t_Light2.y;
				t_SpecularAccum.rgb = t_SpecularAccum.rgb + texture2D(m_ColorRamp, t_UV2).rgb * t_SpecularColor.rgb;
			}
			#else
			{
				t_DiffuseAccum.rgb  = t_DiffuseAccum.rgb  + t_DiffuseColor.rgb  * t_Light2.x;
				t_SpecularAccum.rgb = t_SpecularAccum.rgb + t_SpecularColor.rgb * t_Light2.y;
			}
		}
		
		//----------------light3------------------//
		#ifdef(SINGLE_PASS_LIGHTING2)
		{
			vec4 t_LightColor3 = gu_LightData[6];            
			vec4 t_LightData3 = gu_LightData[7];            

			#ifdef(MATERIAL_COLORS)
			{
				t_DiffuseColor.rgb  = u_Diffuse.rgb * t_LightColor3.rgb;
				t_DiffuseColor.a = 1.0;
				t_SpecularColor.rgb = u_Specular.rgb * t_LightColor3.rgb;
			}
			#else
			{
				t_DiffuseColor.rgb  = t_LightColor3.rgb;
				t_DiffuseColor.a = 1.0;
				t_SpecularColor.rgb = 0.0;
			}

			vec4 t_LightDir3;
			vec3 t_LightVec3;
			lightComputeDir(t_WvPosition, t_LightColor3.w, t_LightData3, t_LightDir3, t_LightVec3);
			
			float t_SpotFallOff3 = 1.0;
			if(t_SpotFallOff3.w > 1.0)
			{
				vec4 t_LightDirection3 = gu_LightData[8];
				t_SpotFallOff3 = computeSpotFalloff(t_LightDirection3, t_LightVec3);
			}

			vec2 t_Light3;
			computeLighting(t_WvNormal, t_ViewDir, t_LightDir3.xyz, t_LightDir3.w * t_SpotFallOff3, t_shininess, t_Light3);

			#ifdef(COLORRAMP)
			{
				vec2 t_UV3;
				t_UV3.x = t_Light3.x;
				t_UV3.y = 0.0;
				t_DiffuseAccum.rgb  = t_DiffuseAccum.rgb  + texture2D(m_ColorRamp, t_UV3).rgb * t_DiffuseColor.rgb;
				
				t_UV3.x = t_Light3.y;
				t_SpecularAccum.rgb = t_SpecularAccum.rgb + texture2D(m_ColorRamp, t_UV3).rgb * t_SpecularColor.rgb;
			}
			#else
			{
				t_DiffuseAccum.rgb  = t_DiffuseAccum.rgb  + t_DiffuseColor.rgb  * t_Light3.x;
				t_SpecularAccum.rgb = t_SpecularAccum.rgb + t_SpecularColor.rgb * t_Light3.y;
			}
		}
		
		//----------------light4------------------//
		#ifdef(SINGLE_PASS_LIGHTING3)
		{
			vec4 t_LightColor4 = gu_LightData[9];            
			vec4 t_LightData4 = gu_LightData[10];            

			#ifdef(MATERIAL_COLORS)
			{
				t_DiffuseColor.rgb  = u_Diffuse.rgb * t_LightColor4.rgb;
				t_DiffuseColor.a = 1.0;
				t_SpecularColor.rgb = u_Specular.rgb * t_LightColor4.rgb;
			}
			#else
			{
				t_DiffuseColor.rgb  = t_LightColor4.rgb;
				t_DiffuseColor.a = 1.0;
				t_SpecularColor.rgb = 0.0;
			}

			vec4 t_LightDir4;
			vec3 t_LightVec4;
			lightComputeDir(t_WvPosition, t_LightColor4.w, t_LightData4, t_LightDir4, t_LightVec4);
			
			float t_SpotFallOff4 = 1.0;
			if(t_SpotFallOff4.w > 1.0)
			{
				vec4 t_LightDirection4 = gu_LightData[11];
				t_SpotFallOff4 = computeSpotFalloff(t_LightDirection4, t_LightVec4);
			}

			vec2 t_Light4;
			computeLighting(t_WvNormal, t_ViewDir, t_LightDir4.xyz, t_LightDir4.w * t_SpotFallOff4, t_shininess, t_Light4);

			#ifdef(COLORRAMP)
			{
				vec2 t_UV4;
				t_UV4.x = t_Light4.x;
				t_UV4.y = 0.0;
				t_DiffuseAccum.rgb  = t_DiffuseAccum.rgb  + texture2D(m_ColorRamp, t_UV4).rgb * t_DiffuseColor.rgb;
				
				t_UV4.x = t_Light4.y;
				t_SpecularAccum.rgb = t_SpecularAccum.rgb + texture2D(m_ColorRamp, t_UV4).rgb * t_SpecularColor.rgb;
			}
			#else
			{
				t_DiffuseAccum.rgb  = t_DiffuseAccum.rgb  + t_DiffuseColor.rgb  * t_Light4.x;
				t_SpecularAccum.rgb = t_SpecularAccum.rgb + t_SpecularColor.rgb * t_Light4.y;
			}
		}
		
		//result
		v_DiffuseAccum = t_DiffuseAccum;
		v_SpecularAccum.rgb = t_SpecularAccum;
		v_SpecularAccum.a = 1.0;
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