uniform sampler2D u_Texture<clamp,nearest>;

varying vec4 v_TexCoord;

uniform vec3 u_Luminance;

void function main()
{
	vec4 t_Color = texture2D(v_TexCoord.xy,u_Texture);
	t_Color.xyz = dot3(t_Color.xyz,u_Luminance);
	t_Color.w = 1.0;
	output = t_Color;
}