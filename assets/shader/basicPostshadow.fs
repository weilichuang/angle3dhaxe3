uniform sampler2D m_ShadowMap;

uniform vec4 u_BitShifts;

varying vec4 v_ProjCoord;

//rgba to float
void function unpack(vec4 color,float zDistance)
{
	zDistance = dot4(u_BitShifts,color);
}

void function main()
{
	vec4 t_Coord = v_ProjCoord;
	t_Coord.xyz = t_Coord.xyz / t_Coord.w;
	
	//float t_Shadow = step(t_Coord.z, texture2D(t_Coord.xy,m_ShadowMap).r)* 0.7 + 0.3;
	
	//vec4 t_Result.rgb = t_Shadow;
	//t_Result.a = 1.0;
	
	vec4 t_Color = texture2D(t_Coord.xy,m_ShadowMap);
	
	float t_Shadow;
	unpack(t_Color,t_Shadow);
	
	vec4 t_Result.rgb = t_Shadow;
	t_Result.a = 1.0;
	
	output = t_Result;
}