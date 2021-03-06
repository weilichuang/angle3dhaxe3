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

varying vec4 v_TexCoord;
#ifdef(SEPARATE_TEXCOORD)
{
    attribute vec2 a_TexCoord2(TEXCOORD2);
}

varying vec3 v_AmbientSum;
varying vec4 v_DiffuseSum;
varying vec3 v_SpecularSum;

#ifdef(VERTEX_LIGHTING)
{
	uniform vec4 gu_LightData[NB_LIGHTS];
	uniform vec4 u_Shininess;//TODO 为什么类型改为float时，效果会出错，需要找原因
} 
#else 
{
	varying vec3 v_Normal;
	varying vec3 v_Pos;
	
    #ifdef(NORMALMAP)
    {
		attribute vec4 a_Tangent(TANGENT);
		varying vec3 v_Tangent;
		varying vec3 v_Binormal;
    }
}

#ifdef(USE_REFLECTION)
{
	uniform vec3 u_FresnelParams;
    uniform vec3 u_CameraPosition(CameraPosition);
    uniform mat4 u_WorldMatrix(WorldMatrix);
    varying vec4 v_RefVec;
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
	
    #ifdef(SEPARATE_TEXCOORD)
	{
		vec4 t_TexCoord = a_TexCoord;
		t_TexCoord.zw = a_TexCoord2;
		v_TexCoord = t_TexCoord;
    }
	#else
	{
		v_TexCoord = a_TexCoord;
	}
	
    vec3 t_WvPosition = (t_ModelSpacePos * u_WorldViewMatrix).xyz;
    vec3 t_WvNormal  = normalize((t_ModelSpaceNorm * u_NormalMatrix).xyz);
    vec3 t_ViewDir = normalize(-t_WvPosition);
  
    #ifndef(VERTEX_LIGHTING)
	{
		#ifdef(NORMALMAP)
		{
			vec3 t_TmpVec = normalize(t_ModelSpaceTan * u_NormalMatrix);
			v_Tangent = t_TmpVec;
			t_TmpVec = crossProduct(t_WvNormal, t_TmpVec);
			t_TmpVec *= a_Tangent.w;
			v_Binormal = t_TmpVec;
		}
		v_Normal = t_WvNormal;
		v_Pos = t_WvPosition;
    }

	vec3 t_AmbientSum;
	vec4 t_DiffuseSum;
	vec3 t_SpecularSum;
    #ifdef(MATERIAL_COLORS)
	{
		//不能这样写，flash会报错，提示uniform不能相乘，应该在外部计算
		//t_AmbientSum  = u_Ambient.rgb * gu_AmbientLightColor.rgb;
		t_AmbientSum  = u_Ambient.rgb;
		t_AmbientSum *= gu_AmbientLightColor.rgb;
		t_DiffuseSum  = u_Diffuse;
		t_SpecularSum = u_Specular.rgb;
    } 
	#else
	{
		// Defaults: Ambient and diffuse are white, specular is black.
        t_AmbientSum  = gu_AmbientLightColor.rgb; 
		t_DiffuseSum  = 1.0;
		t_SpecularSum = 0.0;
    }

    #ifdef(VERTEX_COLOR)
	{
        t_AmbientSum *= a_Color.rgb;
		t_DiffuseSum *= a_Color;
    }
	
	v_AmbientSum = t_AmbientSum;
	
	
    #ifdef(VERTEX_LIGHTING)
	{
		//----------------light1------------------//
		vec4 t_LightColor = gu_LightData[0];            
		vec4 t_LightData = gu_LightData[1];      
		
		vec3 t_DiffuseColor;
		vec3 t_SpecularColor;

		#ifdef(MATERIAL_COLORS)
		{
			t_DiffuseColor.rgb  = u_Diffuse.rgb * t_LightColor.rgb;
			t_SpecularColor.rgb = u_Specular.rgb * t_LightColor.rgb;
		}
		#else
		{
			t_DiffuseColor.rgb  = t_LightColor.rgb;
			t_SpecularColor.rgb = 0.0;
		}

		vec4 t_LightDir;
		vec3 t_LightVec;
		lightComputeDir(t_WvPosition, t_LightColor.w, t_LightData, t_LightDir, t_LightVec);

		vec4 t_LightDirection = gu_LightData[2];
		float t_SpotFallOff = computeSpotFalloff(t_LightDirection, t_LightVec);
		
		//判断是否是聚光灯, t_LightColor.w == 2 时才是聚光灯
		float t_IsSpotLight = sne(t_LightColor.w,2.0); //聚光灯时:0,非聚光灯时:1
		t_SpotFallOff = add(t_SpotFallOff,t_IsSpotLight);//聚光灯时:+0,非聚光灯时:+1
		t_SpotFallOff = min(t_SpotFallOff,1.0);//大于1时为1
		
		vec2 t_Light;
		computeLighting(t_WvNormal, t_ViewDir, t_LightDir.xyz, t_LightDir.w * t_SpotFallOff, u_Shininess.x, t_Light);
		
		vec3 t_DiffuseAccum.rgb  = t_DiffuseColor.rgb  * t_Light.x;
		vec3 t_SpecularAccum.rgb = t_SpecularColor.rgb * t_Light.y;
		
		//----------------light2------------------//
		#ifdef(SINGLE_PASS_LIGHTING1)
		{
			vec4 t_LightColor2 = gu_LightData[3];            
			vec4 t_LightData2 = gu_LightData[4];            

			#ifdef(MATERIAL_COLORS)
			{
				t_DiffuseColor.rgb  = u_Diffuse.rgb * t_LightColor2.rgb;
				t_SpecularColor.rgb = u_Specular.rgb * t_LightColor2.rgb;
			}
			#else
			{
				t_DiffuseColor.rgb  = t_LightColor2.rgb;
				t_SpecularColor.rgb = 0.0;
			}

			vec4 t_LightDir2;
			vec3 t_LightVec2;
			lightComputeDir(t_WvPosition, t_LightColor2.w, t_LightData2, t_LightDir2, t_LightVec2);

			vec4 t_LightDirection2 = gu_LightData[5];
			float t_SpotFallOff2 = computeSpotFalloff(t_LightDirection2, t_LightVec2);
			
			float t_IsSpotLight2 = sne(t_LightColor2.w,2.0); 
			t_SpotFallOff2 = add(t_SpotFallOff2,t_IsSpotLight2);
			t_SpotFallOff2 = min(t_SpotFallOff2,1.0);
			
			vec2 t_Light2;
			computeLighting(t_WvNormal, t_ViewDir, t_LightDir2.xyz, t_LightDir2.w * t_SpotFallOff2, u_Shininess.x, t_Light2);

			t_DiffuseAccum.rgb  += t_DiffuseColor.rgb  * t_Light2.x;
			t_SpecularAccum.rgb += t_SpecularColor.rgb * t_Light2.y;
		}
		
		//----------------light3------------------//
		#ifdef(SINGLE_PASS_LIGHTING2)
		{
			vec4 t_LightColor3 = gu_LightData[6];            
			vec4 t_LightData3 = gu_LightData[7];            

			#ifdef(MATERIAL_COLORS)
			{
				t_DiffuseColor.rgb  = u_Diffuse.rgb * t_LightColor3.rgb;
				t_SpecularColor.rgb = u_Specular.rgb * t_LightColor3.rgb;
			}
			#else
			{
				t_DiffuseColor.rgb  = t_LightColor3.rgb;
				t_SpecularColor.rgb = 0.0;
			}

			vec4 t_LightDir3;
			vec3 t_LightVec3;
			lightComputeDir(t_WvPosition, t_LightColor3.w, t_LightData3, t_LightDir3, t_LightVec3);
			
			vec4 t_LightDirection3 = gu_LightData[8];
			float t_SpotFallOff3 = computeSpotFalloff(t_LightDirection3, t_LightVec3);
			
			float t_IsSpotLight3 = sne(t_LightColor3.w,2.0); 
			t_SpotFallOff3 = add(t_SpotFallOff3,t_IsSpotLight3);
			t_SpotFallOff3 = min(t_SpotFallOff3,1.0);
		
			vec2 t_Light3;
			computeLighting(t_WvNormal, t_ViewDir, t_LightDir3.xyz, t_LightDir3.w * t_SpotFallOff3, u_Shininess.x, t_Light3);

			t_DiffuseAccum.rgb  += t_DiffuseColor.rgb  * t_Light3.x;
			t_SpecularAccum.rgb += t_SpecularColor.rgb * t_Light3.y;
		}
		
		//----------------light4------------------//
		#ifdef(SINGLE_PASS_LIGHTING3)
		{
			vec4 t_LightColor4 = gu_LightData[9];            
			vec4 t_LightData4 = gu_LightData[10];            

			#ifdef(MATERIAL_COLORS)
			{
				t_DiffuseColor.rgb  = u_Diffuse.rgb * t_LightColor4.rgb;
				t_SpecularColor.rgb = u_Specular.rgb * t_LightColor4.rgb;
			}
			#else
			{
				t_DiffuseColor.rgb  = t_LightColor4.rgb;
				t_SpecularColor.rgb = 0.0;
			}

			vec4 t_LightDir4;
			vec3 t_LightVec4;
			lightComputeDir(t_WvPosition, t_LightColor4.w, t_LightData4, t_LightDir4, t_LightVec4);
			
			vec4 t_LightDirection4 = gu_LightData[11];
			float t_SpotFallOff4 = computeSpotFalloff(t_LightDirection4, t_LightVec4);
			
			float t_IsSpotLight4 = sne(t_LightColor4.w,2.0); 
			t_SpotFallOff4 = add(t_SpotFallOff4,t_IsSpotLight4);
			t_SpotFallOff4 = min(t_SpotFallOff4,1.0);
		
			vec2 t_Light4;
			computeLighting(t_WvNormal, t_ViewDir, t_LightDir4.xyz, t_LightDir4.w * t_SpotFallOff4, u_Shininess.x, t_Light4);

			t_DiffuseAccum.rgb  += t_DiffuseColor.rgb  * t_Light4.x;
			t_SpecularAccum.rgb += t_SpecularColor.rgb * t_Light4.y;
		}
		
		t_DiffuseSum.rgb *= t_DiffuseAccum.rgb;
		t_SpecularSum.rgb *= t_SpecularAccum.rgb;
    }
	
	//result
	v_DiffuseSum = t_DiffuseSum;
	v_SpecularSum = t_SpecularSum;

    #ifdef(USE_REFLECTION)
	{
        vec3 t_WorldPos = (t_ModelSpacePos * u_WorldMatrix).xyz;

		vec3 t_I = u_CameraPosition - t_WorldPos;
        t_I = normalize( t_I );
		
		vec4 t_Normal.xyz = a_Normal;
		t_Normal.w = 0.0;
        vec3 t_N = normalize(t_Normal * u_WorldMatrix);

        //vec4 t_refVec.xyz = reflect(t_I, t_N);
        //t_refVec.w = u_FresnelParams.x + u_FresnelParams.y * pow(1.0 + dot3(t_I, t_N), u_FresnelParams.z);
		//v_RefVec = t_refVec;
		
		v_RefVec.xyz = reflect(t_I, t_N);
		
		float t_dot = dot3(t_I,t_N);
		t_dot += 1.0;
		t_dot = pow(t_dot,u_FresnelParams.z);
		t_dot *= u_FresnelParams.y;
		
        v_RefVec.w = u_FresnelParams.x + t_dot;
    } 
}