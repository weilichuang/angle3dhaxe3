attribute vec3 a_position;
				
uniform mat4 u_ViewMatrix;
uniform mat4 u_ProjectionMatrix;
uniform mat4 u_WorldMatrix;

varying vec4 v_direction;

void function main(){
    vec4 t_temp;
	t_temp.xyz = m33(a_position.xyz,u_ViewMatrix);
	t_temp.w = 1.0;

	output = m44(t_temp,u_ProjectionMatrix);

	t_temp.xyz = m33(a_position.xyz,u_WorldMatrix);
	v_direction = t_temp.xyz;
}