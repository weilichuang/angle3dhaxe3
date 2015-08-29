uniform sampler2D u_Texture;

varying vec4 v_TexCoord;

uniform vec4 u_FadeValue;

void function main()
{
	vec4 t_Color = texture2D(v_TexCoord.xy,u_Texture);

	output = u_FadeValue.x * t_Color;
}