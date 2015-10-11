uniform vec4 u_BitShifts;
uniform vec4 u_ShaderInfo;

uniform sampler2D u_Texture;
uniform sampler2D u_DepthTexture;

uniform mat4 u_ViewProjectionMatrixInverse;
uniform vec4 u_ViewProjectionMatrixRow2;

varying vec4 v_TexCoord;

uniform mat4 u_LightViewProjectionMatrix0;
uniform sampler2D u_ShadowMap0;

#ifdef(NUM_SHADOWMAP_1)
{
	uniform mat4 u_LightViewProjectionMatrix1;
	uniform sampler2D u_ShadowMap1;
}

#ifdef(NUM_SHADOWMAP_2)
{
	uniform mat4 u_LightViewProjectionMatrix2;
	uniform sampler2D u_ShadowMap2;
}

#ifdef(NUM_SHADOWMAP_3)
{
	uniform mat4 u_LightViewProjectionMatrix3;
	uniform sampler2D u_ShadowMap3;
}


#ifdef(POINTLIGHT)
{
    uniform mat4 u_LightViewProjectionMatrix4;
	uniform sampler2D u_ShadowMap4;
    uniform mat4 u_LightViewProjectionMatrix5;
	uniform sampler2D u_ShadowMap5;
	
	uniform vec4 u_LightPos;
}
#else
{
    #ifndef(PSSM)
	{
		uniform vec4 u_LightPos;
        uniform vec3 u_LightDir; 
    }
}

#ifdef(PSSM)
{
	uniform vec4 u_Splits;
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
	vec2 t_Coord = v_TexCoord.xy;
	t_Coord.y = 1 - t_Coord.y;
	vec4 t_depthColor = texture2D(t_Coord.xy,u_DepthTexture);
	float t_Depth = dot4(u_BitShifts,t_depthColor);

	// get the vertex in world space
	vec4 t_WorldPos;
	t_WorldPos.xy = v_TexCoord.xy;
	t_WorldPos.z = t_Depth;
	t_WorldPos.w = 1.0;
	t_WorldPos = t_WorldPos * 2.0 - 1.0;
	
	t_WorldPos = m44(t_WorldPos,u_ViewProjectionMatrixInverse);
	t_WorldPos.xyz /= t_WorldPos.w;
	t_WorldPos.w = 1.0;
	
	vec4 t_ProjCoord0 = t_WorldPos * u_LightViewProjectionMatrix0;
	
	#ifdef(NUM_SHADOWMAP_1)
	{
		vec4 t_ProjCoord1 = t_WorldPos * u_LightViewProjectionMatrix1;
	}

	#ifdef(NUM_SHADOWMAP_2)
	{
		vec4 t_ProjCoord2 = t_WorldPos * u_LightViewProjectionMatrix2;
	}

	#ifdef(NUM_SHADOWMAP_3)
	{
		vec4 t_ProjCoord3 = t_WorldPos * u_LightViewProjectionMatrix3;
	}

    #ifdef(POINTLIGHT)
	{
        vec4 t_ProjCoord4 = t_WorldPos * u_LightViewProjectionMatrix4;
		
        vec4 t_ProjCoord5 = t_WorldPos * u_LightViewProjectionMatrix5;
	}
	
	#ifdef(PSSM || FADE)
	{
        float t_ShadowPosition = dot3(u_ViewProjectionMatrixRow2.xyz, t_WorldPos.xyz) +  u_ViewProjectionMatrixRow2.w;
    }
	
	float t_Shadow = 1.0;
 
    #ifdef(POINTLIGHT)
	{
        vec3 t_Vect = t_WorldPos.xyz - u_LightPos.xyz;
        vec3 t_Absv = abs(t_Vect);
        float t_MaxComp = max(t_Absv.x,max(t_Absv.y,t_Absv.z));
		
		vec4 t_ProjCoord;
		
		t_ProjCoord = t_ProjCoord0 / t_ProjCoord0.w;
		t_ProjCoord.y = 1 - t_ProjCoord.y;
		float t_Shadow0 = GETSHADOW(u_ShadowMap0, t_ProjCoord);

		t_ProjCoord = t_ProjCoord1 / t_ProjCoord1.w;
		t_ProjCoord.y = 1 - t_ProjCoord.y;
		float t_Shadow1 = GETSHADOW(u_ShadowMap1, t_ProjCoord);

		t_ProjCoord = t_ProjCoord2 / t_ProjCoord2.w;
		t_ProjCoord.y = 1 - t_ProjCoord.y;
		float t_Shadow2 = GETSHADOW(u_ShadowMap2, t_ProjCoord);

		t_ProjCoord = t_ProjCoord3 / t_ProjCoord3.w;
		t_ProjCoord.y = 1 - t_ProjCoord.y;
		float t_Shadow3 = GETSHADOW(u_ShadowMap3, t_ProjCoord);

		t_ProjCoord = t_ProjCoord4 / t_ProjCoord4.w;
		t_ProjCoord.y = 1 - t_ProjCoord.y;
		float t_Shadow4 = GETSHADOW(u_ShadowMap4, t_ProjCoord);

		t_ProjCoord = t_ProjCoord5 / t_ProjCoord5.w;
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
	}
    #else
	{
		//directional Light
        #ifdef(PSSM)
	    {
			//使用的是正交视角，不需要归一化
			//t_ProjCoord0 = t_ProjCoord0 / t_ProjCoord0.w;
			t_ProjCoord0.y = 1 - t_ProjCoord0.y;
			t_Shadow = GETSHADOW(u_ShadowMap0, t_ProjCoord0);//, 1.0);
			t_Shadow *= slt(t_ShadowPosition.x,u_Splits.x);
			
			
			#ifdef(NUM_SHADOWMAP_1)
			{
				//t_ProjCoord1 = t_ProjCoord1 / t_ProjCoord1.w;
				t_ProjCoord1.y = 1 - t_ProjCoord1.y;
				t_Shadow += GETSHADOW(u_ShadowMap1, t_ProjCoord1);//, 0.5);
				t_Shadow *= slt(t_ShadowPosition.x,u_Splits.y);
			}
			
			#ifdef(NUM_SHADOWMAP_2)
			{
				//t_ProjCoord2 = t_ProjCoord2 / t_ProjCoord2.w;
				t_ProjCoord2.y = 1 - t_ProjCoord2.y;
				t_Shadow += GETSHADOW(u_ShadowMap2, t_ProjCoord2);//, 0.25);
				t_Shadow *= slt(t_ShadowPosition.x,u_Splits.z);
			}
			
			#ifdef(NUM_SHADOWMAP_3)
			{
				//t_ProjCoord3 = t_ProjCoord3 / t_ProjCoord3.w;
				t_ProjCoord3.y = 1 - t_ProjCoord3.y;
				t_Shadow += GETSHADOW(u_ShadowMap3, t_ProjCoord3);//, 0.125);
				t_Shadow *= slt(t_ShadowPosition.x,u_Splits.w);
			}
			
			//在if语句中使用计算出的纹理坐标会报错---why?
			// 某个 if 块中的 TEX 指令无法使用计算出的纹理坐标。请使用内插的纹理坐标或改用 TED 指令。在 fragment 程序的标记 7 处。
            //if(t_ShadowPosition.x < u_Splits.x)
			//{
				//t_Shadow = GETSHADOW(u_ShadowMap0, t_ProjCoord0);//, 1.0);   
			//}
			//else 
			//{
				//if( t_ShadowPosition.x <  u_Splits.y)
				//{
					//#ifdef(NUM_SHADOWMAP_1)
					//{
						//t_Shadow = GETSHADOW(u_ShadowMap1, t_ProjCoord1);//, 0.5);  
					//}
					//#else
					//{
						//t_Shadow = 1.0;
					//}
				//}
				//else 
				//{
					//if( t_ShadowPosition.x <  u_Splits.z)
					//{
						//#ifdef(NUM_SHADOWMAP_2)
						//{
							//t_Shadow = GETSHADOW(u_ShadowMap2, t_ProjCoord2);//, 0.25); 
						//}
						//#else
						//{
							//t_Shadow = 1.0;
						//} 
					//}
					//else 
					//{
						//if( t_ShadowPosition.x <  u_Splits.w)
						//{
							//#ifdef(NUM_SHADOWMAP_3)
							//{
								//t_Shadow = GETSHADOW(u_ShadowMap3, t_ProjCoord3);//, 0.125);  
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
			t_ProjCoord0 = t_ProjCoord0 / t_ProjCoord0.w;
			t_ProjCoord0.y = 1 - t_ProjCoord0.y;
			
			t_Shadow = GETSHADOW(u_ShadowMap0, t_ProjCoord0);
			
			//a small falloff to make the shadow blend nicely into the not lighten
			//we translate the texture coordinate value to a -1,1 range so the length 
			//of the texture coordinate vector is actually the radius of the lighten area on the ground
			t_ProjCoord0.xy = t_ProjCoord0.xy * 2.0 - 1.0;
			float t_FallOff = (length(t_ProjCoord0.xy) - 0.9) / 0.1;
			t_FallOff = saturate(t_FallOff);
			t_Shadow = mix(t_Shadow,1.0,t_FallOff);
			
			vec3 t_LightDir = t_WorldPos.xyz - u_LightPos.xyz;
			float t_LightDot = dot3(u_LightDir,t_LightDir);
			
			//if t_LightDot.x < 0, no shadow
			t_Shadow = max(step(t_LightDot,0),t_Shadow);
        }
    } 

    #ifdef(FADE)
	{
		t_Shadow = max(0.0,mix(t_Shadow,1.0,(t_ShadowPosition.x - u_FadeInfo.x) * u_FadeInfo.y));    
    }
	
    t_Shadow = t_Shadow * u_ShaderInfo.y + u_ShaderInfo.z;
	
	vec4 t_Color = texture2D(v_TexCoord.xy,u_Texture);
	
	if(t_Depth >= 1)
	{
		t_Shadow = 1;
	}
	
	t_Color.xyz *= t_Shadow;

	output = t_Color;
}