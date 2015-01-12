uniform vec4 u_transmittance;
uniform sampler2D u_decalMap;
uniform samplerCube u_environmentMap;

varying vec4 v_texCoord;
varying vec4 v_refract;

vec4 function lerp(vec4 source1,vec4 source2,float percent)
{
	float t_percent1 = percent;
	t_percent1 = sub(1.0,t_percent1);
	vec4 t_local1 = mul(source1,t_percent1);
	vec4 t_local2 = mul(source2,percent);
	return add(t_local1,t_local2);
}

void function main()
{
	vec4 t_reflectedColor = textureCube(v_refract,u_environmentMap);
	vec4 t_decalColor = texture2D(v_texCoord,u_decalMap);
	output = lerp(t_decalColor,t_reflectedColor,u_transmittance.x);
}