varying vec2 v_TexCoord;

varying vec3 v_AmbientSum;
varying vec4 v_DiffuseSum;
varying vec4 v_SpecularSum;

#ifndef(VERTEX_LIGHTING)
{
	uniform vec4 u_Shininess;
	uniform vec4 gu_LightData[NB_LIGHTS];
	
	varying vec4 v_Pos;
	varying vec3 v_Normal;
	
    #ifdef(NORMALMAP)
    {
		varying vec3 v_Tangent;
		varying vec3 v_Binormal;
		uniform mat3 u_Mat3;
    }
}

#ifdef(DIFFUSEMAP)
{
    uniform sampler2D u_DiffuseMap<clamp,nearest>;
}

#ifdef(SPECULARMAP)
{
    uniform sampler2D u_SpecularMap<clamp,nearest>;
}

#ifdef(LIGHTMAP)
{
    uniform sampler2D u_LightMap<clamp,nearest>;
}
  
#ifdef(NORMALMAP)
{
    uniform sampler2D u_NormalMap<clamp,nearest>;   
}

#ifdef(ALPHAMAP)
{
    uniform sampler2D u_AlphaMap<clamp,nearest>;
}

#ifdef(COLORRAMP)
{
    uniform sampler2D u_ColorRamp<clamp,nearest>;
}

#ifdef(DISCARD_ALPHA)
{
	uniform float u_AlphaDiscardThreshold;
}

#ifndef(VERTEX_LIGHTING)
{
	#ifdef(USE_REFLECTION)
	{
		uniform float m_ReflectionPower;
		uniform float m_ReflectionIntensity;

		uniform samplerCube u_EnvMap;
		
		varying vec4 v_RefVec;
	}
}

void function main()
{
    #ifdef(DIFFUSEMAP)
	{
        vec4 t_DiffuseColor = texture2D(v_TexCoord.xy, u_DiffuseMap);
    } 
	#else 
	{
        vec4 t_DiffuseColor = 1.0;
    }
	
	#ifdef(SPECULARMAP)
	{
        vec3 t_SpecularColor = texture2D(v_TexCoord.xy,u_SpecularMap).rgb;
    } 
	#else
	{
        vec3 t_SpecularColor = 1.0;
    }

    float t_Alpha;
	#ifndef(VERTEX_LIGHTING)
	{
		t_Alpha = v_DiffuseSum.a * t_DiffuseColor.a;
	}
	#else 
	{
		t_Alpha = t_DiffuseColor.a;
	}
	
    #ifdef(ALPHAMAP)
	{
        t_Alpha = t_Alpha * texture2D(v_TexCoord.xy, u_AlphaMap).r;
    }
	
	#ifdef(DISCARD_ALPHA)
	{
		kill(t_Alpha - u_AlphaDiscardThreshold);
	}

    #ifdef(LIGHTMAP)
	{
        vec3 t_LightMapColor;
        #ifdef(SEPARATE_TEXCOORD)
	    {
            t_LightMapColor = texture2D(v_TexCoord.zw, u_LightMap).rgb;
        } 
	    #else 
	    {
            t_LightMapColor = texture2D(v_TexCoord.xy, u_LightMap).rgb;
        }
	   
       t_SpecularColor.rgb *= t_LightMapColor;
       t_DiffuseColor.rgb  *= t_LightMapColor;
    }
	
	vec4 gl_FragColor.a = t_Alpha;

    #ifdef(VERTEX_LIGHTING)
	{
        gl_FragColor.rgb =  v_AmbientSum.rgb  * t_DiffuseColor.rgb + 
                            v_DiffuseSum.rgb  * t_DiffuseColor.rgb +
                            v_SpecularSum.rgb * t_SpecularColor.rgb;
    } 
	#else
	{
		vec3 t_ViewDir;
		#ifdef(NORMALMAP)
		{
			mat3 t_TbnMat = u_Mat3;
			t_TbnMat[0].xyz = normalize(v_Tangent.xyz);
			t_TbnMat[1].xyz = normalize(v_Binormal.xyz);
			t_TbnMat[2].xyz = normalize(v_Normal.xyz);
			t_ViewDir = m33(v_Pos.xyz,t_TbnMat);
			t_ViewDir = -t_ViewDir;
		} 
		#else 
		{
			t_ViewDir = -v_Pos.xyz;
		}
		t_ViewDir = normalize(t_ViewDir);
		
		vec3 t_Normal;
		#ifdef(NORMALMAP)
		{
			t_Normal = texture2D(v_TexCoord.xy, u_NormalMap).rgb;
		    //Note the -2.0 and -1.0. We invert the green channel of the normal map, 
		    //as it's complient with normal maps generated with blender.
		    //see http://hub.jmonkeyengine.org/forum/topic/parallax-mapping-fundamental-bug/#post-256898
		    //for more explanation.
			//vec3 t_Normal = normalize((t_NormalHeight.xyz * Vec3(2.0,-2.0,2.0) - Vec3(1.0,-1.0,1.0)));
			t_Normal.x = t_Normal.x * 2.0 - 1.0;
			t_Normal.y = t_Normal.y * -2.0 + 1.0;
			t_Normal.z = t_Normal.z * 2.0 - 1.0;
		    t_Normal = normalize(t_Normal);
		    #ifdef(LATC)
			{
			    t_Normal.z = sqrt(1.0 - (t_Normal.x * t_Normal.x) - (t_Normal.y * t_Normal.y));
		    }
		}
		#else 
		{
		    #ifndef(LOW_QUALITY)
			{
			    t_Normal = normalize(v_Normal.xyz);
		    }
			#else
			{
				t_Normal = v_Normal.xyz;
			}	
		}
		
		gl_FragColor.rgb = v_AmbientSum.rgb * t_DiffuseColor.rgb;
		
		#ifdef(USE_REFLECTION)
		{
			vec4 t_RefColor = textureCube(v_RefVec.xyz,u_EnvMap);
		}

		//--------------light1---------------//
        vec4 t_LightData = gu_LightData[1];    
		
		vec4 t_LightDir;
		vec3 t_LightVec;
		float t_LightType = gu_LightData[0].w;
		lightComputeDir(v_Pos.xyz, t_LightType, t_LightData, t_LightDir, t_LightVec);
		
		float t_SpotFallOff;
		if(t_LightType > 1.0)
		{
			vec4 t_LightDirection = gu_LightData[2];
			t_SpotFallOff = computeSpotFalloff(t_LightDirection, t_LightVec);
		}
		else
		{
			t_SpotFallOff = 1.0;
		}

		#ifdef(NORMALMAP)
		{
			//Normal map -> lighting is computed in tangent space
			t_LightDir.xyz = normalize(m33(t_LightDir.xyz,t_TbnMat)); 
		}
		#else
		{
			//no Normal map -> lighting is computed in view space
			t_LightDir.xyz = normalize(t_LightDir.xyz);  
		}
		
		vec2 t_Light;
		computeLighting(t_Normal, t_ViewDir, t_LightDir.xyz, t_LightDir.w * t_SpotFallOff, u_Shininess.x,t_Light);
		
		vec4 t_SpecularSum = v_SpecularSum;
		#ifdef(USE_REFLECTION)
		{
			// Interpolate light specularity toward reflection color
			// Multiply result by specular map
			t_SpecularColor *= lerp(t_SpecularSum.rgb * t_Light.y, t_RefColor.rgb, v_RefVec.w);

			t_SpecularSum = 1.0;
			t_Light.y = 1.0;
		}

		vec3 t_DiffuseSum = v_DiffuseSum.rgb;
		#ifdef(COLORRAMP)
		{
		   vec2 t_Uv = 0;
		   t_Uv.x = t_Light.x;
		   t_DiffuseSum.rgb *= texture2D(t_Uv,m_ColorRamp).rgb;
		   
		   t_Uv.x = t_Light.y;
		   t_SpecularSum.rgb *= texture2D(t_Uv,m_ColorRamp).rgb;

		   gl_FragColor.rgb += t_DiffuseSum.rgb * gu_LightData[0].rgb * t_DiffuseColor.rgb +
							  t_SpecularSum.rgb * gu_LightData[0].rgb * t_SpecularColor.rgb;
		}
		#else
		{
			gl_FragColor.rgb += t_DiffuseSum.rgb * gu_LightData[0].rgb * t_DiffuseColor.rgb  * t_Light.x +
							   t_SpecularSum.rgb * gu_LightData[0].rgb * t_SpecularColor.rgb * t_Light.y;
		}
		
		//--------------light2---------------//
		#ifdef(SINGLE_PASS_LIGHTING1)
		{
			vec4 t_LightData2 = gu_LightData[4];    
			
			vec4 t_LightDir2;
			vec3 t_LightVec2;
			float t_LightType2 = gu_LightData[3].w;
			lightComputeDir(v_Pos.xyz, t_LightType2, t_LightData2, t_LightDir2, t_LightVec2);
			
			float t_SpotFallOff2;
			if(t_LightType2 > 1.0)
			{
				vec4 t_LightDirection2 = gu_LightData[5];
				t_SpotFallOff2 = computeSpotFalloff(t_LightDirection2, t_LightVec2);
			}
			else
			{
				t_SpotFallOff2 = 1.0;
			}

			#ifdef(NORMALMAP)
			{
				//Normal map -> lighting is computed in tangent space
				t_LightDir2.xyz = normalize(m33(t_LightDir2.xyz,t_TbnMat)); 
			}
			#else
			{
				//no Normal map -> lighting is computed in view space
				t_LightDir2.xyz = normalize(t_LightDir2.xyz);  
			}
			
			vec2 t_Light2;
			computeLighting(t_Normal, t_ViewDir, t_LightDir2.xyz, t_LightDir2.w * t_SpotFallOff2, u_Shininess.x, t_Light2);
			
			// Workaround, since it is not possible to modify varying variables
			vec4 t_SpecularSum2 = v_SpecularSum;
			#ifdef(USE_REFLECTION)
			{
				 // Interpolate light specularity toward reflection color
				 // Multiply result by specular map
				 t_SpecularColor *= lerp(t_SpecularSum2.rgb * t_Light2.y, t_RefColor.rgb, v_RefVec.w);
				 t_SpecularSum2 = 1.0;
				 t_Light2.y = 1.0;
			}
			
			vec3 t_DiffuseSum2 = v_DiffuseSum.rgb;
			#ifdef(COLORRAMP)
			{
			   vec2 t_Uv2 = 0;
			   t_Uv2.x = t_Light2.x;
			   t_DiffuseSum2.rgb *= texture2D(t_Uv2,m_ColorRamp).rgb;
			   
			   t_Uv2.x = t_Light2.y;
			   t_SpecularSum2.rgb *= texture2D(t_Uv2,m_ColorRamp).rgb;

			   gl_FragColor.rgb += t_DiffuseSum2.rgb  * gu_LightData[3].rgb * t_DiffuseColor.rgb +
								  t_SpecularSum2.rgb * gu_LightData[3].rgb * t_SpecularColor.rgb;
			}
			#else
			{
				gl_FragColor.rgb += t_DiffuseSum2.rgb * gu_LightData[3].rgb * t_DiffuseColor.rgb  * t_Light2.x +
								   t_SpecularSum2.rgb * gu_LightData[3].rgb * t_SpecularColor.rgb * t_Light2.y;
			}
		}
		
		//--------------light3---------------//
		#ifdef(SINGLE_PASS_LIGHTING2)
		{
			vec4 t_LightData3 = gu_LightData[7];    
			
			vec4 t_LightDir3;
			vec3 t_LightVec3;
			float t_LightType3 = gu_LightData[6].w;
			lightComputeDir(v_Pos.xyz, t_LightType3, t_LightData3, t_LightDir3, t_LightVec3);
			
			float t_SpotFallOff3;
			if(t_LightType3 > 1.0)
			{
				vec4 t_LightDirection3 = gu_LightData[8];
				t_SpotFallOff3 = computeSpotFalloff(t_LightDirection3, t_LightVec3);
			}
			else
			{
				t_SpotFallOff3 = 1.0;
			}

			#ifdef(NORMALMAP)
			{
				//Normal map -> lighting is computed in tangent space
				t_LightDir3.xyz = normalize(m33(t_LightDir3.xyz,t_TbnMat)); 
			}
			#else
			{
				//no Normal map -> lighting is computed in view space
				t_LightDir3.xyz = normalize(t_LightDir3.xyz);  
			}
			
			vec2 t_Light3;
			computeLighting(t_Normal, t_ViewDir, t_LightDir3.xyz, t_LightDir3.w * t_SpotFallOff3, u_Shininess.x, t_Light3);
			
			// Workaround, since it is not possible to modify varying variables
			vec4 t_SpecularSum3 = v_SpecularSum;
			#ifdef(USE_REFLECTION)
			{
				 // Interpolate light specularity toward reflection color
				 // Multiply result by specular map
				 t_SpecularColor *= lerp(t_SpecularSum3.rgb * t_Light3.y, t_RefColor.rgb, v_RefVec.w);

				 t_SpecularSum3 = 1.0;
				 t_Light3.y = 1.0;
			}
			
			vec3 t_DiffuseSum3 = v_DiffuseSum.rgb;
			#ifdef(COLORRAMP)
			{
			   vec2 t_Uv3 = 0;
			   t_Uv3.x = t_Light3.x;
			   t_DiffuseSum3.rgb *= texture2D(t_Uv3,m_ColorRamp).rgb;
			   
			   t_Uv3.x = t_Light3.y;
			   t_SpecularSum3.rgb *= texture2D(t_Uv3,m_ColorRamp).rgb;

			   gl_FragColor.rgb += t_DiffuseSum3.rgb * gu_LightData[6].rgb * t_DiffuseColor.rgb +
								  t_SpecularSum3.rgb * gu_LightData[6].rgb * t_SpecularColor.rgb;
			}
			#else
			{
				gl_FragColor.rgb += t_DiffuseSum3.rgb * gu_LightData[6].rgb * t_DiffuseColor.rgb  * t_Light3.x +
								   t_SpecularSum3.rgb * gu_LightData[6].rgb * t_SpecularColor.rgb * t_Light3.y;
			}
		}
		
		//--------------light4---------------//
		#ifdef(SINGLE_PASS_LIGHTING3)
		{
			vec4 t_LightData4 = gu_LightData[10];    
			
			vec4 t_LightDir4;
			vec3 t_LightVec4;
			float t_LightType4 = gu_LightData[9].w;
			lightComputeDir(v_Pos.xyz, t_LightType4, t_LightData4, t_LightDir4, t_LightVec4);
			
			float t_SpotFallOff4;
			if(t_LightType4 > 1.0)
			{
				vec4 t_LightDirection4 = gu_LightData[11];
				t_SpotFallOff4 = computeSpotFalloff(t_LightDirection4, t_LightVec4);
			}
			else
			{
				t_SpotFallOff4 = 1.0;
			}
			
			#ifdef(NORMALMAP)
			{
				//Normal map -> lighting is computed in tangent space
				t_LightDir4.xyz = normalize(m33(t_LightDir4.xyz,t_TbnMat)); 
			}
			#else
			{
				//no Normal map -> lighting is computed in view space
				t_LightDir4.xyz = normalize(t_LightDir4.xyz);  
			}
			
			vec2 t_Light4;
			computeLighting(t_Normal, t_ViewDir, t_LightDir4.xyz, t_LightDir4.w * t_SpotFallOff4, u_Shininess.x, t_Light4);
			
			// Workaround, since it is not possible to modify varying variables
			vec4 t_SpecularSum4 = v_SpecularSum;
			#ifdef(USE_REFLECTION)
			{
				 // Interpolate light specularity toward reflection color
				 // Multiply result by specular map
				 t_SpecularColor *= lerp(t_SpecularSum4.rgb * t_Light4.y, t_RefColor.rgb, v_RefVec.w);

				 t_SpecularSum4 = 1.0;
				 t_Light4.y = 1.0;
			}
			
			vec3 t_DiffuseSum4 = v_DiffuseSum.rgb;
			#ifdef(COLORRAMP)
			{
			   vec2 t_Uv4 = 0;
			   t_Uv4.x = t_Light4.x;
			   t_DiffuseSum4.rgb *= texture2D(t_Uv4,m_ColorRamp).rgb;
			   
			   t_Uv4.x = t_Light4.y;
			   t_SpecularSum4.rgb *= texture2D(t_Uv4,m_ColorRamp).rgb;

			   gl_FragColor.rgb += t_DiffuseSum4.rgb * gu_LightData[9].rgb * t_DiffuseColor.rgb +
								  t_SpecularSum4.rgb * gu_LightData[9].rgb * t_SpecularColor.rgb;
			}
			#else
			{
				gl_FragColor.rgb += t_DiffuseSum4.rgb * gu_LightData[9].rgb * t_DiffuseColor.rgb  * t_Light4.x +
								   t_SpecularSum4.rgb * gu_LightData[9].rgb * t_SpecularColor.rgb * t_Light4.y;
			}
		}
    }
	output = gl_FragColor;
}