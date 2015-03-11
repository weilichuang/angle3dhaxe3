attribute vec3 a_Position(POSITION);
attribute vec2 a_TexCoord(TEXCOORD);
attribute vec4 a_Color(COLOR);

varying vec2 v_TexCoord;
varying vec4 v_Color;

uniform mat4 u_WorldViewProjectionMatrix(WorldViewProjectionMatrix);

void function main()
{
	output = m44(a_Position,u_WorldViewProjectionMatrix);
	v_TexCoord = a_TexCoord;
	v_Color = a_Color;
}