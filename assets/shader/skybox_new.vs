attribute vec3 a_position(POSITION);
attribute vec3 a_normal(NORMAL);
				
uniform mat4 u_ViewMatrix(ViewMatrix);
uniform mat4 u_ProjectionMatrix(ProjectionMatrix);
uniform mat4 u_WorldMatrix(WorldMatrix);

uniform vec4 u_NormalScale;

varying vec4 v_direction;

void function main()
{
	// set w coordinate to 0
    vec4 t_temp;
	t_temp.xyz = a_position.xyz;
	t_temp.w = 0.0;
	
	// compute rotation only for view matrix
	t_temp = m44(t_temp, u_ViewMatrix);
	
	// now find projection
	t_temp.w = 1.0;
	output = m44(t_temp,u_ProjectionMatrix);
	
	vec4 t_scale.xyz = multiply(a_normal.xyz,u_NormalScale.xyz);
	t_scale.w = 0;

	t_temp.xyz = m44(t_scale,u_WorldMatrix);
	v_direction = t_temp;
}