uniform sampler2D s_texture;

varying vec4 v_texCoord;

void function main()
{
	vec4 t_Diffuse = texture2D(v_texCoord,s_texture,ignore);
	output = t_Diffuse; 
}