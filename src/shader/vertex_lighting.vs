attribute vec3 a_position;
attribute vec3 a_normal;
attribute vec2 a_texCoord;
	  
uniform mat4 u_WorldViewProjectionMatrix;
uniform mat4 u_WorldViewMatrix;
uniform mat3 u_NormalMatrix;
uniform mat4 u_ViewMatrix;
uniform vec4 u_Ambient;
uniform vec4 u_Diffuse;
uniform vec4 u_Specular;
uniform vec4 u_LightColor;
uniform vec4 u_LightPosition;
uniform vec4 u_LightDirection;
		  
varying vec2 v_texCoord;
varying vec4 v_Ambient;
varying vec4 v_Diffuse;
varying vec4 v_Specular;
varying vec3 v_Normal;
varying vec3 v_ViewDir;
varying vec4 v_LightDir;
varying vec4 v_LightDirection;

void function main(){	
	
}