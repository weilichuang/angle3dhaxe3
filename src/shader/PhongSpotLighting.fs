uniform sampler2D s_texture;

void function main()
{
	vec4 t_Diffuse;
	vec4 t_DiffuseSum;
	vec4 t_SpecularSum;
	vec4 t_result;

	float t_diffuseFactor;
	float t_specularFactor;
	vec3 t_normal;
	vec4 t_lightDir;
	vec3 t_viewDir;

	float t_spotFallOff;
	vec3 t_L;
	vec3 t_spotdir;
	float t_curAngleCos;
	float t_innerAngleCos;
	float t_outerAngleCos;
	float t_innerMinusOuter;

	t_Diffuse = texture2D(v_texCoord,s_texture);
	//t_Diffuse = 1.0;
	t_normal = normalize(v_Normal);
	t_lightDir = v_LightDir;
	t_lightDir.xyz = normalize(t_lightDir.xyz);
	t_viewDir = v_ViewDir;

	//compute spotFallOff
	t_spotdir.xyz = v_LightDirection.xyz;
	t_spotdir = normalize(t_spotdir);
	t_L = t_lightDir.xyz;
	t_L = negate(t_L);
	t_curAngleCos = dot3(t_L,t_spotdir);
	t_innerAngleCos = v_LightDirection.w;
	t_innerAngleCos = floor(t_innerAngleCos);
	t_innerAngleCos = mul(t_innerAngleCos,0.001);
	t_outerAngleCos = v_LightDirection.w;
	t_outerAngleCos = fract(t_outerAngleCos);
	t_innerMinusOuter = sub(t_innerAngleCos,t_outerAngleCos);
	t_spotFallOff = sub(t_curAngleCos,t_outerAngleCos);
	t_spotFallOff = divide(t_spotFallOff,t_innerMinusOuter);
	t_spotFallOff = clamp(t_spotFallOff,0.0,1.0);

	t_lightDir.w = mul(t_lightDir.w,t_spotFallOff);

	//computeDiffuse
	t_diffuseFactor = maxDot(t_normal,t_lightDir,0.0);
	//根据距离衰减
	t_diffuseFactor = mul(t_diffuseFactor,t_lightDir.w);
	//computeSpecular
	t_specularFactor = computeSpecular(t_normal,t_viewDir,t_lightDir,v_Specular.w);
	//根据距离衰减
	t_specularFactor = mul(t_specularFactor,t_lightDir.w);


	t_DiffuseSum = mul(v_Diffuse,t_Diffuse);
	t_DiffuseSum = mul(t_DiffuseSum,t_diffuseFactor);

	t_result = add(v_Ambient,t_DiffuseSum);
	t_SpecularSum = mul(v_Specular,t_specularFactor);
	t_result.xyz = add(t_result.xyz,t_SpecularSum.xyz);
	t_result.w = 1.0;
	output = t_result; 
} 