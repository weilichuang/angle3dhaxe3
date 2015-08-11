attribute vec3 a_Position(POSITION);
attribute vec2 a_TexCoord(TEXCOORD);
	
varying vec4 v_TexCoord;

void function main()
{
    vec4 t_Pos.xy = a_Position.xy * 2.0 - 1.0;
	t_Pos.z = 0.0;
	t_Pos.w = 1.0;

	output = t_Pos;
	v_TexCoord = a_TexCoord;
}