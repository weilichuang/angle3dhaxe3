attribute vec3 a_position(POSITION);
attribute vec3 a_normal(NORMAL);
attribute vec2 a_texCoord(TEXCOORD);
	  
uniform mat4 u_WorldViewProjectionMatrix(WorldViewProjectionMatrix);
uniform mat4 u_WorldViewMatrix(WorldViewMatrix);
uniform mat3 u_NormalMatrix(NormalMatrix);
uniform mat4 u_ViewMatrix(ViewMatrix);

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
varying vec4 v_Normal;
varying vec4 v_ViewDir;
varying vec4 v_LightDir;

temp vec4 t_color;
temp vec4 t_wvPosition;
temp vec4 t_wvLightPos;
temp vec3 t_wvNormal;
temp vec3 t_viewDir;
temp vec4 t_lightDir;
temp float t_lightDist;

void function main(){	
	
	output = m44(a_position,u_WorldViewProjectionMatrix);

	t_wvPosition = m44(a_position,u_WorldViewMatrix);

	t_wvNormal = m33(a_normal,u_NormalMatrix);
	t_wvNormal = normalize(t_wvNormal);
			  
	//viewDir = normalize(-wvPosition)
	t_viewDir = negate(t_wvPosition.xyz); 
	t_viewDir = normalize(t_viewDir);
			  
	t_wvLightPos = u_LightPosition;
	//方向光时为0，其他情况为1
	t_wvLightPos.w = 1.0;
	t_wvLightPos = m44(t_wvLightPos,u_ViewMatrix);
	t_wvLightPos.w = u_LightPosition.w;
			  
	//lights in world space
	t_lightDir.xyz = sub(t_wvLightPos.xyz,t_wvPosition.xyz);

	t_lightDist = length3(t_lightDir.xyz);

	t_lightDir.xyz = divide(t_lightDir.xyz,t_lightDist);

	t_lightDist = mul(t_wvLightPos.w,t_lightDist);
	t_lightDist = sub(1.0,t_lightDist);
	//自定义函数中传入常量解析时出问题了
	//t_lightDir.w = clamp(t_lightDist,0.0,1.0);
	t_lightDir.w = max(t_lightDist,0.0);
	t_lightDir.w = min(t_lightDir.w,1.0);

	t_color = u_Diffuse;
	t_color = mul(t_color,u_LightColor);
	v_Diffuse = t_color;
			  
	t_color = u_Specular;
	t_color.rgb = mul(t_color.rgb,u_LightColor.rgb);
	v_Specular = t_color;

	v_Normal = t_wvNormal;	
	v_ViewDir = t_viewDir;
	v_LightDir = t_lightDir;
	v_texCoord = a_texCoord;
	v_Ambient = u_Ambient;
}