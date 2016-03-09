uniform sampler2D u_AlphaMap<linear>;
uniform sampler2D u_TexMap1<linear>;
uniform sampler2D u_TexMap2<linear>;
uniform sampler2D u_TexMap3<linear>;

uniform float u_TexScale1;
uniform float u_TexScale2;
uniform float u_TexScale3;

varying vec4 v_TexCoord;

#ifdef(TRI_PLANAR_MAPPING)
{
   varying vec4 v_Vertex;
   varying vec3 v_Normal;
}

void function main()
{
	#ifdef(TRI_PLANAR_MAPPING)
	{
	    // tri-planar texture bending factor for this fragment's normal
	    vec3 t_Blending = abs( v_Normal );
		vec3 t_2 = 0.2;
		t_Blending = (t_Blending - t_2) * 0.7;
		vec3 t_00001 = 0.00001;
		t_Blending = normalize(max(t_Blending, t_00001));      // Force weights to sum to 1.0 (very important!)
		float t_B = (t_Blending.x + t_Blending.y + t_Blending.z);
		t_Blending.xyz /= t_B;

		vec4 t_Col1 = texture2D( v_Vertex.yz * u_TexScale1.x, u_TexMap1 );
		vec4 t_Col2 = texture2D( v_Vertex.xz * u_TexScale1.x, u_TexMap1 );
		vec4 t_Col3 = texture2D( v_Vertex.xy * u_TexScale1.x, u_TexMap1 );
		// blend the results of the 3 planar projections.
		vec4 t_Tex1 = t_Col1 * t_Blending.x + t_Col2 * t_Blending.y + t_Col3 * t_Blending.z;

		t_Col1 = texture2D( v_Vertex.yz * u_TexScale2.x, u_TexMap2 );
		t_Col2 = texture2D( v_Vertex.xz * u_TexScale2.x, u_TexMap2 );
		t_Col3 = texture2D( v_Vertex.xy * u_TexScale2.x, u_TexMap2 );
		// blend the results of the 3 planar projections.
		vec4 t_Tex2 = t_Col1 * t_Blending.x + t_Col2 * t_Blending.y + t_Col3 * t_Blending.z;

		t_Col1 = texture2D( v_Vertex.yz * u_TexScale3.x, u_TexMap3 );
		t_Col2 = texture2D( v_Vertex.xz * u_TexScale3.x, u_TexMap3 );
		t_Col3 = texture2D( v_Vertex.xy * u_TexScale3.x, u_TexMap3 );
		// blend the results of the 3 planar projections.
		vec4 t_Tex3 = t_Col1 * t_Blending.x + t_Col2 * t_Blending.y + t_Col3 * t_Blending.z;
	}
	#else
	{
		vec4 t_Tex1 = texture2D(v_TexCoord.xy * u_TexScale1.x, u_TexMap1 ); // Tile
		vec4 t_Tex2 = texture2D(v_TexCoord.xy * u_TexScale2.x, u_TexMap2 ); // Tile
		vec4 t_Tex3  = texture2D(v_TexCoord.xy * u_TexScale3.x, u_TexMap3 ); // Tile
	}
	
	// get the alpha value at this 2D texture coord
	vec4 t_Alpha = texture2D(v_TexCoord.xy,u_AlphaMap);
	vec4 outColor = t_Tex1 * t_Alpha.r; // Red channel
	outColor = lerp( outColor, t_Tex2, t_Alpha.g ); // Green channel
	outColor = lerp( outColor, t_Tex3, t_Alpha.b ); // Blue channel
	output = outColor;
}