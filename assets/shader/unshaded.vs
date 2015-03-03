attribute vec3 a_position(POSITION);
attribute vec2 a_texCoord(TEXCOORD);

varying vec4 v_texCoord;

#ifdef(HAS_LIGHTMAP && USETEXCOORD2)
{
   attribute vec2 a_texCoord2(TEXCOORD2);
   varying vec4 v_texCoord2;
}

uniform mat4 u_WorldViewProjectionMatrix(WorldViewProjectionMatrix);

uniform vec4 u_ambientColor;
varying vec4 v_ambientColor;

void function main()
{
	output = m44(a_position,u_WorldViewProjectionMatrix);
	v_texCoord = a_texCoord;
	#ifdef( HAS_LIGHTMAP && USETEXCOORD2)
	{
		v_texCoord2 = a_texCoord2;
	}
	
	v_ambientColor = u_ambientColor;
}