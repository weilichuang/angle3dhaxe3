uniform sampler2D u_Texture; // this should hold the texture rendered by the horizontal blur pass
uniform vec3 u_SizeScale;

varying vec4 v_TexCoord;

void function main()
{
	// blur in x (vertical)
   // take nine samples, with the distance blurSize between them
   vec4 t_sum;
   vec2 t_TexCoord = v_TexCoord.xy;
   float t_Four = 4.0;
   t_TexCoord.y = v_TexCoord.y - t_Four * u_SizeScale.z;
   t_sum = texture2D(t_TexCoord,u_Texture) * 0.06;
   
   t_TexCoord.y += u_SizeScale.z;
   t_sum += texture2D(t_TexCoord,u_Texture) * 0.09;
   
   t_TexCoord.y += u_SizeScale.z;
   t_sum += texture2D(t_TexCoord,u_Texture) * 0.12;
   
   t_TexCoord.y += u_SizeScale.z;
   t_sum += texture2D(t_TexCoord,u_Texture) * 0.15;
   
   t_TexCoord.y += u_SizeScale.z;
   t_sum += texture2D(t_TexCoord,u_Texture) * 0.16;
   
   t_TexCoord.y += u_SizeScale.z;
   t_sum += texture2D(t_TexCoord,u_Texture) * 0.15;
   
   t_TexCoord.y += u_SizeScale.z;
   t_sum += texture2D(t_TexCoord,u_Texture) * 0.12;
   
   t_TexCoord.y += u_SizeScale.z;
   t_sum += texture2D(t_TexCoord,u_Texture) * 0.09;
   
   t_TexCoord.y += u_SizeScale.z;
   t_sum += texture2D(t_TexCoord,u_Texture) * 0.06;
   
   output = t_sum;
}