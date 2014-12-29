attribute vec3 a_position;
attribute vec3 a_normal;
attribute vec2 a_texCoord;
	  
uniform mat4 u_WorldViewProjectionMatrix;
uniform mat4 u_WorldViewMatrix;
uniform mat3 u_NormalMatrix;
uniform mat4 u_ViewMatrix;
uniform vec4 u_Ambient;
uniform vec4 u_Diffuse;
uniform vec4 u_Specular;
uniform vec4 u_LightColor;
uniform vec4 u_LightPosition;
uniform vec4 u_LightDirection;
		  
varying vec4 v_texCoord;
varying vec4 v_Ambient;
varying vec4 v_Diffuse;
varying vec4 v_Specular;
varying vec4 v_LightDirection;

void function main()
{
	vec4 t_color;
	vec4 t_wvPosition;
	vec4 t_wvLightPos;
	vec3 t_wvNormal;
	vec3 t_viewDir;
	vec3 t_lightDir;
	float t_lightDist;
	float t_invDist;
	float t_spotFallOff;
	float t_diffuseFactor;
	float t_specularFactor;
	vec3 t_L;
	vec3 t_spotdir;
	float t_curAngleCos;
	float t_innerAngleCos;
	float t_outerAngleCos;
	float t_innerMinusOuter;

	output = m44(a_position,u_WorldViewProjectionMatrix);

	t_wvPosition = m44(a_position,u_WorldViewMatrix);
	t_wvNormal = m33(a_normal,u_NormalMatrix);
	t_wvNormal = normalize(t_wvNormal);
			  
	//viewDir = normalize(-wvPosition)
	t_viewDir = negate(t_wvPosition); 
	t_viewDir = normalize(t_viewDir);
			  
	t_wvLightPos = u_LightPosition;
	//方向光时为0，其他情况为1
	//t_wvLightPos.w = u_LightColor.w;
	//t_wvLightPos.w = clamp(t_wvLightPos.w,0.0,1.0);
	t_wvLightPos.w = 1.0;
	t_wvLightPos = m44(t_wvLightPos,u_ViewMatrix);
	t_wvLightPos.w = u_LightPosition.w;
			  
	//lights in world space
	t_lightDir.xyz = sub(t_wvLightPos.xyz,t_wvPosition.xyz);
	t_lightDist = length3(t_lightDir.xyz);

	//t_invDist = clamp(1.0 - t_wvLightPos.w * t_lightDist, 0.0, 1.0)
	t_invDist = mul(t_wvLightPos.w,t_lightDist);
	t_invDist = sub(1.0,t_invDist);
	t_invDist = clamp(t_invDist,0.0,1.0);

	t_lightDir.xyz = divide(t_lightDir.xyz,t_lightDist);

	//compute spotFallOff
	t_spotdir.xyz = u_LightDirection.xyz;
	t_spotdir = normalize(t_spotdir);
	t_L = normalize(t_lightDir);
	t_L = negate(t_L);
	t_curAngleCos = dot3(t_L,t_spotdir);
	t_innerAngleCos = u_LightDirection.w;
	t_innerAngleCos = floor(t_innerAngleCos);
	t_innerAngleCos = mul(t_innerAngleCos,0.001);
	t_outerAngleCos = u_LightDirection.w;
	t_outerAngleCos = fract(t_outerAngleCos);
	t_innerMinusOuter = sub(t_innerAngleCos,t_outerAngleCos);
	t_spotFallOff = sub(t_curAngleCos,t_outerAngleCos);
	t_spotFallOff = divide(t_spotFallOff,t_innerMinusOuter);
	t_spotFallOff = clamp(t_spotFallOff,0.0,1.0);

	//乘以t_spotFallOff
	t_invDist = mul(t_invDist,t_spotFallOff);

	//computeDiffuse
	t_diffuseFactor = maxDot(t_wvNormal,t_lightDir,0.0);
	//根据距离衰减
	t_diffuseFactor = mul(t_diffuseFactor,t_invDist);
	//computeSpecular
	t_specularFactor = computeSpecular(t_wvNormal,t_viewDir,t_lightDir,u_Specular.w);
	//根据距离衰减
	t_specularFactor = mul(t_specularFactor,t_invDist);

	t_color = u_Diffuse;
	t_color = mul(t_color,u_LightColor);
	t_color.xyz = mul(t_color.xyz,t_diffuseFactor);
	v_Diffuse = t_color;
			  
	t_color = u_Specular;
	t_color.w = 1.0;
	t_color.xyz = mul(t_color.xyz,u_LightColor.xyz);
	t_color.xyz = mul(t_color.xyz,t_specularFactor);
	v_Specular = t_color;
			  
	v_texCoord = a_texCoord;
	v_Ambient = u_Ambient;
}