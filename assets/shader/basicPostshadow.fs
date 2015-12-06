uniform sampler2D u_ShadowMap<clamp,nearest>;

uniform vec4 u_BitShifts;
uniform vec4 u_ShaderInfo;
uniform vec4 u_LightPos;

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
	
	float t_Depth = t_Coord.z - u_ShaderInfo.x;
	
	vec4 t_Color;
	float t_Shadow;
	
	#ifdef(PCF)
	{
		t_Shadow = u_ShaderInfo.z;
		t_Shadow *= 9;
		
		vec2 t_Offset;
		float t_ShadowDepth;
		
		//-1,-1
		t_Offset.x = t_Coord.x - u_ShaderInfo.w;
		t_Offset.y = t_Coord.y - u_ShaderInfo.w;
		
		t_Color = texture2D(t_Offset,u_ShadowMap);
		t_ShadowDepth = dot4(u_BitShifts,t_Color);
		t_Shadow += step(t_Depth, t_ShadowDepth) * u_ShaderInfo.y;
		
		//0,-1
		t_Offset.x = t_Coord.x;
		t_Offset.y = t_Coord.y - u_ShaderInfo.w;
		
		t_Color = texture2D(t_Offset,u_ShadowMap);
		t_ShadowDepth = dot4(u_BitShifts,t_Color);
		t_Shadow += step(t_Depth, t_ShadowDepth) * u_ShaderInfo.y;
		
		//1,-1
		t_Offset.x = t_Coord.x + u_ShaderInfo.w;
		t_Offset.y = t_Coord.y - u_ShaderInfo.w;
		
		t_Color = texture2D(t_Offset,u_ShadowMap);
		t_ShadowDepth = dot4(u_BitShifts,t_Color);
		t_Shadow += step(t_Depth, t_ShadowDepth) * u_ShaderInfo.y;
		
		//-1,0
		t_Offset.x = t_Coord.x - u_ShaderInfo.w;
		t_Offset.y = t_Coord.y;
		
		t_Color = texture2D(t_Offset,u_ShadowMap);
		t_ShadowDepth = dot4(u_BitShifts,t_Color);
		t_Shadow += step(t_Depth, t_ShadowDepth) * u_ShaderInfo.y;
		
		//0,0
		t_Offset.x = t_Coord.x;
		t_Offset.y = t_Coord.y;
		
		t_Color = texture2D(t_Offset,u_ShadowMap);
		t_ShadowDepth = dot4(u_BitShifts,t_Color);
		t_Shadow += step(t_Depth, t_ShadowDepth) * u_ShaderInfo.y;
		
		//1,0
		t_Offset.x = t_Coord.x + u_ShaderInfo.w;
		t_Offset.y = t_Coord.y;
		
		t_Color = texture2D(t_Offset,u_ShadowMap);
		t_ShadowDepth = dot4(u_BitShifts,t_Color);
		t_Shadow += step(t_Depth, t_ShadowDepth) * u_ShaderInfo.y;
		
		//-1,1
		t_Offset.x = t_Coord.x - u_ShaderInfo.w;
		t_Offset.y = t_Coord.y + u_ShaderInfo.w;
		
		t_Color = texture2D(t_Offset,u_ShadowMap);
		t_ShadowDepth = dot4(u_BitShifts,t_Color);
		t_Shadow += step(t_Depth, t_ShadowDepth) * u_ShaderInfo.y;
		
		//0,1
		t_Offset.x = t_Coord.x;
		t_Offset.y = t_Coord.y + u_ShaderInfo.w;
		
		t_Color = texture2D(t_Offset,u_ShadowMap);
		t_ShadowDepth = dot4(u_BitShifts,t_Color);
		t_Shadow += step(t_Depth, t_ShadowDepth) * u_ShaderInfo.y;
		
		//1,1
		t_Offset.x = t_Coord.x + u_ShaderInfo.w;
		t_Offset.y = t_Coord.y + u_ShaderInfo.w;
		
		t_Color = texture2D(t_Offset,u_ShadowMap);
		t_ShadowDepth = dot4(u_BitShifts,t_Color);
		t_Shadow += step(t_Depth, t_ShadowDepth) * u_ShaderInfo.y;
		
		t_Shadow /= 9;
	}
	#else
	{
		//unpack_depth
		t_Color = texture2D(t_Coord,u_ShadowMap);
		t_Shadow = dot4(u_BitShifts,t_Color);
		t_Shadow = step(t_Depth, t_Shadow) * u_ShaderInfo.y + u_ShaderInfo.z;
	}

	vec4 t_Result.rgb = t_Shadow;
	t_Result.a = 1.0;
	
	output = t_Result;
}