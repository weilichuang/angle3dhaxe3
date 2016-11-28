#ifdef(DIFFUSEMAP)
{
   uniform sampler2D u_DiffuseMap<clamp,nearest>;
   varying vec4 v_TexCoord;
}

#ifdef(LIGHTMAP)
{
	uniform sampler2D u_LightMap<clamp,nearest>;
}

#ifdef(REFLECTMAP)
{
	uniform vec4 u_Reflectivity;
	varying vec4 v_Reflect;
	uniform samplerCube u_ReflectMap<clamp,nearest>;
}

#ifdef(REFRACTIMAP)
{
	uniform vec4 u_Transmittance;
	varying vec4 v_Refract;
	uniform samplerCube u_RefractMap<clamp,nearest>;
}

#ifdef(ALPHAMAP)
{
    uniform sampler2D u_AlphaMap<clamp,nearest>;
}

#ifdef(VERTEX_COLOR || MATERIAL_COLORS){
	varying vec4 v_Color;
}

#ifdef(DISCARD_ALPHA)
{
	uniform vec4 u_AlphaDiscardThreshold;
}

void function main()
{
	vec4 t_Color = 1.0;
	
	#ifdef(DIFFUSEMAP)
	{
		t_Color = texture2D(v_TexCoord.xy,u_DiffuseMap);
	}
	
	#ifdef(VERTEX_COLOR || MATERIAL_COLORS)
	{
		t_Color *= v_Color;
	}
	
	#ifdef(ALPHAMAP)
	{
        t_Color.a *= texture2D(v_TexCoord.xy, u_AlphaMap).r;
    }
	
	#ifdef(DISCARD_ALPHA)
	{
		kill(t_Color.a - u_AlphaDiscardThreshold.x);
	}

    #ifdef(LIGHTMAP)
	{
        #ifdef(SeparateTexCoord)
		{
			t_Color.rgb = t_Color.rgb * texture2D(v_TexCoord.zw,u_LightMap).rgb;
        }
        #else
		{
			t_Color.rgb = t_Color.rgb * texture2D(v_TexCoord.xy,u_LightMap).rgb;
        }
    }
	
	#ifdef(REFLECTMAP)
	{
		vec3 t_ReflectedColor = textureCube(v_Reflect.xyz,u_ReflectMap).rgb;
		t_Color.rgb = lerp(t_Color.rgb,t_ReflectedColor,u_Reflectivity.x);
	}
	
	#ifdef(REFRACTIMAP)
	{
		vec3 t_RefefractdColor = textureCube(v_Refract.xyz,u_RefractMap).rgb;
		t_Color.rgb = lerp(t_Color.rgb,t_RefefractdColor,u_Transmittance.x);
	}
	
    output = t_Color;
}