attribute vec3 a_Position(POSITION);

#ifdef(NUM_BONES)
{
	attribute vec4 a_boneWeights(BONE_WEIGHTS);
	attribute vec4 a_boneIndices(BONE_INDICES);
	uniform vec4 u_BoneMatrices[NUM_BONES];
}
#elseif(KEYFRAME)
{
	attribute vec3 a_Position1(POSITION1);
	uniform vec2 u_Interpolate;
}

#ifdef(DISCARD_ALPHA)
{
    attribute vec2 a_TexCoord(TEXCOORD);
	varying vec4 v_TexCoord;
}

uniform mat4 u_WorldMatrix(WorldMatrix);
uniform mat4 u_WorldViewProjectionMatrix(WorldViewProjectionMatrix);

uniform mat4 u_LightViewProjectionMatrix0;
varying vec4 v_ProjCoord0;

#ifdef(NUM_SHADOWMAP_1)
{
	uniform mat4 u_LightViewProjectionMatrix1;
	varying vec4 v_ProjCoord1;
}

#ifdef(NUM_SHADOWMAP_2)
{
	uniform mat4 u_LightViewProjectionMatrix2;
	varying vec4 v_ProjCoord2;
}

#ifdef(NUM_SHADOWMAP_3)
{
	uniform mat4 u_LightViewProjectionMatrix3;
	varying vec4 v_ProjCoord3;
}


#ifdef(POINTLIGHT)
{
    uniform mat4 u_LightViewProjectionMatrix4;
    uniform mat4 u_LightViewProjectionMatrix5;
	uniform vec3 u_LightPos; 
	
    varying vec4 v_ProjCoord4;
    varying vec4 v_ProjCoord5;
    varying vec4 v_WorldPos;
}
#else
{
	uniform vec3 u_LightDir; 
    #ifndef(PSSM)
	{
		uniform vec3 u_LightPos; 
        varying vec4 v_LightDot;
    }
}

#ifdef(PSSM || FADE)
{
	varying vec4 v_ShadowPosition;
}

#ifndef(BACKFACE_SHADOWS)
{
    attribute vec3 a_Normal(NORMAL);
    varying vec4 v_nDotL;
}

void function main()
{
    vec4 t_ModelSpacePos.xyz = a_Position;
	t_ModelSpacePos.w = 1.0;
	#ifdef(NUM_BONES)
	{
		skinning_Compute(a_boneIndices,a_boneWeights,u_BoneMatrices,t_ModelSpacePos);
    }
	#elseif(KEYFRAME)
	{
		t_ModelSpacePos.xyz = a_Position.xyz * u_Interpolate.x + a_Position1.xyz * u_Interpolate.y;
	}
	
	vec4 t_Pos = t_ModelSpacePos * u_WorldViewProjectionMatrix;
	output = t_Pos;
	
    #ifdef(PSSM || FADE)
	{
        v_ShadowPosition = t_Pos.z;
    }  
	
    // get the vertex in world space
    vec4 t_WorldPos = t_ModelSpacePos * u_WorldMatrix;

	#ifdef(POINTLIGHT)
	{
		v_WorldPos = t_WorldPos;
	}

	#ifdef(DISCARD_ALPHA)
	{
		v_TexCoord = a_TexCoord;
	}
	
    // populate the light view matrices array and convert vertex to light viewProj space
    v_ProjCoord0 = t_WorldPos * u_LightViewProjectionMatrix0;
	
	#ifdef(NUM_SHADOWMAP_1)
	{
		v_ProjCoord1 = t_WorldPos * u_LightViewProjectionMatrix1;
	}

	#ifdef(NUM_SHADOWMAP_2)
	{
		v_ProjCoord2 = t_WorldPos * u_LightViewProjectionMatrix2;
	}

	#ifdef(NUM_SHADOWMAP_3)
	{
		v_ProjCoord3 = t_WorldPos * u_LightViewProjectionMatrix3;
	}

	vec3 t_LightDir;
    #ifdef(POINTLIGHT)
	{
        v_ProjCoord4 = t_WorldPos * u_LightViewProjectionMatrix4;
		
        v_ProjCoord5 = t_WorldPos * u_LightViewProjectionMatrix5;
	}
    #else
	{
        #ifndef(PSSM)
		{
			//Spot light
            t_LightDir = t_WorldPos.xyz - u_LightPos.xyz;
            v_LightDot = dot3(u_LightDir.xyz,t_LightDir);
        }
    }
	
	#ifndef(BACKFACE_SHADOWS)
	{
        vec3 t_Normal = a_Normal.xyz;
		t_Normal.w = 0;
		t_Normal = t_Normal * u_WorldMatrix;
		t_Normal.xyz = normalize(t_Normal.xyz);
		
        #ifdef(POINTLIGHT)
		{
            t_LightDir = t_WorldPos.xyz - u_LightPos.xyz;
        }
		#else
		{
            #ifdef(PSSM)
			{
               t_LightDir = u_LightDir.xyz;
            }
        }
        v_nDotL = dot3(t_Normal, t_LightDir);
    }
}