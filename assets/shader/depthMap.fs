uniform sampler2D u_DepthMap<SGSL_TEXT_FORMAT,clamp,nearest>;
uniform vec4 u_BitShifts;
varying vec4 v_TexCoord;

void function main()
{
	vec4 t_Color = texture2D(v_TexCoord.xy,u_DepthMap);
	t_Color.xyz = dot4(u_BitShifts,t_Color);
	t_Color.w = 1.0;
    output = t_Color;
}