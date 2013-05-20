uniform sampler2D s_texture;
temp vec4 t_Diffuse;
temp vec4 t_DiffuseSum;
temp vec4 t_SpecularSum;
temp vec4 t_result;

temp float t_diffuseFactor;
temp float t_specularFactor;
temp vec3 t_normal;
temp vec4 t_lightDir;
temp vec3 t_viewDir;

temp float t_spotFallOff;
temp vec3 t_L;
temp vec3 t_spotdir;
temp float t_curAngleCos;
temp float t_innerAngleCos;
temp float t_outerAngleCos;
temp float t_innerMinusOuter;

void function main(){
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