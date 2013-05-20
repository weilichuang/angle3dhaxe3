attribute vec3 a_position(POSITION);
attribute vec3 a_color(COLOR);

uniform mat4 u_WorldViewProjectionMatrix(WorldViewProjectionMatrix);
uniform vec4 u_alpha;

varying vec4 v_color;

void function main(){
	output = m44(a_position,u_WorldViewProjectionMatrix);
	v_color.rgb = a_color.rgb;
	v_color.a = u_alpha.x;
}