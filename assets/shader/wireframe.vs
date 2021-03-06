attribute vec3 a_position(POSITION);
//a_position1.w代表当前点方向，1或者-1
attribute vec4 a_position1(POSITION1);

#ifdef(USE_VERTEX_COLOR)
{
	attribute vec3 a_color(COLOR);
}
#else 
{
	uniform vec4 u_color;
}

uniform mat4 u_worldViewMatrix(WorldViewMatrix);
uniform mat4 u_projectionMatrix(ProjectionMatrix);

/*
* 线条的粗细
*/
uniform vec4 u_thickness;

varying vec4 v_color;

void function main()
{
	vec4 t_start = m44(a_position,u_worldViewMatrix);
	vec4 t_end = a_position1;
	t_end.w = 1;
	t_end = m44(t_end,u_worldViewMatrix);
	
	vec3 t_L = t_end.xyz - t_start.xyz;
    vec3 t_sideVec = crossProduct(t_L,t_start.xyz);
	t_sideVec = normalize(t_sideVec);
	
	float t_distance = t_start.z * a_position1.w;
	t_distance *= u_thickness.x;
	t_sideVec *= t_distance;
	
	t_start = t_start + t_sideVec;
	output = m44(t_start,u_projectionMatrix);
	
	#ifdef(USE_VERTEX_COLOR)
	{
		v_color = a_color;
	}
	#else 
	{
		v_color = u_color;
	}
}