uniform sampler2D s_texture;

varying vec4 v_texCoord;

#ifdef(USE_COLOR || USE_LOCAL_COLOR)
{  
	varying vec4 v_color;
} 
			
void function main()
{
	vec4 t_diffuseColor = texture2D(v_texCoord,s_texture);

	#ifdef(USE_COLOR || USE_LOCAL_COLOR)
	{
		t_diffuseColor = mul(t_diffuseColor,v_color);
	}
	
	/*
	float t_alpha = sub(1,t_diffuseColor.w);
	t_diffuseColor.rgb = mul(t_diffuseColor.rgb,t_alpha);
	t_diffuseColor.a = t_alpha;
	*/
	
	output = t_diffuseColor;
}