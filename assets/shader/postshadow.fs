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
	output = 1.0;
}