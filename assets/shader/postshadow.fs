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
	uniform vec4 u_LightPos;
	
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
	uniform float u_AlphaDiscardThreshold;
	
    #ifdef(COLOR_MAP)
    {
        uniform sampler2D u_ColorMap;
		varying vec2 v_TexCoord;
    }
}

float function GETSHADOW(sampler2D texture,vec4 projCoord)
{
	vec3 t_Coord.xyz = projCoord.xyz / projCoord.w;
	t_Coord.y = 1 - t_Coord.y;
	
	float t_Depth = t_Coord.z * u_BiasMultiplier.x;
	
	vec4 t_Color = texture2D(t_Coord,texture);
	//unpack_depth
	float t_Shadow = dot4(u_BitShifts,t_Color);
	
	return step(t_Depth, t_Shadow) * 0.5 + 0.5;
	
	//#ifdef(FILTER_MODE == 0)
	//{
		//
	//}
	//#elseif(FILTER_MODE == 1)
	//{
	//}
	//#elseif(FILTER_MODE == 2)
	//{
	//}
	//#elseif(FILTER_MODE == 3)
	//{
	//}
}

void function main()
{
	#ifdef(DISCARD_ALPHA && COLOR_MAP)
	{
		float t_Alpha = texture2D(v_TexCoord.xy,u_ColorMap).a;
		kill(t_Alpha - u_AlphaDiscardThreshold);
	}
	
	float t_Shadow = 1.0;
 
    #ifdef(POINTLIGHT)
	{
        vec3 t_Vect = v_WorldPos.xyz - u_LightPos.xyz;
        vec3 t_Absv = abs(t_Vect);
        float t_MaxComp = max(t_Absv.x,max(t_Absv.y,t_Absv.z));
        if(t_MaxComp == t_Absv.y)
		{
            if(t_Absv.y < 0.0)
		    {
                t_Shadow = GETSHADOW(u_ShadowMap0, v_ProjCoord0 / v_ProjCoord0.w);
            }
		    else
		    {
                t_Shadow = GETSHADOW(u_ShadowMap1, v_ProjCoord1 / v_ProjCoord1.w);
            }
        }
		else if(t_MaxComp == t_Absv.z)
		{
            if(t_Vect.z < 0.0)
		    {
                t_Shadow = GETSHADOW(u_ShadowMap2, v_ProjCoord2 / v_ProjCoord2.w);
            }
		    else
		    {
                t_Shadow = GETSHADOW(u_ShadowMap3, v_ProjCoord3 / v_ProjCoord3.w);
            }
        }
		else if(t_MaxComp == t_Absv.x)
		{
            if(t_Vect.x < 0.0)
		    {
                t_Shadow = GETSHADOW(u_ShadowMap4, v_ProjCoord4 / v_ProjCoord4.w);
            }
		    else
		    {
                t_Shadow = GETSHADOW(u_ShadowMap5, v_ProjCoord5 / v_ProjCoord5.w);
            }
        }  
	}
    #else
	{
        #ifdef(PSSM)
	    {
            if(v_ShadowPosition.x < splits.x)
			{
				t_Shadow = GETSHADOW(u_ShadowMap0, v_ProjCoord0 );   
			}
			else if( v_ShadowPosition.x <  splits.y)
			{
				//shadowBorderScale = 0.5;
				t_Shadow = GETSHADOW(u_ShadowMap1, v_ProjCoord1);  
			}
			else if( v_ShadowPosition.x <  splits.z)
			{
				//shadowBorderScale = 0.25;
				t_Shadow = GETSHADOW(u_ShadowMap2, v_ProjCoord2); 
			}
			else if( v_ShadowPosition.x <  splits.w)
			{
				//shadowBorderScale = 0.125;
				t_Shadow = GETSHADOW(u_ShadowMap3, v_ProjCoord3); 
			}
	    }
        #else
	    {
            //spotlight

			vec4 t_ProjCoord = v_ProjCoord;
			t_ProjCoord = t_ProjCoord / t_ProjCoord.w;
			
			t_Shadow = GETSHADOW(u_ShadowMap0, t_ProjCoord);
			
			//a small falloff to make the shadow blend nicely into the not lighten
			//we translate the texture coordinate value to a -1,1 range so the length 
			//of the texture coordinate vector is actually the radius of the lighten area on the ground
			t_ProjCoord = t_ProjCoord * 2.0 - 1.0;
			float t_FallOff = (length(t_ProjCoord.xy) - 0.9) / 0.1;
			t_Shadow = mix(t_Shadow,1.0,saturate(fallOff));

			//if v_LightDot.x < 0, no shadow
			t_Shadow = max(step(v_LightDot.x,0),t_Shadow);
        }
    } 

    #ifdef(FADE)
	{
		t_Shadow = max(0.0,mix(t_Shadow,1.0,(v_ShadowPosition - u_FadeInfo.x) * u_FadeInfo.y));    
    }
	
    t_Shadow = t_Shadow * u_ShadowIntensity + (1.0 - u_ShadowIntensity);

	vec4 gl_FragColor.rgb = t_Shadow;
	gl_FragColor.a = 1.0;
	
	output = gl_FragColor;
}