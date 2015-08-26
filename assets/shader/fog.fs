uniform vec4 u_BitShifts;
uniform sampler2D u_Texture;
uniform sampler2D u_DepthTexture;

varying vec4 v_TexCoord;

uniform vec4 u_FogColor;
uniform vec4 u_FogInfo;

void function main()
{
	vec4 t_Color = texture2D(v_TexCoord.xy,u_DepthTexture);
	float t_fogVal = dot4(u_BitShifts,t_Color);

	float t_depth = u_FogInfo.w / (u_FogInfo.y - t_fogVal * u_FogInfo.z);

	float t_fogFactor = exp(u_FogInfo.x * t_depth * t_depth);
	
	t_fogFactor = saturate(t_fogFactor);
	float t_fogFactor1 = 1 - t_fogFactor;
	
	vec4 t_texVal = texture2D(v_TexCoord.xy,u_Texture);
	output = u_FogColor * t_fogFactor1 + t_texVal * t_fogFactor;
}