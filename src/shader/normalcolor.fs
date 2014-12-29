uniform vec4 u_scale;


void function main()
{
	vec4 t_normal;
	vec4 t_color;
	t_normal = mul(v_normal,u_scale);
	t_normal = add(t_normal,u_scale);
	t_color.xyz = t_normal.xyz;
	t_color.w = 1.0;
	output = t_color;
}