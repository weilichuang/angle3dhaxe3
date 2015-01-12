temp vec4 t_textureMapColor;
			
uniform sampler2D s_texture;

#ifdef(lightmap)
{
    temp vec4 t_lightMapColor;
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

	t_textureMapColor = texture2D(v_texCoord,s_texture);

    #ifdef(lightmap)
	{
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