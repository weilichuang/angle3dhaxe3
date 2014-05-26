attribute vec3 a_position(POSITION);
attribute vec2 a_texCoord(TEXCOORD);
  
uniform mat4 u_WorldViewProjectionMatrix(WorldViewProjectionMatrix);

varying vec4 v_texCoord;

void function main(){	
	
	float t_w = clamp(a_position.x,0.0,1.0);
	
	output = m44(a_position,u_WorldViewProjectionMatrix);
	
	v_texCoord = a_texCoord;
}