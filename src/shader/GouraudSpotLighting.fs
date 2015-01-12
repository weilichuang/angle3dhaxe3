uniform sampler2D s_texture;

varying vec4 v_texCoord;
varying vec4 v_Ambient;
varying vec4 v_Diffuse;
varying vec4 v_Specular;
varying vec4 v_LightDirection;

void function main()
{
	vec4 t_Diffuse;
	vec4 t_DiffuseSum;
	vec4 t_result;
	t_Diffuse = texture2D(v_texCoord,s_texture);
	t_DiffuseSum = multiply(v_Diffuse,t_Diffuse);
	t_result = add(v_Ambient,t_DiffuseSum);
	t_result.xyz = add(t_result.xyz,v_Specular.xyz);
	t_result.w = 1.0;
	output = t_result;
}