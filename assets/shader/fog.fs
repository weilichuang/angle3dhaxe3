uniform vec4 u_BitShifts;
uniform sampler2D u_Texture;
uniform sampler2D u_DepthTexture;

varying vec4 v_TexCoord;

uniform vec4 u_FogColor;
uniform vec4 u_FogDensity;
uniform vec4 u_FogDistance;

void function main()
{
	vec4 t_Color = texture2D(v_TexCoord.xy,u_DepthTexture);
	float t_fogVal = dot4(u_BitShifts,t_Color);
	
	float t_fDis = u_FogDistance.x;
	float t_depth = 2 / (t_fDis + 1 - t_fogVal * (t_fDis - 1));
	float t_fDensity = u_FogDensity.x;
	float t_fogFactor = exp(-t_fDensity * t_fDensity * t_depth * t_depth * 1.442695);
	t_fogFactor = saturate(t_fogFactor);
	float t_fogFactor1 = 1 - t_fogFactor;
	
	vec4 t_texVal = texture2D(v_TexCoord.xy,u_Texture);
	output = u_FogColor * t_fogFactor + t_texVal * t_fogFactor1;
	
	//t_Color.rgb = t_fogVal;
	//t_Color.a = 1;
	//output = t_Color;
}