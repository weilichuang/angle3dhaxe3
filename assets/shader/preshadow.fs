#ifdef(DISCARD_ALPHA)
{
    #ifdef(COLOR_MAP)
    {
        uniform sampler2D m_ColorMap;
    }
    #elseif(DIFFUSEMAP)   
    {
        uniform sampler2D m_DiffuseMap;
    }
	
    uniform float m_AlphaDiscardThreshold;
	
	#ifdef(COLOR_MAP || DIFFUSEMAP)
    {
		varying vec2 v_TexCoord;
    }
}

varying vec4 v_Pos;

void function main()
{
	#ifdef(DISCARD_ALPHA)
	{
		#ifdef(COLOR_MAP)
		{
			float t_Alpha = texture2D(v_TexCoord.xy,m_ColorMap).a;
			kill(t_Alpha - m_AlphaDiscardThreshold);
		}
		#elseif(DIFFUSEMAP)    
		{
			float t_Alpha2 = texture2D(v_TexCoord.xy,m_DiffuseMap).a;
			kill(t_Alpha2 - m_AlphaDiscardThreshold);
		}
	}

	vec4 t_Result;
	t_Result.g = fract(v_Pos.z);
	t_Result.r = v_Pos.z - t_Result.g;
	t_Result.r = t_Result.r / 255;
	t_Result.b = 0;
	t_Result.a = 1;
	
	output = t_Result;
}