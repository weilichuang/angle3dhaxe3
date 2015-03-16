uniform sampler2D m_ShadowMap;

varying vec4 v_ProjCoord;

void function main()
{
	vec4 t_Coord = v_ProjCoord;
	t_Coord.xyz = t_Coord.xyz / t_Coord.w;
	
	float t_Shadow = step(t_Coord.z, texture2D(t_Coord.xy,m_ShadowMap).r)* 0.7 + 0.3;
	
	vec4 t_Result.rgb = t_Shadow;
	t_Result.a = 1.0;
	
	output = t_Result;
}