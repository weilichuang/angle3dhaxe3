
uniform vec4 u_BitShifts;
uniform vec4 u_ShaderInfo;

varying vec4 v_ProjCoord0;
uniform sampler2D u_ShadowMap0<clamp,nearest>;

#ifdef(NUM_SHADOWMAP_1)
{
	varying vec4 v_ProjCoord1;
	uniform sampler2D u_ShadowMap1<clamp,nearest>;
}

#ifdef(NUM_SHADOWMAP_2)
{
	varying vec4 v_ProjCoord2;
	uniform sampler2D u_ShadowMap2<clamp,nearest>;
}

#ifdef(NUM_SHADOWMAP_3)
{
	varying vec4 v_ProjCoord3;
	uniform sampler2D u_ShadowMap3<clamp,nearest>;
}

#ifdef(POINTLIGHT)
{
	varying vec4 v_ProjCoord4;
	uniform sampler2D u_ShadowMap4<clamp,nearest>;
	
	varying vec4 v_ProjCoord5;
	uniform sampler2D u_ShadowMap5<clamp,nearest>;
	
	uniform vec4 u_LightPos;
    varying vec4 v_WorldPos;
}
#else
{
    #ifndef(PSSM)
	{
        varying vec4 v_LightDot;
    }
}

#ifdef(PSSM)
{
	uniform vec4 u_Splits;
}

#ifdef(DISCARD_ALPHA)
{
    #ifdef(COLOR_MAP)
	{
        uniform sampler2D u_ColorMap<clamp,nearest>;
	}
    #else
    {
        uniform sampler2D u_DiffuseMap<clamp,nearest>;
	}
    uniform float u_AlphaDiscardThreshold;
	varying vec4 v_TexCoord;
}

#ifdef(PSSM || FADE)
{
	varying vec4 v_ShadowPosition;
}

#ifdef(FADE)
{
	uniform vec4 u_FadeInfo;
}

#ifdef(PSSM)
{
	float function GETSHADOW(sampler2D texture,vec4 projCoord)//,float borderScale)
	{
		//unpack_depth
		vec4 t_Color = texture2D(projCoord,texture);
		float t_Shadow = dot4(u_BitShifts,t_Color);
		
		float t_Depth = projCoord.z - u_ShaderInfo.x;
		return step(t_Depth, t_Shadow);
	}	
}
#else
{
	float function GETSHADOW(sampler2D texture,vec4 projCoord)
	{
		//unpack_depth
		vec4 t_Color = texture2D(projCoord,texture);
		float t_Shadow = dot4(u_BitShifts,t_Color);
		
		float t_Depth = projCoord.z - u_ShaderInfo.x;
		return step(t_Depth, t_Shadow);
	}
}


void function main()
{
	#ifdef(DISCARD_ALPHA)
	{
        #ifdef(COLOR_MAP)
		{
            float t_Alpha = texture2D(v_TexCoord,m_ColorMap).a;
		}
        #else
		{
            float t_Alpha = texture2D(v_TexCoord,m_DiffuseMap).a;
        }
		
		kill(t_Alpha - u_AlphaDiscardThreshold);
    }
	
	float t_Shadow = 1.0;
 
    #ifdef(POINTLIGHT)
	{
        vec3 t_Vect = v_WorldPos.xyz - u_LightPos.xyz;
        vec3 t_Absv = abs(t_Vect);
        float t_MaxComp = max(t_Absv.x,max(t_Absv.y,t_Absv.z));
		
		vec4 t_ProjCoord;
		
		t_ProjCoord = v_ProjCoord0 / v_ProjCoord0.w;
		t_ProjCoord.y = 1 - t_ProjCoord.y;
		float t_Shadow0 = GETSHADOW(u_ShadowMap0, t_ProjCoord);

		t_ProjCoord = v_ProjCoord1 / v_ProjCoord1.w;
		t_ProjCoord.y = 1 - t_ProjCoord.y;
		float t_Shadow1 = GETSHADOW(u_ShadowMap1, t_ProjCoord);

		t_ProjCoord = v_ProjCoord2 / v_ProjCoord2.w;
		t_ProjCoord.y = 1 - t_ProjCoord.y;
		float t_Shadow2 = GETSHADOW(u_ShadowMap2, t_ProjCoord);

		t_ProjCoord = v_ProjCoord3 / v_ProjCoord3.w;
		t_ProjCoord.y = 1 - t_ProjCoord.y;
		float t_Shadow3 = GETSHADOW(u_ShadowMap3, t_ProjCoord);

		t_ProjCoord = v_ProjCoord4 / v_ProjCoord4.w;
		t_ProjCoord.y = 1 - t_ProjCoord.y;
		float t_Shadow4 = GETSHADOW(u_ShadowMap4, t_ProjCoord);

		t_ProjCoord = v_ProjCoord5 / v_ProjCoord5.w;
		t_ProjCoord.y = 1 - t_ProjCoord.y;
		float t_Shadow5 = GETSHADOW(u_ShadowMap5, t_ProjCoord);
		
		if(t_MaxComp == t_Absv.y)
		{
            if(t_Vect.y < 0.0)
		    {
                t_Shadow = t_Shadow0;
            }
		    else
		    {
                t_Shadow = t_Shadow1;
            }
        }
		else
		{
			if(t_MaxComp == t_Absv.z)
			{
				if(t_Vect.z < 0.0)
				{
					t_Shadow = t_Shadow2;
				}
				else
				{
					t_Shadow = t_Shadow3;
				}
			}
			else 
			{
				if(t_MaxComp == t_Absv.x)
				{
					if(t_Vect.x < 0.0)
					{
						t_Shadow = t_Shadow4;
					}
					else
					{
						t_Shadow = t_Shadow5;
					}
				} 
			}
		}
		

        //if(t_MaxComp == t_Absv.y)
		//{
            //if(t_Vect.y < 0.0)
		    //{
                //t_Shadow = GETSHADOW(u_ShadowMap0, v_ProjCoord0);
            //}
		    //else
		    //{
                //t_Shadow = GETSHADOW(u_ShadowMap1, v_ProjCoord1);
            //}
        //}
		//else
		//{
			//if(t_MaxComp == t_Absv.z)
			//{
				//if(t_Vect.z < 0.0)
				//{
					//t_Shadow = GETSHADOW(u_ShadowMap2, v_ProjCoord2);
				//}
				//else
				//{
					//t_Shadow = GETSHADOW(u_ShadowMap3, v_ProjCoord3);
				//}
			//}
			//else 
			//{
				//if(t_MaxComp == t_Absv.x)
				//{
					//if(t_Vect.x < 0.0)
					//{
						//t_Shadow = GETSHADOW(u_ShadowMap4, v_ProjCoord4);
					//}
					//else
					//{
						//t_Shadow = GETSHADOW(u_ShadowMap5, v_ProjCoord5);
					//}
				//} 
			//}
		//}
	}
    #else
	{
		//directional Light
        #ifdef(PSSM)
	    {
			vec4 t_ProjCoord0 = v_ProjCoord0;
			//使用的是正交视角，不需要归一化
			//t_ProjCoord0 = t_ProjCoord0 / t_ProjCoord0.w;
			t_ProjCoord0.y = 1 - t_ProjCoord0.y;
			t_Shadow = GETSHADOW(u_ShadowMap0, t_ProjCoord0);//, 1.0);
			t_Shadow *= slt(v_ShadowPosition.x,u_Splits.x);
			
			
			#ifdef(NUM_SHADOWMAP_1)
			{
				vec4 t_ProjCoord1 = v_ProjCoord1;
				//t_ProjCoord1 = t_ProjCoord1 / t_ProjCoord1.w;
				t_ProjCoord1.y = 1 - t_ProjCoord1.y;
				t_Shadow += GETSHADOW(u_ShadowMap1, t_ProjCoord1);//, 0.5);
				t_Shadow *= slt(v_ShadowPosition.x,u_Splits.y);
			}
			
			#ifdef(NUM_SHADOWMAP_2)
			{
				vec4 t_ProjCoord2 = v_ProjCoord2;
				//t_ProjCoord2 = t_ProjCoord2 / t_ProjCoord2.w;
				t_ProjCoord2.y = 1 - t_ProjCoord2.y;
				t_Shadow += GETSHADOW(u_ShadowMap2, t_ProjCoord2);//, 0.25);
				t_Shadow *= slt(v_ShadowPosition.x,u_Splits.z);
			}
			
			#ifdef(NUM_SHADOWMAP_3)
			{
				vec4 t_ProjCoord3 = v_ProjCoord3;
				//t_ProjCoord3 = t_ProjCoord3 / t_ProjCoord3.w;
				t_ProjCoord3.y = 1 - t_ProjCoord3.y;
				t_Shadow += GETSHADOW(u_ShadowMap3, t_ProjCoord3);//, 0.125);
				t_Shadow *= slt(v_ShadowPosition.x,u_Splits.w);
			}
			
			//在if语句中使用计算出的纹理坐标会报错---why?
			// 某个 if 块中的 TEX 指令无法使用计算出的纹理坐标。请使用内插的纹理坐标或改用 TED 指令。在 fragment 程序的标记 7 处。
            //if(v_ShadowPosition.x < u_Splits.x)
			//{
				//t_Shadow = GETSHADOW(u_ShadowMap0, v_ProjCoord0);//, 1.0);   
			//}
			//else 
			//{
				//if( v_ShadowPosition.x <  u_Splits.y)
				//{
					//#ifdef(NUM_SHADOWMAP_1)
					//{
						//t_Shadow = GETSHADOW(u_ShadowMap1, v_ProjCoord1);//, 0.5);  
					//}
					//#else
					//{
						//t_Shadow = 1.0;
					//}
				//}
				//else 
				//{
					//if( v_ShadowPosition.x <  u_Splits.z)
					//{
						//#ifdef(NUM_SHADOWMAP_2)
						//{
							//t_Shadow = GETSHADOW(u_ShadowMap2, v_ProjCoord2);//, 0.25); 
						//}
						//#else
						//{
							//t_Shadow = 1.0;
						//} 
					//}
					//else 
					//{
						//if( v_ShadowPosition.x <  u_Splits.w)
						//{
							//#ifdef(NUM_SHADOWMAP_3)
							//{
								//t_Shadow = GETSHADOW(u_ShadowMap3, v_ProjCoord3);//, 0.125);  
							//}
							//#else
							//{
								//t_Shadow = 1.0;
							//}
						//}
					//}
				//}
			//}
	    }
        #else
	    {
            //spotlight
			vec4 t_ProjCoord = v_ProjCoord0 / v_ProjCoord0.w;
			t_ProjCoord.y = 1 - t_ProjCoord.y;
			
			t_Shadow = GETSHADOW(u_ShadowMap0, t_ProjCoord);
			
			//a small falloff to make the shadow blend nicely into the not lighten
			//we translate the texture coordinate value to a -1,1 range so the length 
			//of the texture coordinate vector is actually the radius of the lighten area on the ground
			t_ProjCoord.xy = t_ProjCoord.xy * 2.0 - 1.0;
			float t_FallOff = (length(t_ProjCoord.xy) - 0.9) / 0.1;
			t_FallOff = saturate(t_FallOff);
			t_Shadow = mix(t_Shadow,1.0,t_FallOff);
			
			//if v_LightDot.x < 0, no shadow
			t_Shadow = max(step(v_LightDot.x,0),t_Shadow);
        }
    } 

    #ifdef(FADE)
	{
		t_Shadow = max(0.0,mix(t_Shadow,1.0,(v_ShadowPosition.x - u_FadeInfo.x) * u_FadeInfo.y));    
    }
	
    t_Shadow = t_Shadow * u_ShaderInfo.y + u_ShaderInfo.z;

	vec4 gl_FragColor.rgb = t_Shadow;
	gl_FragColor.a = 1.0;
	
	output = gl_FragColor;
}