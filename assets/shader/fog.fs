uniform vec4 u_BitShifts;
uniform sampler2D u_Texture;
uniform sampler2D u_DepthTexture;

varying vec4 v_TexCoord;

uniform vec4 u_FogColor;
uniform vec4 u_FogDensity;
uniform vec4 u_FogDistance;

void function main()
{
	vec4 t_texVal = texture2D(v_TexCoord,u_Texture);
	
	vec4 t_Color = texture2D(v_TexCoord,u_DepthTexture);
	float t_fogVal = dot4(u_BitShifts,t_Color);
	
	float t_depth = 2 / (u_FogDistance.x + 1 - t_fogVal * (u_FogDistance - 1));
	float t_fogFactor = exp(-u_FogDensity * u_FogDensity * t_depth * t_depth * 1.442695);
	t_fogFactor = saturate(t_fogFactor);
	//t_fogFactor = 0.5;
	float t_fogFactor1 = 1 - t_fogFactor;
	
	vec4 gl_FragColor;
	gl_FragColor = u_FogColor * t_fogFactor + t_texVal * t_fogFactor1;
	gl_FragColor = t_texVal;
	
	output = 1.0;//gl_FragColor;
}