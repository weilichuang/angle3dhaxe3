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
	vec4 t_Diffuse;
	vec4 t_DiffuseSum;
	vec4 t_SpecularSum;
	vec4 t_result;

	float t_diffuseFactor;
	float t_specularFactor;
	vec3 t_normal;
	vec3 t_lightDir;
	vec3 t_viewDir;

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