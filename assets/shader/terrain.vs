attribute vec3 a_Position(POSITION);
attribute vec2 a_TexCoord(TEXCOORD);

varying vec4 v_TexCoord;

#ifdef(TRI_PLANAR_MAPPING)
{
   attribute vec3 a_Normal(NORMAL);
   varying vec3 v_Vertex;
   varying vec3 v_Normal;
}

uniform mat4 u_WorldViewProjectionMatrix(WorldViewProjectionMatrix);

void function main()
{
	vec4 t_ModelSpacePos.xyz = a_Position;
	t_ModelSpacePos.w = 1.0;
	output = t_ModelSpacePos * u_WorldViewProjectionMatrix;
	
	v_TexCoord = a_TexCoord;
	
	#ifdef(TRI_PLANAR_MAPPING)
	{
	   v_Vertex = a_Position;
	   v_Normal = a_Normal;
	}
}