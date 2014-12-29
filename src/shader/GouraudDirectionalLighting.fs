uniform sampler2D s_texture;

void function main()
{
	vec4 t_Diffuse = texture2D(v_texCoord,s_texture);
	t_Diffuse = 1.0;
	vec4 t_DiffuseSum = multiply(v_Diffuse,t_Diffuse);
	vec4 t_result = add(v_Ambient,t_DiffuseSum);
	t_result.xyz = add(t_result.xyz,v_Specular.xyz);
	t_result.w = 1.0;
	output = t_result;
}