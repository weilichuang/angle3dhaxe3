uniform samplerCube t_cubeTexture;

varying vec4 v_direction;

void function main()
{
	//vec3 t_dir = normalize(v_direction.xyz);
	output = textureCube(v_direction,t_cubeTexture);
}