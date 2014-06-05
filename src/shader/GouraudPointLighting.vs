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

temp vec4 t_color;
temp vec4 t_wvPosition;
temp vec4 t_wvLightPos;
temp vec3 t_wvNormal;
temp vec3 t_viewDir;
temp vec3 t_lightDir;
temp float t_lightDist;
temp float t_invDist;
temp float t_diffuseFactor;
temp float t_specularFactor;

void function main()
{
	output = m44(a_position,u_WorldViewProjectionMatrix);

	t_wvPosition = m44(a_position,u_WorldViewMatrix);

	t_wvNormal = m33(a_normal,u_NormalMatrix);
	t_wvNormal = normalize(t_wvNormal);
			  
	//t_viewDir = normalize(-t_wvPosition)
	t_viewDir = negate(t_wvPosition); 
	t_viewDir = normalize(t_viewDir);
			  
	t_wvLightPos = u_LightPosition;
	//方向光时为0，其他情况为1
	//t_wvLightPos.w = u_LightColor.w;
	//t_wvLightPos.w = notEqual(u_LightColor.w,0.0);
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

	//computeDiffuse
	t_diffuseFactor = maxDot(t_wvNormal,t_lightDir,0.0);

	//computeSpecular
	t_specularFactor = computeSpecular(t_wvNormal,t_viewDir,t_lightDir,u_Specular.w);

	//根据距离衰减
	t_diffuseFactor = mul(t_diffuseFactor,t_invDist);
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