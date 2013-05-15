attribute vec3 a_position;
//a_position1.w代表当前点方向，1或者-1
attribute vec4 a_position1;

varying vec4 v_color;

uniform mat4 u_worldViewMatrix;
uniform mat4 u_projectionMatrix;
uniform vec4 u_color;
/*
* 线条的粗细
*/
uniform vec4 u_thickness;

void function main(){
	vec4 t_start = m44(a_position,u_worldViewMatrix);
	vec4 t_end = a_position1;
	t_end.w = 1;
	t_end = m44(t_end,u_worldViewMatrix);
	
	vec3 t_L = sub(t_end.xyz,t_start.xyz);
    vec3 t_sideVec = cross(t_L,t_start.xyz);
	t_sideVec = normalize(t_sideVec);
	
	float t_distance = mul(t_start.z,a_position1.w);
	t_distance = mul(t_distance,u_thickness.x);
	t_sideVec = mul(t_sideVec,t_distance);
	
	t_start = add(t_start,t_sideVec);
	output = m44(t_start,u_projectionMatrix);
	v_color = u_color;
}