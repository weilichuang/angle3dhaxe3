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
		uniform sampler2D u_NormalMap<SGSL_TEXT_FORMAT,clamp,nearest>;   
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
    uniform sampler2D u_DiffuseMap<SGSL_TEXT_FORMAT,clamp,nearest>;
}

#ifdef(SPECULARMAP)
{
    uniform sampler2D u_SpecularMap<SGSL_TEXT_FORMAT,clamp,nearest>;
}

#ifdef(LIGHTMAP)
{
    uniform sampler2D u_LightMap<SGSL_TEXT_FORMAT,clamp,nearest>;
}
  
#ifdef(ALPHAMAP)
{
    uniform sampler2D u_AlphaMap<SGSL_TEXT_FORMAT,clamp,nearest>;
}

#ifdef(COLORRAMP)
{
    uniform sampler2D u_ColorRamp<SGSL_TEXT_FORMAT,clamp,nearest>;
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

		uniform samplerCube u_EnvMap<SGSL_TEXT_FORMAT,clamp,nearest>;
		
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

    float t_Alpha = v_DiffuseSum.a * t_DiffuseColor.a;
    #ifdef(ALPHAMAP)
	{
        t_Alpha *= texture2D(v_TexCoord.xy, u_AlphaMap).r;
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
		vec3 t_Normal;
		#ifdef(NORMALMAP)
		{
			vec4 t_NormalHeight = texture2D(v_TexCoord.xy, u_NormalMap);
		    //Note the -2.0 and -1.0. We invert the green channel of the normal map, 
		    //as it's complient with normal maps generated with blender.
		    //see http://hub.jmonkeyengine.org/forum/topic/parallax-mapping-fundamental-bug/#post-256898
		    //for more explanation.
			//vec3 t_Normal = normalize((t_NormalHeight.xyz * Vec3(2.0,-2.0,2.0) - Vec3(1.0,-1.0,1.0)));

			t_Normal.x = t_NormalHeight.x * 2.0 - 1.0;
			t_Normal.y = t_NormalHeight.y * -2.0 + 1.0;
			t_Normal.z = t_NormalHeight.z * 2.0 - 1.0;
		    t_Normal = normalize(t_Normal);
		    #ifdef(LATC)
			{
			    t_Normal.z = sqrt(1.0 - (t_Normal.x * t_Normal.x) - (t_Normal.y * t_Normal.y));
		    }
		}
		#else 
		{
			t_Normal = v_Normal.xyz;
		    #ifndef(LOW_QUALITY)
			{
			    t_Normal = normalize(t_Normal);
		    }
		}
	}

    #ifdef(SPECULARMAP)
	{
        vec4 t_SpecularColor = texture2D(v_TexCoord.xy,u_SpecularMap);
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
            t_LightMapColor = texture2D(v_TexCoord.zw, u_LightMap).rgb;
        } 
	    #else 
	    {
            t_LightMapColor = texture2D(v_TexCoord.xy, u_LightMap).rgb;
        }
	   
       t_SpecularColor.rgb *= t_LightMapColor;
       t_DiffuseColor.rgb  *= t_LightMapColor;
    }
	
	vec4 gl_FragColor;

    #ifdef(VERTEX_LIGHTING)
	{
        #ifdef(COLORRAMP)
		{
			vec2 t_UV.x = v_VertexLightValues.x;
			t_UV.y = 0;
			t_DiffuseColor.rgb  *= texture2D(t_UV, u_ColorRamp).rgb;
			t_UV.x = v_VertexLightValues.y;
			t_SpecularColor.rgb *= texture2D(t_UV, u_ColorRamp).rgb;

			gl_FragColor.rgb =  v_AmbientSum.rgb  * t_DiffuseColor.rgb + 
                            v_DiffuseSum.rgb  * t_DiffuseColor.rgb +
                            v_SpecularSum.rgb * t_SpecularColor.rgb;
        }
		#else
		{
			gl_FragColor.rgb =  v_AmbientSum.rgb  * t_DiffuseColor.rgb + 
                            v_DiffuseSum.rgb  * t_DiffuseColor.rgb  * v_VertexLightValues.x +
                            v_SpecularSum.rgb * t_SpecularColor.rgb * v_VertexLightValues.y;
		} 
    } 
	#else
	{
        vec4 t_LightDir = v_LightDir;
        t_LightDir.xyz = normalize(t_LightDir.xyz);
        vec3 t_ViewDir = normalize(v_ViewDir.xyz);
		
		float t_SpotFallOff;
		vec4 t_lightDirection = gu_LightDirection;
		//spotLight
		if(t_lightDirection.w != 0.0)
		{
			t_SpotFallOff =  computeSpotFalloff(t_lightDirection, v_LightVec);
		}
		else
		{
			t_SpotFallOff = 1.0;
		}
		
		//if(t_SpotFallOff <= 0.0)
		//{
			//gl_FragColor.rgb = v_AmbientSum.rgb * t_DiffuseColor.rgb;
		//}
		//else
		//{
			vec2 t_Light; 
			computeLighting(t_Normal, t_ViewDir, t_LightDir.xyz, t_LightDir.w * t_SpotFallOff, u_Shininess.x, t_Light);

			#ifdef(COLORRAMP)
			{
				vec2 t_UV.x = t_Light.x;
				t_UV.y = 0;
				t_DiffuseColor.rgb  *= texture2D(t_UV, u_ColorRamp).rgb;
				t_UV.x = t_Light.y;
				t_SpecularColor.rgb *= texture2D(t_UV, u_ColorRamp).rgb;
				t_Light.xy = 1.0;
			}

			vec3 t_SpecularSum2.rgb = v_SpecularSum.rgb;
			#ifdef(USE_REFLECTION)
			{
				vec3 t_RefColor.rgb = textureCube(v_RefVec.xyz,u_EnvMap).rgb;

				// Interpolate light specularity toward reflection color
				// Multiply result by specular map
				t_SpecularColor.rgb = lerp(t_SpecularSum2.rgb * t_Light.y, t_RefColor.rgb, v_RefVec.w) * t_SpecularColor.rgb;

				t_SpecularSum2.rgb = 1.0;
				t_Light.y = 1.0;
			}

			gl_FragColor.rgb =  v_AmbientSum.rgb   * t_DiffuseColor.rgb  +
								v_DiffuseSum.rgb   * t_DiffuseColor.rgb  * t_Light.x +
								t_SpecularSum2.rgb * t_SpecularColor.rgb * t_Light.y;
		//}
    }
    gl_FragColor.a = t_Alpha;
	output = gl_FragColor;
}