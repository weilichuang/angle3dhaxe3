uniform vec4 u_BitShifts;
uniform sampler2D u_Texture<clamp,nearest>;
uniform sampler2D u_DepthTexture<clamp,nearest>;

varying vec4 v_TexCoord;

uniform vec4 u_DofInfo;
uniform vec4 u_NearFar;

void function main()
{
	vec4 t_Color = texture2D(v_TexCoord.xy,u_DepthTexture);
	float t_zBuffer = dot4(u_BitShifts,t_Color);
	t_zBuffer = u_NearFar.y / (t_zBuffer - u_NearFar.x);

	float t_unfocus = min(u_NearFar.z, abs(t_zBuffer - u_DofInfo.x ) / u_DofInfo.y );
	
	vec4 t_sum;
	
	vec2 t_tex;
	float t_2 = u_NearFar.z;
	float t_sx2 = t_2 * u_DofInfo.z;
	float t_sy2 = t_2 * u_DofInfo.w;
	vec2 t_sxy2 = t_2 * u_DofInfo.zw;
	
	//-2.0,-2.0
	t_tex.xy = v_TexCoord.xy - t_sxy2;
	t_sum = texture2D(t_tex,u_Texture);
	//-0.0,-2.0
	t_tex.x = v_TexCoord.x;
	t_tex.y = v_TexCoord.y - t_sy2;
	t_sum += texture2D(t_tex,u_Texture);
	//+2.0,-2.0
	t_tex.x = v_TexCoord.x + t_sx2;
	t_tex.y = v_TexCoord.y - t_sy2;
	t_sum += texture2D(t_tex,u_Texture);
	//-1.0,-1.0
	t_tex.xy = v_TexCoord.xy - u_DofInfo.zw;
	t_sum += texture2D(t_tex,u_Texture);
	//+1.0,-1.0
	t_tex.x = v_TexCoord.x + u_DofInfo.z;
	t_tex.y = v_TexCoord.y - u_DofInfo.w;
	t_sum += texture2D(t_tex,u_Texture);
	//-2.0,-0.0
	t_tex.x = v_TexCoord.x - t_sx2;
	t_tex.y = v_TexCoord.y;
	t_sum += texture2D(t_tex,u_Texture);
	//+2.0,-0.0
	t_tex.x = v_TexCoord.x + t_sx2;
	t_tex.y = v_TexCoord.y;
	t_sum += texture2D(t_tex,u_Texture);
	//-1.0,+1.0
	t_tex.x = v_TexCoord.x - u_DofInfo.z;
	t_tex.y = v_TexCoord.y + u_DofInfo.w;
	t_sum += texture2D(t_tex,u_Texture);
	//+1.0,+1.0
	t_tex.xy = v_TexCoord.xy + u_DofInfo.zw;
	t_sum += texture2D(t_tex,u_Texture);
	//-2.0,+2.0
	t_tex.x = v_TexCoord.x - t_sx2;
	t_tex.y = v_TexCoord.y + t_sy2;
	t_sum += texture2D(t_tex,u_Texture);
	//-0.0,+2.0
	t_tex.x = v_TexCoord.x;
	t_tex.y = v_TexCoord.y + t_sy2;
	t_sum += texture2D(t_tex,u_Texture);
	//+2.0,+2.0
	t_tex.xy = v_TexCoord.xy + t_sxy2;
	t_sum += texture2D(t_tex,u_Texture);
	
	t_sum *= u_NearFar.w;
	
	float t_unfocus1 = 1 - t_unfocus;
	vec4 t_texVal = texture2D(v_TexCoord.xy,u_Texture);
	output = t_texVal * t_unfocus1 + t_sum * t_unfocus;
}