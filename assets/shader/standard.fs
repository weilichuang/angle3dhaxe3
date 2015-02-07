uniform sampler2D s_texture;

#ifdef(lightmap)
{
    uniform sampler2D s_lightmap;
}

varying vec4 v_texCoord;

#ifdef(lightmap && useTexCoord2)
{
   varying vec4 v_texCoord2;
}

#ifdef(REFLECTION)
{
	uniform vec4 u_reflectivity;
	varying vec4 v_Reflect;
}

#ifdef(REFRACTION)
{
	uniform vec4 u_transmittance;
	varying vec4 v_Refract;
}

#ifdef(REFLECTION || REFRACTION)
{
	uniform samplerCube u_environmentMap;
}

//
void function main()
{
	vec4 t_textureMapColor = texture2D(v_texCoord,s_texture);

    #ifdef(lightmap)
	{
		vec4 t_lightMapColor;
        #ifdef(useTexCoord2)
		{
			t_lightMapColor = texture2D(v_texCoord2,s_lightmap);
        }
        #else
		{
			t_lightMapColor = texture2D(v_texCoord,s_lightmap);
        }

        t_textureMapColor = multiply(t_textureMapColor,t_lightMapColor);
    }
	
	#ifdef(REFLECTION)
	{
		vec4 t_reflectedColor = textureCube(v_Reflect,u_environmentMap);
		output = lerp(t_textureMapColor,t_reflectedColor,u_reflectivity.x);
	}
	#elseif(REFRACTION)
	{
		vec4 t_refefractdColor = textureCube(v_Refract,u_environmentMap);
		output = lerp(t_textureMapColor,t_refefractdColor,u_transmittance.x);
	}
	#else
	{
		output = t_textureMapColor;
	}
	
    
}