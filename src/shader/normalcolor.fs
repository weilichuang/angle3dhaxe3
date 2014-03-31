uniform vec4 u_scale;
temp vec4 t_normal;
temp vec4 t_color;

void function main()
{
	t_normal = mul(v_normal,u_scale);
	t_normal = add(t_normal,u_scale);
	t_color.xyz = t_normal.xyz;
	t_color.w = 1.0;
	output = t_color;
}