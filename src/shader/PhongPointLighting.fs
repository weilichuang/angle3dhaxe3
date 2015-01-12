uniform sampler2D s_texture;

varying vec4 v_texCoord;
varying vec4 v_Ambient;
varying vec4 v_Diffuse;
varying vec4 v_Specular;
varying vec4 v_Normal;
varying vec4 v_ViewDir;
varying vec4 v_LightDir;

void function main()
{
	vec4 t_Diffuse = texture2D(v_texCoord,s_texture,ignore);
	vec3 t_normal = normalize(v_Normal);
	vec4 t_lightDir = v_LightDir;
	t_lightDir.xyz = normalize(t_lightDir.xyz);
	vec3 t_viewDir = v_ViewDir;

	//computeDiffuse
	float t_diffuseFactor = maxDot(t_normal,t_lightDir,0.0);
	//根据距离衰减
	t_diffuseFactor = mul(t_diffuseFactor,t_lightDir.w);
	//computeSpecular
	float t_specularFactor = computeSpecular(t_normal,t_viewDir,t_lightDir,v_Specular.w);
	//t_specularFactor = mul(t_specularFactor,t_diffuseFactor);
	//根据距离衰减
	t_specularFactor = mul(t_specularFactor,t_lightDir.w);

	vec4 t_DiffuseSum = mul(v_Diffuse,t_Diffuse);
	t_DiffuseSum = mul(t_DiffuseSum,t_diffuseFactor);
	vec4 t_result = add(v_Ambient,t_DiffuseSum);
	vec4 t_SpecularSum = mul(v_Specular,t_specularFactor);
	t_result.xyz = add(t_result.xyz,t_SpecularSum.xyz);
	t_result.w = 1.0;

	output = t_result; 
}