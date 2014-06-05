uniform samplerCube t_cubeTexture;
void function main()
{
	//vec3 t_dir = normalize(v_direction.xyz);
	output = textureCube(v_direction,t_cubeTexture);
}