attribute vec3 a_position(POSITION);
attribute vec2 a_texCoord(TEXCOORD);
attribute vec3 a_normal(NORMAL);

varying vec4 v_texCoord;
varying vec4 v_refract;

uniform mat4 u_WorldViewProjectionMatrix(WorldViewProjectionMatrix);
uniform mat4 u_worldMatrix(WorldMatrix);
uniform vec4 u_camPosition(CameraPosition);
uniform vec4 u_etaRatio;

void function main()
{
	output = m44(a_position,u_WorldViewProjectionMatrix);

	vec3 t_N = m33(a_normal.xyz,u_worldMatrix);
	t_N = normalize(t_N);

	vec4 t_positionW = m44(a_position,u_worldMatrix);
	vec3 t_I = sub(t_positionW.xyz,u_camPosition.xyz);
    t_I = normalize(t_I);

	v_refract = refract(t_I,t_N,u_etaRatio);
	v_texCoord = a_texCoord;
}