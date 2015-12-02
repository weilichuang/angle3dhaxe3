uniform sampler2D u_DiffuseMap<SGSL_TEXT_FORMAT,clamp,nearest>;

varying vec2 v_TexCoord;
varying vec4 v_Color;
void function main()
{
	output = v_Color * texture2D(v_TexCoord.xy,u_DiffuseMap);
}