uniform sampler2D u_AlphaMap<clamp,nearest>;
uniform sampler2D u_TexMap1<clamp,nearest>;
uniform sampler2D u_TexMap2<clamp,nearest>;
uniform sampler2D u_TexMap3<clamp,nearest>;

uniform float u_Tex1Scale;
uniform float u_Tex2Scale;
uniform float u_Tex3Scale;

varying vec4 v_TexCoord;

#ifdef(TRI_PLANAR_MAPPING)
{
   varying vec4 v_Vertex;
   varying vec3 v_Normal;
}

void function main()
{
	// get the alpha value at this 2D texture coord
	vec4 t_Alpha = texture2D(v_TexCoord.xy,u_AlphaMap);
	
	v_TexCoord = a_TexCoord;
	
	#ifdef(TRI_PLANAR_MAPPING)
	{
	    // tri-planar texture bending factor for this fragment's normal
	    vec3 t_blending = abs( v_Normal );
		t_blending = (t_blending -0.2) * 0.7;
		t_blending = normalize(max(t_blending, 0.00001));      // Force weights to sum to 1.0 (very important!)
		float t_b = (t_blending.x + t_blending.y + t_blending.z);
		t_blending.xyz /= t_b;

		// texture coords
		vec4 t_coords = v_Vertex;

		vec4 col1 = texture2D( t_coords.yz * u_Tex1Scale, u_TexMap1 );
		vec4 col2 = texture2D( t_coords.xz * u_Tex1Scale, u_TexMap1 );
		vec4 col3 = texture2D( t_coords.xy * u_Tex1Scale, u_TexMap1 );
		// blend the results of the 3 planar projections.
		vec4 t_Tex1 = col1 * t_blending.x + col2 * t_blending.y + col3 * t_blending.z;

		col1 = texture2D( t_coords.yz * u_Tex2Scale, u_TexMap2 );
		col2 = texture2D( t_coords.xz * u_Tex2Scale, u_TexMap2 );
		col3 = texture2D( t_coords.xy * u_Tex2Scale, u_TexMap2 );
		// blend the results of the 3 planar projections.
		vec4 t_Tex2 = col1 * t_blending.x + col2 * t_blending.y + col3 * t_blending.z;

		col1 = texture2D( t_coords.yz * u_Tex3Scale, u_TexMap3 );
		col2 = texture2D( t_coords.xz * u_Tex3Scale, u_TexMap3 );
		col3 = texture2D( t_coords.xy * u_Tex3Scale, u_TexMap3 );
		// blend the results of the 3 planar projections.
		vec4 t_Tex3 = col1 * t_blending.x + col2 * t_blending.y + col3 * t_blending.z;
	}
	#else
	{
		vec4 t_Tex1 = texture2D( m_Tex1, texCoord.xy * u_Tex1Scale ); // Tile
		vec4 t_Tex2 = texture2D( m_Tex2, texCoord.xy * u_Tex2Scale ); // Tile
		vec4 t_Tex3  = texture2D( m_Tex3, texCoord.xy * u_Tex3Scale ); // Tile
	}
	
	vec4 outColor = t_Tex1 * t_Alpha.r; // Red channel
	outColor = mix( outColor, t_Tex2, t_Alpha.g ); // Green channel
	outColor = mix( outColor, t_Tex3, t_Alpha.b ); // Blue channel
	output = outColor;
}