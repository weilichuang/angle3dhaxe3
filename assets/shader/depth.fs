#ifdef(DISCARD_ALPHA && COLOR_MAP)
{
	uniform sampler2D u_ColorMap;
	uniform float u_AlphaDiscardThreshold;
	
	varying vec2 v_TexCoord;
}

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
	#ifdef(DISCARD_ALPHA && COLOR_MAP)
	{
		float t_Alpha = texture2D(v_TexCoord.xy,u_ColorMap).a;
		kill(t_Alpha - u_AlphaDiscardThreshold);
	}

	//float t_Depth = v_Pos.z/v_Pos.w;
	//t_Depth += 1.0;
	//t_Depth *= 0.5;
	
	vec4 t_Result = u_BitSh * v_Pos.z;
	t_Result = fract(t_Result);
	vec4 t_Color = t_Result.yzww * u_BitMsk;
	output = t_Result - t_Color;
}