uniform sampler2D s_texture;

temp vec4 t_Diffuse;
temp vec4 t_DiffuseSum;
temp vec4 t_SpecularSum;
temp vec4 t_result;

temp float t_diffuseFactor;
temp float t_specularFactor;
temp vec3 t_normal;
temp vec3 t_lightDir;
temp vec3 t_viewDir;

void function main()
{
	t_Diffuse = texture2D(v_texCoord,s_texture);
	//t_Diffuse = 1.0;
	t_normal = normalize(v_Normal);
	t_lightDir = v_LightDir;
	t_lightDir = normalize(t_lightDir);
	t_viewDir = v_ViewDir;

	//computeDiffuse
	t_diffuseFactor = maxDot(t_normal,t_lightDir,0.0);
	//computeSpecular
	t_specularFactor = computeSpecular(t_normal,t_viewDir,t_lightDir,v_Specular.w);

	//t_specularFactor = mul(t_specularFactor,t_diffuseFactor);
	t_DiffuseSum = mul(v_Diffuse,t_Diffuse);
	t_DiffuseSum = mul(t_DiffuseSum,t_diffuseFactor);
	t_result = add(v_Ambient,t_DiffuseSum);
	t_SpecularSum = mul(v_Specular,t_specularFactor);
	t_result.xyz = add(t_result.xyz,t_SpecularSum.xyz);
	t_result.w = 1.0;
	output = t_result;  
}