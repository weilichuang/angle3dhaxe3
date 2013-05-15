attribute vec3 a_position;
attribute vec2 a_texCoord;
attribute vec4 a_color;

varying vec4 v_texCoord;
varying vec4 v_color;

uniform mat4 u_WorldViewProjectionMatrix;

void function main(){
	output = m44(a_position,u_WorldViewProjectionMatrix);
	v_texCoord = a_texCoord;
	v_color = a_color;
}