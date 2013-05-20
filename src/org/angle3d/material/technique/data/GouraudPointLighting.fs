uniform sampler2D s_texture;
temp vec4 t_Diffuse;
temp vec4 t_DiffuseSum;
temp vec4 t_result;
void function main(){
	t_Diffuse = texture2D(v_texCoord,s_texture);
	t_Diffuse = 1.0;
	t_DiffuseSum = multiply(v_Diffuse,t_Diffuse);
	t_result = add(v_Ambient,t_DiffuseSum);
	t_result.xyz = add(t_result.xyz,v_Specular.xyz);
	t_result.w = 1.0;
	output = t_result;
}