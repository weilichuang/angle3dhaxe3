uniform sampler2D u_DiffuseMap<SGSL_TEXT_FORMAT,clamp,nearest>;

varying vec4 v_TexCoord;

#ifdef(USE_COLOR || USE_LOCAL_COLOR)
{  
	varying vec4 v_Color;
} 
			
void function main()
{
	vec4 t_DiffuseColor = texture2D(v_TexCoord,u_DiffuseMap);

	#ifdef(USE_COLOR || USE_LOCAL_COLOR)
	{
		t_DiffuseColor = t_DiffuseColor * v_Color;
	}
	
	/*
	float t_alpha = sub(1,t_diffuseColor.w);
	t_diffuseColor.rgb = mul(t_diffuseColor.rgb,t_alpha);
	t_diffuseColor.a = t_alpha;
	*/
	
	output = t_DiffuseColor;
}