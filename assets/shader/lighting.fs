varying vec4 v_TexCoord;

varying vec3 v_AmbientSum;
varying vec4 v_DiffuseSum;
varying vec3 v_SpecularSum;

#ifndef(VERTEX_LIGHTING)
{
	uniform vec4 gu_LightDirection;
	
	varying vec3 v_LightVec;
    varying vec4 v_ViewDir;
    varying vec4 v_LightDir;
	
	#ifdef(NORMALMAP)
	{
		uniform sampler2D u_NormalMap<clamp,nearest>;   
	} 
	#else 
	{
		varying vec3 v_Normal;
	}
} 
#else 
{
    varying vec4 v_VertexLightValues;
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
    uniform vec4 u_Shininess;
	
	#ifdef(USE_REFLECTION)
	{
		uniform float m_ReflectionPower;
		uniform float m_ReflectionIntensity;

		uniform samplerCube u_EnvMap<clamp,nearest>;
		
		varying vec4 v_RefVec;
	}
}

void function main()
{
	float t_Alpha = v_DiffuseSum.a;
    #ifdef(DIFFUSEMAP)
	{
        vec4 t_DiffuseColor = texture2D(v_TexCoord.xy, u_DiffuseMap);
		t_Alpha *= t_DiffuseColor.a;
    } 
	//#else 
	//{
        //vec4 t_DiffuseColor = 1.0;
    //}

    #ifdef(ALPHAMAP)
	{
		vec4 t_AlphaColor = texture2D(v_TexCoord.xy, u_AlphaMap);
        t_Alpha *= t_AlphaColor.r;
    }
	
	#ifdef(DISCARD_ALPHA)
	{
		kill(t_Alpha - u_AlphaDiscardThreshold);
	}
	
	vec4 gl_FragColor;
	gl_FragColor.a = t_Alpha;

    #ifdef(SPECULARMAP)
	{
        vec4 t_SpecularColor = texture2D(v_TexCoord.xy,u_SpecularMap);
    } 
	//#else
	//{
        //vec4 t_SpecularColor = 1.0;
    //}

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
			vec4 t_SpecularColor = t_LightMapColor;
		}
	   
		#ifdef(DIFFUSEMAP)
		{
			t_DiffuseColor.rgb  *= t_LightMapColor;
		} 
		#else
		{
			vec4 t_DiffuseColor = t_LightMapColor;
		}
    }
	
    #ifdef(VERTEX_LIGHTING)
	{
        #ifdef(COLORRAMP)
		{
			vec2 t_UV.x = v_VertexLightValues.x;
			t_UV.y = 0;
			t_DiffuseColor.rgb  *= texture2D(t_UV, u_ColorRamp).rgb;
			t_UV.x = v_VertexLightValues.y;
			t_SpecularColor.rgb *= texture2D(t_UV, u_ColorRamp).rgb;
			
			#ifdef(DIFFUSEMAP || LIGHTMAP)
			{
				gl_FragColor.rgb =  v_AmbientSum.rgb  * t_DiffuseColor.rgb;
				gl_FragColor.rgb += v_DiffuseSum.rgb  * t_DiffuseColor.rgb;
			} 
			#else
			{
				gl_FragColor.rgb =  v_AmbientSum.rgb + v_DiffuseSum.rgb;
			}

			
			#ifdef(SPECULARMAP)
			{
				gl_FragColor.rgb += v_SpecularSum.rgb * t_SpecularColor.rgb;
			} 
			#else
			{
				gl_FragColor.rgb += v_SpecularSum.rgb;
			}
        }
		#else
		{
			#ifdef(DIFFUSEMAP || LIGHTMAP)
			{
				gl_FragColor.rgb =  v_AmbientSum.rgb  * t_DiffuseColor.rgb;
				gl_FragColor.rgb += v_DiffuseSum.rgb  * t_DiffuseColor.rgb  * v_VertexLightValues.x;
			} 
			#else
			{
				gl_FragColor.rgb =  v_AmbientSum.rgb;
				gl_FragColor.rgb += v_DiffuseSum.rgb * v_VertexLightValues.x;
			}

			#ifdef(SPECULARMAP)
			{
				gl_FragColor.rgb += v_SpecularSum.rgb * t_SpecularColor.rgb * v_VertexLightValues.y;
			} 
			#else
			{
				gl_FragColor.rgb += v_SpecularSum.rgb * v_VertexLightValues.y;
			}
		} 
    } 
	#else
	{
        vec4 t_LightDir = v_LightDir;
        t_LightDir.xyz = normalize(t_LightDir.xyz);
        
		//SpotFallOff
		vec4 t_lightDirection = gu_LightDirection;
		float t_SpotFallOff =  computeSpotFalloff(t_lightDirection, v_LightVec);

		//判断是否是聚光灯, t_lightDirection.w是packedAngleCos != 0 时才是聚光灯
		float t_IsSpotLight = seq(t_lightDirection.w,0.0); //聚光灯时:0,非聚光灯时:1
		t_SpotFallOff = add(t_SpotFallOff,t_IsSpotLight);//聚光灯时:+0,非聚光灯时:+1
		t_SpotFallOff = min(t_SpotFallOff,1.0);//大于1时为1
		
		vec3 t_Normal;
		#ifdef(NORMALMAP)
		{
			vec4 t_NormalHeight = texture2D(v_TexCoord.xy, u_NormalMap);
		    //Note the -2.0 and -1.0. We invert the green channel of the normal map, 
		    //as it's complient with normal maps generated with blender.
		    //see http://hub.jmonkeyengine.org/forum/topic/parallax-mapping-fundamental-bug/#post-256898
		    //for more explanation.
			//vec3 t_Normal = normalize((t_NormalHeight.xyz * Vec3(2.0,-2.0,2.0) - Vec3(1.0,-1.0,1.0)));
			t_Normal.xz = t_Normal.xz * 2.0;
			t_Normal.xz = t_Normal.xz - 1.0;
			t_Normal.y = -2.0 * t_Normal.y;
			t_Normal.y += 1.0;
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
		
		vec3 t_ViewDir = normalize(v_ViewDir.xyz);
		vec2 t_Light; 
		computeLighting(t_Normal, t_ViewDir, t_LightDir.xyz, t_LightDir.w * t_SpotFallOff, u_Shininess.x, t_Light);

		#ifdef(COLORRAMP)
		{
			vec2 t_UV.x = t_Light.x;
			t_UV.y = 0;
			
			#ifdef(DIFFUSEMAP || LIGHTMAP)
			{
				t_DiffuseColor.rgb *= texture2D(t_UV, u_ColorRamp).rgb;
			} 
			#else
			{
				vec4 t_DiffuseColor = texture2D(t_UV, u_ColorRamp);
			}

			t_UV.x = t_Light.y;
			#ifdef(SPECULARMAP || LIGHTMAP)
			{
				t_SpecularColor.rgb *= texture2D(t_UV, u_ColorRamp).rgb;
			} 
			#else
			{
				vec4 t_SpecularColor = texture2D(t_UV, u_ColorRamp);
			}

			//这时候不需要设为1.0了，之后不乘这个数字了
			//t_Light.xy = 1.0;
		}

		#ifdef(USE_REFLECTION)
		{
			vec3 t_RefColor.rgb = textureCube(v_RefVec.xyz,u_EnvMap).rgb;

			// Interpolate light specularity toward reflection color
			// Multiply result by specular map
			
			#ifdef(SPECULARMAP || LIGHTMAP || COLORRAMP)
			{
				t_SpecularColor.rgb *= lerp(t_SpecularSum2.rgb * t_Light.y, t_RefColor.rgb, v_RefVec.w);
			} 
			#else
			{
				vec4 t_SpecularColor = lerp(t_SpecularSum2.rgb * t_Light.y, t_RefColor.rgb, v_RefVec.w);
			}

			//vec3 t_SpecularSum2.rgb = v_SpecularSum.rgb;
			//t_SpecularSum2.rgb = 1.0;
			//t_Light.y = 1.0;
		}
		
		#ifdef(DIFFUSEMAP || LIGHTMAP || COLORRAMP)
		{
			gl_FragColor.rgb =  v_AmbientSum.rgb  * t_DiffuseColor.rgb;
			
			//COLORRAMP时,t_Light.x == 1
			#ifdef(COLORRAMP)
			{
				gl_FragColor.rgb +=  v_DiffuseSum.rgb * t_DiffuseColor.rgb;
			} 
			#else
			{
				gl_FragColor.rgb +=  v_DiffuseSum.rgb * t_DiffuseColor.rgb  * t_Light.x;
			}
		} 
		#else
		{
			gl_FragColor.rgb =  v_AmbientSum.rgb;
			gl_FragColor.rgb +=  v_DiffuseSum.rgb * t_Light.x;
		}
		
		#ifdef(SPECULARMAP || LIGHTMAP || COLORRAMP || USE_REFLECTION)
		{
			//USE_REFLECTION,t_Light.y == 1,v_SpecularSum.rgb == 1.0;
			#ifdef(USE_REFLECTION)
			{
				gl_FragColor.rgb += t_SpecularColor.rgb;
			} 
			//COLORRAMP时,t_Light.y == 1
			#elseif(COLORRAMP)
			{
				gl_FragColor.rgb +=  v_SpecularSum.rgb * t_SpecularColor.rgb;
			} 
			#else
			{
				gl_FragColor.rgb +=  v_SpecularSum.rgb * t_SpecularColor.rgb * t_Light.y;
			}
		} 
		#else
		{
			gl_FragColor.rgb +=  v_SpecularSum.rgb * t_Light.y;
		}
    }
    
	output = gl_FragColor;
}