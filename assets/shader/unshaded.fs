uniform sampler2D s_texture;

varying vec4 v_texCoord;

#ifdef(HAS_LIGHTMAP)
{
    uniform sampler2D s_lightmap;
	
	#ifdef(USETEXCOORD2)
	{
	   varying vec4 v_texCoord2;
	}
}

varying vec4 v_ambientColor;

void function main()
{
	vec4 t_textureMapColor = texture2D(v_texCoord,s_texture);

    #ifdef(HAS_LIGHTMAP)
	{
		vec4 t_lightMapColor;
        #ifdef(USETEXCOORD2)
		{
			t_lightMapColor = texture2D(v_texCoord2,s_lightmap);
        }
        #else
		{
			t_lightMapColor = texture2D(v_texCoord,s_lightmap);
        }

        t_textureMapColor = t_textureMapColor * t_lightMapColor;
    }
    output = t_textureMapColor * v_ambientColor;
}