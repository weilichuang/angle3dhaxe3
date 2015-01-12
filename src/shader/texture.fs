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
    output = t_textureMapColor;
}