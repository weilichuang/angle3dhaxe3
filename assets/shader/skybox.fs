uniform samplerCube t_cubeTexture<SGSL_TEXT_FORMAT,clamp,nearest>;

varying vec4 v_direction;
void function main()
{
	vec3 t_dir = normalize(v_direction.xyz);
	output = textureCube(t_dir,t_cubeTexture);
}