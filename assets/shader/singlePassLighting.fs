varying vec2 v_TexCoord;

varying vec3 v_AmbientSum;
varying vec4 v_DiffuseSum;
varying vec3 v_SpecularSum;

#ifndef(VERTEX_LIGHTING)
{
	uniform vec4 u_Shininess;
	uniform vec4 gu_LightData[NB_LIGHTS];
	
	varying vec3 v_Normal;
	varying vec3 v_Pos;
	
    #ifdef(NORMALMAP)
    {
		uniform sampler2D u_NormalMap<clamp,nearest>;  
		
		varying vec3 v_Tangent;
		varying vec3 v_Binormal;
    }
	
	#ifdef(COLORRAMP)
	{
		uniform sampler2D u_ColorRamp<clamp,nearest>;
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

#ifdef(ALPHAMAP)
{
    uniform sampler2D u_AlphaMap<clamp,nearest>;
}

#ifdef(DISCARD_ALPHA)
{
	uniform float u_AlphaDiscardThreshold;
}

#ifndef(VERTEX_LIGHTING)
{
	#ifdef(USE_REFLECTION)
	{
		uniform samplerCube u_EnvMap<clamp,nearest>;
		
		varying vec4 v_RefVec;
	}
}

void function main()
{
    #ifdef(DIFFUSEMAP)
	{
        vec4 t_DiffuseColor = texture2D(v_TexCoord.xy, u_DiffuseMap);
    } 
	//#else 
	//{
        //vec4 t_DiffuseColor = 1.0;
    //}

    float t_Alpha;
	#ifndef(VERTEX_LIGHTING)
	{
		#ifdef(DIFFUSEMAP)
		{
			t_Alpha = v_DiffuseSum.a * t_DiffuseColor.a;
		} 
		#else
		{
			t_Alpha = v_DiffuseSum.a;
		}
	}
	#else 
	{
		#ifdef(DIFFUSEMAP)
		{
			t_Alpha = t_DiffuseColor.a;
		} 
		#else
		{
			t_Alpha = 1.0;
		}
	}
	
    #ifdef(ALPHAMAP)
	{
        t_Alpha *= texture2D(v_TexCoord.xy, u_AlphaMap).r;
    }
	
	#ifdef(DISCARD_ALPHA)
	{
		kill(t_Alpha - u_AlphaDiscardThreshold);
	}
	
	vec4 gl_FragColor.a = t_Alpha;
	
	#ifdef(SPECULARMAP)
	{
        vec3 t_SpecularColor = texture2D(v_TexCoord.xy,u_SpecularMap).rgb;
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
		
		#ifdef(SPECULARMAP)
		{
			t_SpecularColor.rgb *= t_LightMapColor;
		}
	    #else
		{
			vec3 t_SpecularColor = t_LightMapColor;
		}
		
		#ifdef(DIFFUSEMAP)
		{
			t_DiffuseColor.rgb *= t_LightMapColor;
		}
	    #else
		{
			vec3 t_DiffuseColor = t_LightMapColor;
		}
    }

    #ifdef(VERTEX_LIGHTING)
	{
		#ifdef(DIFFUSEMAP || LIGHTMAP)
		{
			gl_FragColor.rgb =  v_AmbientSum.rgb  * t_DiffuseColor.rgb; 
			gl_FragColor.rgb += v_DiffuseSum.rgb  * t_DiffuseColor.rgb;
		}
		#else
		{
			gl_FragColor.rgb = v_AmbientSum.rgb + v_DiffuseSum.rgb; 
		}

		#ifdef(SPECULARMAP || LIGHTMAP)
		{
			gl_FragColor.rgb += v_SpecularSum.rgb * t_SpecularColor.rgb;
		}
		#else
		{
			gl_FragColor.rgb += v_SpecularSum.rgb;
		}
		output = gl_FragColor;
    } 
	#else
	{
		#ifdef(DIFFUSEMAP || LIGHTMAP)
		{
			gl_FragColor.rgb = v_AmbientSum.rgb * t_DiffuseColor.rgb;
		}
		#else
		{
			gl_FragColor.rgb = v_AmbientSum.rgb;
		}
		
		vec3 t_Normal;
		#ifdef(NORMALMAP)
		{
			t_Normal = texture2D(v_TexCoord.xy, u_NormalMap).xyz;
		    //Note the -2.0 and -1.0. We invert the green channel of the normal map, 
		    //as it's complient with normal maps generated with blender.
		    //see http://hub.jmonkeyengine.org/forum/topic/parallax-mapping-fundamental-bug/#post-256898
		    //for more explanation.
			//vec3 t_Normal = normalize((t_NormalHeight.xyz * Vec3(2.0,-2.0,2.0) - Vec3(1.0,-1.0,1.0)));

			//t_Normal.xz = t_Normal.xz * 2.0;
			//t_Normal.xz = t_Normal.xz - 1.0;
			//t_Normal.y = -2.0 * t_Normal.y;
			//t_Normal.y += 1.0;
			
			t_Normal.xyz = t_Normal.xyz * 2.0;
			t_Normal.xyz = t_Normal.xyz - 1.0;
		    t_Normal = normalize(t_Normal);
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
		
		vec3 t_ViewDir;
		#ifdef(NORMALMAP)
		{
			mat3 t_TbnMat;
			vec3 t_Tangent = normalize(v_Tangent.xyz);
			t_TbnMat[0] = t_Tangent;
			vec3 t_Binormal = normalize(v_Binormal.xyz);
			t_TbnMat[1] = t_Binormal;
			vec3 t_vNormal = normalize(v_Normal.xyz);
			t_TbnMat[2] = t_vNormal;
			vec3 t_Pos = -v_Pos.xyz;
			t_ViewDir = m33(t_Pos,t_TbnMat);
		} 
		#else 
		{
			t_ViewDir = -v_Pos.xyz;
		}
		t_ViewDir = normalize(t_ViewDir);
		
		//--------------light1---------------//
		vec4 t_LightDir;
		vec3 t_LightVec;
		float t_LightType = gu_LightData[0].w;
		vec4 t_LightData = gu_LightData[1];  
		lightComputeDir(v_Pos.xyz, t_LightType, t_LightData, t_LightDir, t_LightVec);
		
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
		
		vec4 t_LightDirection = gu_LightData[2];
		float t_SpotFallOff = computeSpotFalloff(t_LightDirection, t_LightVec);
		
		//判断是否是聚光灯, t_LightType == 2 时才是聚光灯
		float t_IsSpotLight = sne(t_LightType,2.0); //聚光灯时:0,非聚光灯时:1
		t_SpotFallOff = add(t_SpotFallOff,t_IsSpotLight);//聚光灯时:+0,非聚光灯时:+1
		t_SpotFallOff = min(t_SpotFallOff,1.0);//大于1时为1

		vec2 t_Light;
		computeLighting(t_Normal, t_ViewDir, t_LightDir.xyz, t_LightDir.w * t_SpotFallOff, u_Shininess.x, t_Light);
		
		vec3 t_SpecularColor0 = t_SpecularColor;
		#ifdef(USE_REFLECTION)
		{
			vec4 t_RefColor = textureCube(v_RefVec.xyz,u_EnvMap);
			
			// Interpolate light specularity toward reflection color
			// Multiply result by specular map
			
			#ifdef(SPECULARMAP || LIGHTMAP)
			{
				t_SpecularColor0 *= lerp(v_SpecularSum.rgb * t_Light.y, t_RefColor.rgb, v_RefVec.w);
			}
			#else
			{
				t_SpecularColor0 = lerp(v_SpecularSum.rgb * t_Light.y, t_RefColor.rgb, v_RefVec.w);
			}
		}
		#else
		{
			vec3 t_SpecularSum = v_SpecularSum.rgb;
		}
		
		#ifdef(COLORRAMP)
		{
		    vec3 t_DiffuseSum = v_DiffuseSum.rgb;
		    vec2 t_Uv = 0;
		    t_Uv.x = t_Light.x;
		    t_DiffuseSum.rgb *= texture2D(t_Uv,u_ColorRamp).rgb;
		   
		    t_Uv.x = t_Light.y;
			
			
			#ifdef(USE_REFLECTION)
			{
				vec3 t_SpecularSum.rgb = texture2D(t_Uv,u_ColorRamp).rgb;
			}
			#else
			{
				t_SpecularSum.rgb *= texture2D(t_Uv,u_ColorRamp).rgb;
			}

		    #ifdef(DIFFUSEMAP || LIGHTMAP)
			{
				gl_FragColor.rgb += t_DiffuseSum.rgb * gu_LightData[0].rgb * t_DiffuseColor.rgb;
			}
			#else
			{
				gl_FragColor.rgb += t_DiffuseSum.rgb * gu_LightData[0].rgb;
			}
			
			#ifdef(SPECULARMAP || LIGHTMAP || USE_REFLECTION)
			{
				gl_FragColor.rgb += t_SpecularSum.rgb * gu_LightData[0].rgb * t_SpecularColor0.rgb;
			}
			#else
			{
				gl_FragColor.rgb += t_SpecularSum.rgb * gu_LightData[0].rgb;
			}
		}
		#else
		{
			#ifdef(DIFFUSEMAP || LIGHTMAP)
			{
				gl_FragColor.rgb += v_DiffuseSum.rgb * gu_LightData[0].rgb * t_DiffuseColor.rgb  * t_Light.x;
			}
			#else
			{
				gl_FragColor.rgb += v_DiffuseSum.rgb * gu_LightData[0].rgb * t_Light.x;
			}
			
			#ifdef(SPECULARMAP || LIGHTMAP || USE_REFLECTION)
			{
				#ifdef(USE_REFLECTION)
				{
					gl_FragColor.rgb += gu_LightData[0].rgb * t_SpecularColor0.rgb;
				}
				#else
				{
					gl_FragColor.rgb += v_SpecularSum.rgb * gu_LightData[0].rgb * t_SpecularColor0.rgb * t_Light.y;
				}
			}
			#else
			{
				gl_FragColor.rgb += v_SpecularSum.rgb * gu_LightData[0].rgb * t_Light.y;
			}
		}
		
		//--------------light2---------------//
		#ifdef(SINGLE_PASS_LIGHTING1)
		{
			vec4 t_LightDir2;
			vec3 t_LightVec2;
			float t_LightType2 = gu_LightData[3].w;
			vec4 t_LightData2 = gu_LightData[4]; 
			lightComputeDir(v_Pos.xyz, t_LightType2, t_LightData2, t_LightDir2, t_LightVec2);
			
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
			
			vec4 t_LightDirection2 = gu_LightData[5];
			float t_SpotFallOff2 = computeSpotFalloff(t_LightDirection2, t_LightVec2);
			
			float t_IsSpotLight2 = sne(t_LightType2,2.0);
			t_SpotFallOff2 = add(t_SpotFallOff2,t_IsSpotLight2);
			t_SpotFallOff2 = min(t_SpotFallOff2,1.0);

			vec2 t_Light2;
			computeLighting(t_Normal, t_ViewDir, t_LightDir2.xyz, t_LightDir2.w * t_SpotFallOff2, u_Shininess.x, t_Light2);
					
			vec3 t_SpecularColor2 = t_SpecularColor;
			#ifdef(USE_REFLECTION)
			{
				// Interpolate light specularity toward reflection color
				// Multiply result by specular map
				#ifdef(SPECULARMAP || LIGHTMAP)
				{
					t_SpecularColor2 *= lerp(v_SpecularSum.rgb * t_Light2.y, t_RefColor.rgb, v_RefVec.w);
				}
				#else
				{
					t_SpecularColor2 = lerp(v_SpecularSum.rgb * t_Light2.y, t_RefColor.rgb, v_RefVec.w);
				}
			}
			#else
			{
				vec3 t_SpecularSum2 = v_SpecularSum.rgb;
			}
			
			#ifdef(COLORRAMP)
			{
			    vec3 t_DiffuseSum2 = v_DiffuseSum.rgb;
			    vec2 t_Uv2 = 0;
			    t_Uv2.x = t_Light2.x;
			    t_DiffuseSum2.rgb *= texture2D(t_Uv2,u_ColorRamp).rgb;
			   
			    t_Uv2.x = t_Light2.y;

				#ifdef(USE_REFLECTION)
				{
					vec3 t_SpecularSum2.rgb = texture2D(t_Uv2,u_ColorRamp).rgb;
				}
				#else
				{
					t_SpecularSum2.rgb *= texture2D(t_Uv2,u_ColorRamp).rgb;
				}
			   
			    #ifdef(DIFFUSEMAP || LIGHTMAP)
				{
					gl_FragColor.rgb += t_DiffuseSum2.rgb  * gu_LightData[3].rgb * t_DiffuseColor.rgb;
				}
				#else
				{
					gl_FragColor.rgb += t_DiffuseSum2.rgb  * gu_LightData[3].rgb;
				}
				
				#ifdef(SPECULARMAP || LIGHTMAP || USE_REFLECTION)
				{
					gl_FragColor.rgb += t_SpecularSum2.rgb * gu_LightData[3].rgb * t_SpecularColor2.rgb;
				}
				#else
				{
					gl_FragColor.rgb += t_SpecularSum2.rgb * gu_LightData[3].rgb;
				}
			}
			#else
			{
				#ifdef(DIFFUSEMAP || LIGHTMAP)
				{
					gl_FragColor.rgb += v_DiffuseSum.rgb * gu_LightData[3].rgb * t_DiffuseColor.rgb * t_Light2.x;
				}
				#else
				{
					gl_FragColor.rgb += v_DiffuseSum.rgb * gu_LightData[3].rgb * t_Light2.x;
				}

				#ifdef(SPECULARMAP || LIGHTMAP || USE_REFLECTION)
				{
					#ifdef(USE_REFLECTION)
					{
						gl_FragColor.rgb += gu_LightData[3].rgb * t_SpecularColor2.rgb;
					}
					#else
					{
						gl_FragColor.rgb += t_SpecularSum2.rgb * gu_LightData[3].rgb * t_SpecularColor2.rgb * t_Light2.y;
					}
				}
				#else
				{
					gl_FragColor.rgb += t_SpecularSum2.rgb * gu_LightData[3].rgb * t_Light2.y;
				}
			}
		}
		
		//--------------light3---------------//
		#ifdef(SINGLE_PASS_LIGHTING2)
		{
			vec4 t_LightDir3;
			vec3 t_LightVec3;
			float t_LightType3 = gu_LightData[6].w;
			vec4 t_LightData3 = gu_LightData[7];  
			lightComputeDir(v_Pos.xyz, t_LightType3, t_LightData3, t_LightDir3, t_LightVec3);
			
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
			
			vec4 t_LightDirection3 = gu_LightData[8];
			float t_SpotFallOff3 = computeSpotFalloff(t_LightDirection3, t_LightVec3);

			float t_IsSpotLight3 = sne(t_LightType3,2.0);
			t_SpotFallOff3 = add(t_SpotFallOff3,t_IsSpotLight3);
			t_SpotFallOff3 = min(t_SpotFallOff3,1.0);

			vec2 t_Light3;
			computeLighting(t_Normal, t_ViewDir, t_LightDir3.xyz, t_LightDir3.w * t_SpotFallOff3, u_Shininess.x, t_Light3);
			
			// Workaround, since it is not possible to modify varying variables
			
			vec3 t_SpecularColor3 = t_SpecularColor;
			#ifdef(USE_REFLECTION)
			{
				// Interpolate light specularity toward reflection color
				// Multiply result by specular map
				#ifdef(SPECULARMAP || LIGHTMAP)
				{
					t_SpecularColor3 *= lerp(v_SpecularSum.rgb * t_Light3.y, t_RefColor.rgb, v_RefVec.w);
				}
				#else
				{
					t_SpecularColor3 = lerp(v_SpecularSum.rgb * t_Light3.y, t_RefColor.rgb, v_RefVec.w);
				}
			}
			#else
			{
				vec3 t_SpecularSum3 = v_SpecularSum.rgb;
			}
			
			#ifdef(COLORRAMP)
			{
				vec3 t_DiffuseSum3 = v_DiffuseSum.rgb;
			    vec2 t_Uv3 = 0;
			    t_Uv3.x = t_Light3.x;
			    t_DiffuseSum3.rgb *= texture2D(t_Uv3,u_ColorRamp).rgb;
			   
			    t_Uv3.x = t_Light3.y;
				
				
				#ifdef(USE_REFLECTION)
				{
					vec3 t_SpecularSum3.rgb = texture2D(t_Uv3,u_ColorRamp).rgb;
				}
				#else
				{
					t_SpecularSum3.rgb *= texture2D(t_Uv3,u_ColorRamp).rgb;
				}
				
				#ifdef(DIFFUSEMAP || LIGHTMAP)
				{
					gl_FragColor.rgb += t_DiffuseSum3.rgb * gu_LightData[6].rgb * t_DiffuseColor.rgb;
				}
				#else
				{
					gl_FragColor.rgb += t_DiffuseSum3.rgb * gu_LightData[6].rgb;
				}

				#ifdef(SPECULARMAP || LIGHTMAP || USE_REFLECTION)
				{
					gl_FragColor.rgb += t_SpecularSum3.rgb * gu_LightData[6].rgb * t_SpecularColor3.rgb;
				}
				#else
				{
					gl_FragColor.rgb += t_SpecularSum3.rgb * gu_LightData[6].rgb;
				}
			}
			#else
			{
				#ifdef(DIFFUSEMAP || LIGHTMAP)
				{
					gl_FragColor.rgb += v_DiffuseSum.rgb * gu_LightData[6].rgb * t_DiffuseColor.rgb  * t_Light3.x;
				}
				#else
				{
					gl_FragColor.rgb += v_DiffuseSum.rgb * gu_LightData[6].rgb * t_Light3.x;
				}
				
				#ifdef(SPECULARMAP || LIGHTMAP || USE_REFLECTION)
				{
					#ifdef(USE_REFLECTION)
					{
						gl_FragColor.rgb += gu_LightData[6].rgb * t_SpecularColor3.rgb;
					}
					#else
					{
						gl_FragColor.rgb += t_SpecularSum3.rgb * gu_LightData[6].rgb * t_SpecularColor3.rgb * t_Light3.y;
					}
				}
				#else
				{
					gl_FragColor.rgb += t_SpecularSum3.rgb * gu_LightData[6].rgb * t_Light3.y;
				}
			}
		}
		
		//--------------light4---------------//
		#ifdef(SINGLE_PASS_LIGHTING3)
		{
			vec4 t_LightDir4;
			vec3 t_LightVec4;
			float t_LightType4 = gu_LightData[9].w;
			vec4 t_LightData4 = gu_LightData[10];  
			lightComputeDir(v_Pos.xyz, t_LightType4, t_LightData4, t_LightDir4, t_LightVec4);
			
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
			
			vec4 t_LightDirection4 = gu_LightData[11];
			float t_SpotFallOff4 = computeSpotFalloff(t_LightDirection4, t_LightVec4);

			float t_IsSpotLight4 = sne(t_LightType4,2.0);
			t_SpotFallOff4 = add(t_SpotFallOff4,t_IsSpotLight4);
			t_SpotFallOff4 = min(t_SpotFallOff4,1.0);
			
			vec2 t_Light4;
			computeLighting(t_Normal, t_ViewDir, t_LightDir4.xyz, t_LightDir4.w * t_SpotFallOff4, u_Shininess.x, t_Light4);
			
			vec3 t_SpecularColor4 = t_SpecularColor;
			#ifdef(USE_REFLECTION)
			{
				// Interpolate light specularity toward reflection color
				// Multiply result by specular map
				#ifdef(SPECULARMAP || LIGHTMAP)
				{
					t_SpecularColor4 *= lerp(v_SpecularSum.rgb * t_Light4.y, t_RefColor.rgb, v_RefVec.w);
				}
				#else
				{
					t_SpecularColor4 = lerp(v_SpecularSum.rgb * t_Light4.y, t_RefColor.rgb, v_RefVec.w);
				}
			}
			#else
			{
				vec3 t_SpecularSum4 = v_SpecularSum.rgb;
			}
			
			#ifdef(COLORRAMP)
			{
				vec3 t_DiffuseSum4 = v_DiffuseSum.rgb;
			    vec2 t_Uv4 = 0;
			    t_Uv4.x = t_Light4.x;
			    t_DiffuseSum4.rgb *= texture2D(t_Uv4,u_ColorRamp).rgb;
			   
			    t_Uv4.x = t_Light4.y;
				
			    #ifdef(USE_REFLECTION)
				{
					vec3 t_SpecularSum4.rgb = texture2D(t_Uv4,u_ColorRamp).rgb;
				}
				#else
				{
					t_SpecularSum4.rgb *= texture2D(t_Uv4,u_ColorRamp).rgb;
				}
				
				#ifdef(DIFFUSEMAP || LIGHTMAP)
				{
					gl_FragColor.rgb += t_DiffuseSum4.rgb * gu_LightData[9].rgb * t_DiffuseColor.rgb;
				}
				#else
				{
					gl_FragColor.rgb += t_DiffuseSum4.rgb * gu_LightData[9].rgb;
				}

			    #ifdef(SPECULARMAP || LIGHTMAP || USE_REFLECTION)
				{
					gl_FragColor.rgb += t_SpecularSum4.rgb * gu_LightData[9].rgb * t_SpecularColor4.rgb;
				}
				#else
				{
					gl_FragColor.rgb += t_SpecularSum4.rgb * gu_LightData[9].rgb;
				}
			}
			#else
			{
				#ifdef(DIFFUSEMAP || LIGHTMAP)
				{
					gl_FragColor.rgb += v_DiffuseSum.rgb * gu_LightData[9].rgb * t_DiffuseColor.rgb  * t_Light4.x;
				}
				#else
				{
					gl_FragColor.rgb += v_DiffuseSum.rgb * gu_LightData[9].rgb * t_Light4.x;
				}
				
				#ifdef(SPECULARMAP || LIGHTMAP || USE_REFLECTION)
				{
					#ifdef(USE_REFLECTION)
					{
						gl_FragColor.rgb += gu_LightData[9].rgb * t_SpecularColor4.rgb;
					}
					#else
					{
						gl_FragColor.rgb += t_SpecularSum4.rgb * gu_LightData[9].rgb * t_SpecularColor4.rgb * t_Light4.y;
					}
				}
				#else
				{
					gl_FragColor.rgb += t_SpecularSum4.rgb * gu_LightData[9].rgb * t_Light4.y;
				}
			}
		}
		
		output = gl_FragColor;
    }
}