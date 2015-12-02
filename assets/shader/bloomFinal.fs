uniform sampler2D u_Texture<SGSL_TEXT_FORMAT,clamp,nearest>;
uniform sampler2D u_BloomTex<SGSL_TEXT_FORMAT,clamp,nearest>;
uniform float u_BloomIntensity;

varying vec4 v_TexCoord;

void function main()
{
	vec4 t_ColorRes = texture2D(v_TexCoord,u_Texture);
	vec4 t_Bloom = texture2D(v_TexCoord,u_BloomTex);
	output = t_Bloom * u_BloomIntensity.x + t_ColorRes;
}