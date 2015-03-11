varying vec2 v_TexCoord;
#ifdef(SEPARATE_TEXCOORD)
{
    varying vec2 v_TexCoord2;
}

varying vec3 v_AmbientSum;
varying vec4 v_Pos;
#ifdef(VERTEX_LIGHTING)
{
	varying vec4 v_SpecularAccum;
    varying vec4 v_DiffuseAccum;
} 
#else 
{
	uniform vec4 u_Shininess;
	uniform vec4 gu_LightData[NB_LIGHTS];
	
	varying vec4 v_DiffuseSum;
	varying vec3 v_SpecularSum;
	varying vec3 v_Normal;
	
    #ifdef(NORMALMAP)
    {
		varying vec3 v_Tangent;
		varying vec3 v_Binormal;
    }
}

#ifdef(DIFFUSEMAP)
{
    uniform sampler2D u_DiffuseMap;
}

#ifdef(SPECULARMAP)
{
    uniform sampler2D u_SpecularMap;
}

#ifdef(LIGHTMAP)
{
    uniform sampler2D u_LightMap;
}
  
#ifdef(NORMALMAP)
{
    uniform sampler2D u_NormalMap;   
}

#ifdef(ALPHAMAP)
{
    uniform sampler2D u_AlphaMap;
}

#ifdef(COLORRAMP)
{
    uniform sampler2D u_ColorRamp;
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
	vec3 t_ViewDir;
	#ifdef(NORMALMAP)
	{
		mat3 t_TbnMat;
		t_TbnMat[0] = normalize(v_Tangent.xyz);
		t_TbnMat[1] = normalize(v_Binormal.xyz);
		t_TbnMat[2] = normalize(v_Normal.xyz);
        t_ViewDir = -m33(v_Pos.xyz,t_TbnMat);
    } 
	#else 
	{
        t_ViewDir = -v_Pos.xyz;
    }
	t_ViewDir = normalize(t_ViewDir);
	
    vec2 t_NewTexCoord = v_TexCoord; 

    #ifdef(DIFFUSEMAP)
	{
        vec4 t_DiffuseColor = texture2D(t_NewTexCoord, u_DiffuseMap);
    } 
	#else 
	{
        vec4 t_DiffuseColor = 1.0;
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
        t_Alpha = t_Alpha * texture2D(t_NewTexCoord, u_AlphaMap).r;
    }
	
	#ifdef(DISCARD_ALPHA)
	{
		kill(t_Alpha - u_AlphaDiscardThreshold);
	}
 
    // ***********************
    // Read from textures
    // ***********************
	#ifndef(VERTEX_LIGHTING)
	{
		#ifdef(NORMALMAP)
		{
			vec4 t_NormalHeight = texture2D(t_NewTexCoord, u_NormalMap);
		    //Note the -2.0 and -1.0. We invert the green channel of the normal map, 
		    //as it's complient with normal maps generated with blender.
		    //see http://hub.jmonkeyengine.org/forum/topic/parallax-mapping-fundamental-bug/#post-256898
		    //for more explanation.
			//vec3 t_Normal = normalize((t_NormalHeight.xyz * Vec3(2.0,-2.0,2.0) - Vec3(1.0,-1.0,1.0)));
			vec3 t_height;
			t_height.x = t_NormalHeight.x * 2.0 - 1.0;
			t_height.y = t_NormalHeight.y * -2.0 + 1.0;
			t_height.z = t_NormalHeight.z * 2.0 - 1.0;
			
		    vec3 t_Normal = normalize(t_height);
		    #ifdef(LATC)
			{
			    t_Normal.z = sqrt(1.0 - (t_Normal.x * t_Normal.x) - (t_Normal.y * t_Normal.y));
		    }
		}
		#else 
		{
			vec3 t_Normal; 
		    #ifndef(LOW_QUALITY)
			{
			    t_Normal = normalize(v_Normal.xyz);
		    }
			#else
			{
				t_Normal = v_Normal.xyz;
			}	
		}
	}

    #ifdef(SPECULARMAP)
	{
        vec4 t_SpecularColor = texture2D(t_NewTexCoord,u_SpecularMap);
    } 
	#else
	{
        vec4 t_SpecularColor = 1.0;
    }

    #ifdef(LIGHTMAP)
	{
        vec3 t_LightMapColor;
        #ifdef(SEPARATE_TEXCOORD)
	    {
            t_LightMapColor = texture2D(v_TexCoord2, u_LightMap).rgb;
        } 
	    #else 
	    {
            t_LightMapColor = texture2D(v_TexCoord, u_LightMap).rgb;
        }
	   
       t_SpecularColor.rgb = t_SpecularColor.rgb * t_LightMapColor;
       t_DiffuseColor.rgb  = t_DiffuseColor.rgb * t_LightMapColor;
    }
	
	vec4 gl_FragColor;

    #ifdef(VERTEX_LIGHTING)
	{
        gl_FragColor.rgb =  v_AmbientSum.rgb  * t_DiffuseColor.rgb + 
                            v_DiffuseAccum.rgb  * t_DiffuseColor.rgb +
                            v_SpecularAccum.rgb * t_SpecularColor.rgb;
    } 
	#else
	{
		gl_FragColor.rgb = v_AmbientSum.rgb * t_DiffuseColor.rgb;
		
		vec4 t_RefColor;
		#ifdef(USE_REFLECTION)
		{
			t_RefColor = textureCube(v_RefVec.xyz,u_EnvMap);
		}
		
		float t_shininess = u_Shininess.x;
		

		//--------------light1---------------//
		vec4 t_LightColor = gu_LightData[0];
        vec4 t_LightData = gu_LightData[1];    
		
		vec4 t_LightDir;
		vec3 t_LightVec;
		lightComputeDir(v_Pos.xyz, t_LightColor.w, t_LightData, t_LightDir, t_LightVec);
		
		float t_SpotFallOff = 1.0;
		if(t_LightColor.w > 1.0)
		{
			vec4 t_LightDirection = gu_LightData[2];
			t_SpotFallOff = computeSpotFalloff(t_LightDirection, t_LightVec);
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
		computeLighting(t_Normal, t_ViewDir, t_LightDir.xyz, t_LightDir.w * t_SpotFallOff, t_shininess,t_Light);
		
		// Workaround, since it is not possible to modify varying variables
		vec4 t_SpecularSum = 1.0;
		#ifdef(USE_REFLECTION)
		{
			// Interpolate light specularity toward reflection color
			// Multiply result by specular map
			t_SpecularColor = lerp(t_SpecularSum * t_Light.y, t_RefColor, v_RefVec.w) * t_SpecularColor;

			t_SpecularSum = 1.0;
			t_Light.y = 1.0;
		}

		
		#ifdef(COLORRAMP)
		{
		   vec4 t_DiffuseSum;
		   vec2 t_Uv = 0;
		   t_Uv.x = t_Light.x;
		   t_DiffuseSum.rgb  = texture2D(t_Uv,m_ColorRamp).rgb;
		   
		   t_Uv.x = t_Light.y;
		   t_SpecularSum.rgb = t_SpecularSum * texture2D(t_Uv,m_ColorRamp).rgb;

		   gl_FragColor.rgb = gl_FragColor.rgb + 
							  t_DiffuseSum.rgb   * t_LightColor.rgb * t_DiffuseColor.rgb +
							  t_SpecularSum.rgb * t_LightColor.rgb * t_SpecularColor.rgb;
		}
		#else
		{
			gl_FragColor.rgb = gl_FragColor.rgb + 
							   t_LightColor.rgb * t_DiffuseColor.rgb  * t_Light.x +
							   t_SpecularSum.rgb * t_LightColor.rgb * t_SpecularColor.rgb * t_Light.y;
		}
		
		//--------------light2---------------//
		#ifdef(SINGLE_PASS_LIGHTING1)
		{
			vec4 t_LightColor2 = gu_LightData[3];
			vec4 t_LightData2 = gu_LightData[4];    
			
			vec4 t_LightDir2;
			vec3 t_LightVec2;
			lightComputeDir(v_Pos.xyz, t_LightColor2.w, t_LightData2, t_LightDir2, t_LightVec2);
			
			float t_SpotFallOff2 = 1.0;
			if(t_LightColor2.w > 1.0)
			{
				vec4 t_LightDirection2 = gu_LightData[5];
				t_SpotFallOff2 = computeSpotFalloff(t_LightDirection2, t_LightVec2);
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
			computeLighting(t_Normal, t_ViewDir, t_LightDir2.xyz, t_LightDir2.w * t_SpotFallOff2, t_shininess, t_Light2);
			
			// Workaround, since it is not possible to modify varying variables
			vec4 t_SpecularSum2 = 1.0;
			#ifdef(USE_REFLECTION)
			{
				 // Interpolate light specularity toward reflection color
				 // Multiply result by specular map
				 t_SpecularColor = lerp(t_SpecularSum2 * t_Light2.y, t_RefColor, v_RefVec.w) * t_SpecularColor;

				 t_SpecularSum2 = 1.0;
				 t_Light2.y = 1.0;
			}
			
			#ifdef(COLORRAMP)
			{
			   vec2 t_Uv2 = 0;
			   t_Uv2.x = t_Light2.x;
			   vec3 t_DiffuseSum2.rgb  = texture2D(t_Uv2,m_ColorRamp).rgb;
			   
			   t_Uv2.x = t_Light2.y;
			   t_SpecularSum2.rgb = t_SpecularSum2 * texture2D(t_Uv2,m_ColorRamp).rgb;

			   gl_FragColor.rgb = gl_FragColor.rgb + 
								  t_DiffuseSum2.rgb   * t_LightColor2.rgb * t_DiffuseColor.rgb +
								  t_SpecularSum2.rgb * t_LightColor2.rgb * t_SpecularColor.rgb;
			}
			#else
			{
				gl_FragColor.rgb = gl_FragColor.rgb + 
								   t_LightColor2.rgb * t_DiffuseColor.rgb  * t_Light2.x +
								   t_SpecularSum2.rgb * t_LightColor2.rgb * t_SpecularColor.rgb * t_Light2.y;
			}
		}
		
		//--------------light3---------------//
		#ifdef(SINGLE_PASS_LIGHTING2)
		{
			vec4 t_LightColor3 = gu_LightData[6];
			vec4 t_LightData3 = gu_LightData[7];    
			
			vec4 t_LightDir3;
			vec3 t_LightVec3;
			lightComputeDir(v_Pos.xyz, t_LightColor3.w, t_LightData3, t_LightDir3, t_LightVec3);
			
			float t_SpotFallOff3 = 1.0;
			if(t_LightColor3.w > 1.0)
			{
				vec4 t_LightDirection3 = gu_LightData[8];
				t_SpotFallOff3 = computeSpotFalloff(t_LightDirection3, t_LightVec3);
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
			computeLighting(t_Normal, t_ViewDir, t_LightDir3.xyz, t_LightDir3.w * t_SpotFallOff3, t_shininess, t_Light3);
			
			// Workaround, since it is not possible to modify varying variables
			vec4 t_SpecularSum3 = 1.0;
			#ifdef(USE_REFLECTION)
			{
				 // Interpolate light specularity toward reflection color
				 // Multiply result by specular map
				 t_SpecularColor = lerp(t_SpecularSum3 * t_Light3.y, t_RefColor, v_RefVec.w) * t_SpecularColor;

				 t_SpecularSum3 = 1.0;
				 t_Light3.y = 1.0;
			}
			
			#ifdef(COLORRAMP)
			{
			   vec2 t_Uv3 = 0;
			   t_Uv3.x = t_Light3.x;
			   vec3 t_DiffuseSum3.rgb  = texture2D(t_Uv3,m_ColorRamp).rgb;
			   
			   t_Uv3.x = t_Light3.y;
			   t_SpecularSum3.rgb = t_SpecularSum3 * texture2D(t_Uv3,m_ColorRamp).rgb;

			   gl_FragColor.rgb = gl_FragColor.rgb + 
								  t_DiffuseSum3.rgb   * t_LightColor3.rgb * t_DiffuseColor.rgb +
								  t_SpecularSum3.rgb * t_LightColor3.rgb * t_SpecularColor.rgb;
			}
			#else
			{
				gl_FragColor.rgb = gl_FragColor.rgb + 
								   t_LightColor3.rgb * t_DiffuseColor.rgb  * t_Light3.x +
								   t_SpecularSum3.rgb * t_LightColor3.rgb * t_SpecularColor.rgb * t_Light3.y;
			}
		}
		
		//--------------light4---------------//
		#ifdef(SINGLE_PASS_LIGHTING3)
		{
			vec4 t_LightColor4 = gu_LightData[9];
			vec4 t_LightData4 = gu_LightData[10];    
			
			vec4 t_LightDir4;
			vec3 t_LightVec4;
			lightComputeDir(v_Pos.xyz, t_LightColor4.w, t_LightData4, t_LightDir4, t_LightVec4);
			
			float t_SpotFallOff4 = 1.0;
			if(t_LightColor4.w > 1.0)
			{
				vec4 t_LightDirection4 = gu_LightData[11];
				t_SpotFallOff4 = computeSpotFalloff(t_LightDirection4, t_LightVec4);
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
			computeLighting(t_Normal, t_ViewDir, t_LightDir4.xyz, t_LightDir4.w * t_SpotFallOff4, t_shininess, t_Light4);
			
			// Workaround, since it is not possible to modify varying variables
			vec4 t_SpecularSum4 = 1.0;
			#ifdef(USE_REFLECTION)
			{
				 // Interpolate light specularity toward reflection color
				 // Multiply result by specular map
				 t_SpecularColor = lerp(t_SpecularSum4 * t_Light4.y, t_RefColor, v_RefVec.w) * t_SpecularColor;

				 t_SpecularSum4 = 1.0;
				 t_Light4.y = 1.0;
			}
			
			#ifdef(COLORRAMP)
			{
			   vec2 t_Uv4 = 0;
			   t_Uv4.x = t_Light4.x;
			   vec3 t_DiffuseSum2.rgb  = texture2D(t_Uv4,m_ColorRamp).rgb;
			   
			   t_Uv4.x = t_Light4.y;
			   t_SpecularSum4.rgb = t_SpecularSum4 * texture2D(t_Uv4,m_ColorRamp).rgb;

			   gl_FragColor.rgb = gl_FragColor.rgb + 
								  t_DiffuseSum4.rgb   * t_LightColor4.rgb * t_DiffuseColor.rgb +
								  t_SpecularSum4.rgb * t_LightColor4.rgb * t_SpecularColor.rgb;
			}
			#else
			{
				gl_FragColor.rgb = gl_FragColor.rgb + 
								   t_LightColor4.rgb * t_DiffuseColor.rgb  * t_Light4.x +
								   t_SpecularSum4.rgb * t_LightColor4.rgb * t_SpecularColor.rgb * t_Light4.y;
			}
		}
		
    }
    gl_FragColor.a = t_Alpha;
	output = gl_FragColor;
}