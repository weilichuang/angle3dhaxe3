uniform sampler2D m_ShadowMap;

uniform vec4 u_BitShifts;
uniform vec4 u_BiasMultiplier;

varying vec4 v_ProjCoord;

//rgba to float
//void function unpack(vec4 color,float zDistance)
//{
	//zDistance = dot4(u_BitShifts,color);
//}

void function main()
{
	vec3 t_Coord.xyz = v_ProjCoord.xyz / v_ProjCoord.w;
	
	t_Coord.y = 1 - t_Coord.y;

	vec4 t_Color = texture2D(t_Coord,m_ShadowMap);
	
	//unpack_depth
	float t_Shadow = dot4(u_BitShifts,t_Color);
	
	t_Coord.z = t_Coord.z * u_BiasMultiplier.x;
	t_Shadow = step(t_Coord.z, t_Shadow) * 0.5 + 0.5;

	vec4 t_Result.rgb = t_Shadow;
	t_Result.a = 1.0;
	
	output = t_Result;
}