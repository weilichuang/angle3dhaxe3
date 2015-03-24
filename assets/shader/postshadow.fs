varying vec4 v_ProjCoord0;
uniform sampler2D u_ShadowMap0;

#ifdef(NUM_SHADOWMAP_2)
{
	varying vec4 v_ProjCoord1;
	uniform sampler2D u_ShadowMap1;
}

#ifdef(NUM_SHADOWMAP_3)
{
	varying vec4 v_ProjCoord2;
	uniform sampler2D u_ShadowMap2;
}

#ifdef(NUM_SHADOWMAP_4)
{
	varying vec4 v_ProjCoord3;
	uniform sampler2D u_ShadowMap3;
}

#ifdef(POINTLIGHT)
{
	uniform sampler2D u_ShadowMap4;
	uniform sampler2D u_ShadowMap5;
	
    varying vec4 v_ProjCoord4;
    varying vec4 v_ProjCoord5;
    varying vec4 v_WorldPos;
}
#else
{
    #ifndef(PSSM)
	{
        varying vec4 v_LightDot;
    }
}

#ifdef(PSSM || FADE)
{
	varying vec4 v_ShadowPosition;
}

#ifdef(PSSM)
{
	uniform vec4 u_FadeInfo;
}

#ifdef(DISCARD_ALPHA)
{
    #ifdef(COLOR_MAP)
    {
        uniform sampler2D u_ColorMap;
    }
    #elseif(DIFFUSEMAP)   
    {
        uniform sampler2D u_DiffuseMap;
    }
	
    uniform float u_AlphaDiscardThreshold;
	
	#ifdef(COLOR_MAP || DIFFUSEMAP)
    {
		varying vec2 v_TexCoord;
    }
}

void function main()
{
	#ifdef(DISCARD_ALPHA)
	{
		#ifdef(COLOR_MAP)
		{
			float t_Alpha = texture2D(v_TexCoord.xy,u_ColorMap).a;
			kill(t_Alpha - u_AlphaDiscardThreshold);
		}
		#elseif(DIFFUSEMAP)    
		{
			float t_Alpha2 = texture2D(v_TexCoord.xy,u_DiffuseMap).a;
			kill(t_Alpha2 - u_AlphaDiscardThreshold);
		}
	}
	
	float shadow = 1.0;
 
    #ifdef(POINTLIGHT)
	{
            shadow = getPointLightShadows(v_WorldPos, u_LightPos,
                           u_ShadowMap0,u_ShadowMap1,u_ShadowMap2,u_ShadowMap3,u_ShadowMap4,u_ShadowMap5,
                           v_ProjCoord0, v_ProjCoord1, v_ProjCoord2, v_ProjCoord3, v_ProjCoord4, v_ProjCoord5);
	}
    #else
	{
       #ifdef(PSSM)
	   {
            shadow = getDirectionalLightShadows(u_Splits, v_ShadowPosition,
                           u_ShadowMap0,u_ShadowMap1,u_ShadowMap2,u_ShadowMap3,
                           v_ProjCoord0, v_ProjCoord1, v_ProjCoord2, v_ProjCoord3);
	   }
       #else
	   {
            //spotlight
            //if(lightDot < 0.0)
			//{
                //gl_FragColor = 1.0;
            //}
            shadow = getSpotLightShadows(u_ShadowMap0,v_ProjCoord0);
       }
    } 

    #ifdef(FADE)
	{
		shadow = max(0.0,mix(shadow,1.0,(v_ShadowPosition - u_FadeInfo.x) * u_FadeInfo.y));    
    }
    shadow = shadow * u_ShadowIntensity + (1.0 - u_ShadowIntensity);

	vec4 gl_FragColor.rgb = shadow;
	gl_FragColor.a = 1.0;
	
	output = gl_FragColor;
}