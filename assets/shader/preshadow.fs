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

uniform vec4 u_NearFar(NearFar);
uniform vec4 u_BitSh;
uniform vec4 u_BitMsk;


varying vec4 v_Pos;

//float to rgba
//void function pack(float zDistance,vec4 color)
//{
	//color = u_BitSh * zDistance;
	//color = fract(color);
	//vec4 t_Color = color.yzww * u_BitMsk;
	//color = color - t_Color;
//}

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
	
	//float t_Depth = dot4(v_Pos,v_Pos);
	//t_Depth = sqrt(t_Depth);
	//t_Depth = t_Depth / u_NearFar.z;

	//Store screen-space z-coordinate or linear depth value (better precision)
	float t_Depth = v_Pos.z / v_Pos.w;
	
	vec4 t_Result = u_BitSh * t_Depth;
	t_Result = fract(t_Result);
	vec4 t_Color = t_Result.yzww * u_BitMsk;
	output = t_Result - t_Color;
}