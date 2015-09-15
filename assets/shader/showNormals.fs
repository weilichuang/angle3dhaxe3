varying vec4 v_Normal;

void function main()
{
	vec4 t_Result;
	t_Result.xyz = v_Normal.xyz * 0.5;
	t_Result.xyz += 0.5;
	t_Result.w = 1.0;
	output = t_Result;
}