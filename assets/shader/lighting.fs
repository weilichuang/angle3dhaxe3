varying vec2 v_TexCoord;
#ifdef(SEPARATE_TEXCOORD)
{
    varying vec2 v_TexCoord2;
}

varying vec3 v_AmbientSum;
varying vec4 v_DiffuseSum;
varying vec3 v_SpecularSum;

#ifndef(VERTEX_LIGHTING)
{
	uniform vec4 gu_LightDirection;
	
	varying vec3 v_LightVec;
    varying vec4 v_ViewDir;
    varying vec4 v_LightDir;
} 
#else 
{
    varying vec4 v_VertexLightValues;
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
#else 
{
    varying vec3 v_Normal;
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
    uniform vec4 u_Shininess;
	
	#ifdef(USE_REFLECTION)
	{
		uniform float m_ReflectionPower;
		uniform float m_ReflectionIntensity;

		uniform samplerCube u_EnvMap;
		
		varying vec4 v_RefVec;
	}
	
	/*
	* Computes the spot falloff for a spotlight
	*/
	float function computeSpotFalloff(vec4 lightDirection, vec3 lightVector){
		vec3 t_L = normalize(lightVector);
		vec3 t_Spotdir = lightDirection.xyz;
		t_Spotdir = normalize(t_Spotdir);
		//vec3 t_Spotdir = normalize(lightDirection.xyz);
		float t_CurAngleCos = dot3(-t_L, t_Spotdir);   
		float t_w = lightDirection.w;
		float t_InnerAngleCos = floor(t_w) * 0.001;
		float t_OuterAngleCos = fract(t_w);
		float t_InnerMinusOuter = t_InnerAngleCos - t_OuterAngleCos;
		return clamp((t_CurAngleCos - t_OuterAngleCos) / t_InnerMinusOuter, step(t_w, 0.001), 1.0);
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
    vec2 t_NewTexCoord = v_TexCoord; 

    #ifdef(DIFFUSEMAP)
	{
        vec4 t_DiffuseColor = texture2D(t_NewTexCoord, u_DiffuseMap);
    } 
	#else 
	{
        vec4 t_DiffuseColor = 1.0;
    }

    float t_Alpha = v_DiffuseSum.a * t_DiffuseColor.a;
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
			vec3 t_Normal = v_Normal.xyz;
		    #ifndef(LOW_QUALITY && V_TANGENT)
			{
			    t_Normal = normalize(t_Normal);
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
        vec2 t_Light = v_VertexLightValues.xy;
		
        #ifdef(COLORRAMP)
		{
            t_Light.x = texture2D(Vec2(t_Light.x, 0.0),u_ColorRamp).r;
            t_Light.y = texture2D(Vec2(t_Light.y, 0.0),u_ColorRamp).r;
        }

        gl_FragColor.rgb =  v_AmbientSum.rgb  * t_DiffuseColor.rgb + 
                            v_DiffuseSum.rgb  * t_DiffuseColor.rgb  * t_Light.x +
                            v_SpecularSum.rgb * t_SpecularColor.rgb * t_Light.y;
    } 
	#else
	{
        vec4 t_LightDir = v_LightDir;
        t_LightDir.xyz = normalize(t_LightDir.xyz);
        vec3 t_ViewDir = normalize(v_ViewDir.xyz);
		
		float t_SpotFallOff = 1.0;
		float t_PackedAngleCos = gu_LightDirection.w;
		//spotLight
		//if(t_PackedAngleCos != 0.0)
		//{
			//t_SpotFallOff =  computeSpotFalloff(gu_LightDirection, v_LightVec);
		//}
		
		if(t_SpotFallOff <= 0.0)
		{
			gl_FragColor.rgb = v_AmbientSum.rgb * t_DiffuseColor.rgb;
		}
		else
		{
			float t_shininess = u_Shininess.x;
			vec2 t_Light; 
			computeLighting(t_Normal, t_ViewDir, t_LightDir.xyz, t_LightDir.w * t_SpotFallOff, t_shininess,t_Light);

			#ifdef(COLORRAMP)
			{
				t_DiffuseColor.rgb  = t_DiffuseColor.rgb  * texture2D(Vec2(t_Light.x, 0.0), u_ColorRamp).rgb;
				t_SpecularColor.rgb = t_SpecularColor.rgb * texture2D(Vec2(t_Light.y, 0.0), u_ColorRamp).rgb;
			}

			// Workaround, since it is not possible to modify varying variables
			vec4 t_SpecularSum2.rgb = v_SpecularSum.rgb;
			t_SpecularSum2.w = 1.0;
			#ifdef(USE_REFLECTION)
			{
				//TODO support sphere map
				vec4 t_RefColor = textureCube(v_RefVec.xyz,u_EnvMap);

				// Interpolate light specularity toward reflection color
				// Multiply result by specular map
				t_SpecularColor = lerp(t_SpecularSum2 * t_Light.y, t_RefColor, v_RefVec.w) * t_SpecularColor;

				t_SpecularSum2.rgba = 1.0;
				t_Light.y = 1.0;
			}

			gl_FragColor.rgb =  v_AmbientSum.rgb   * t_DiffuseColor.rgb  +
								v_DiffuseSum.rgb   * t_DiffuseColor.rgb  * t_Light.x +
								t_SpecularSum2.rgb * t_SpecularColor.rgb * t_Light.y;
		}
    }
    gl_FragColor.a = t_Alpha;
	output = gl_FragColor;
}