attribute vec3 a_position(POSITION);
attribute vec2 a_texCoord(TEXCOORD);
attribute vec4 a_color(COLOR);

varying vec4 v_texCoord;
varying vec4 v_color;

uniform mat4 u_WorldViewProjectionMatrix(WorldViewProjectionMatrix);

void function main()
{
	output = m44(a_position,u_WorldViewProjectionMatrix);
	v_texCoord = a_texCoord;
	v_color = a_color;
}