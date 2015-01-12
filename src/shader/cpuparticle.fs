uniform sampler2D s_texture;

varying vec4 v_texCoord;
varying vec4 v_color;
void function main()
{
	vec4 t_diffuseColor = texture2D(v_texCoord,s_texture);
	t_diffuseColor = mul(t_diffuseColor,v_color);
	output = t_diffuseColor;
}