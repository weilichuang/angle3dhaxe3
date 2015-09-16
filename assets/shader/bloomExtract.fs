#ifdef(DO_EXTRACT){
	uniform sampler2D u_Texture;
}

uniform vec2 u_Exposure;

#ifdef(HAS_GLOWMAP)
{
	uniform sampler2D u_GlowMap;
}

varying vec4 v_TexCoord;

void function main()
{
	vec4 t_Color = 0;
	
	#ifdef(DO_EXTRACT)
	{
		t_Color = texture2D(v_TexCoord,u_Texture);
		float t_CutOff = lessThan((t_Color.r+t_Color.g+t_Color.b)/3.0,u_Exposure.y);
		vec4 t_Pow1 = u_Exposure.x;
		t_Color = pow(t_Color,t_Pow1);
		t_Color *= t_CutOff;
	}
	
	#ifdef(HAS_GLOWMAP)
	{
		vec4 t_GlowColor = texture2D(v_TexCoord,u_GlowMap);
		vec4 t_Pow2 = u_Exposure.x;
		t_GlowColor = pow(t_GlowColor,t_Pow2);
		t_Color += t_GlowColor;
	}
	
	output = t_Color;
}