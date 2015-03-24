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

uniform mat4 u_WorldMatrix(WorldMatrix);
uniform mat4 u_WorldViewProjectionMatrix(WorldViewProjectionMatrix);
uniform mat4 u_BiasMat;
uniform vec4 u_LightPos; 

uniform mat4 u_LightViewProjectionMatrix0;
varying vec4 v_ProjCoord0;

#ifdef(NUM_SHADOWMAP_2)
{
	uniform mat4 u_LightViewProjectionMatrix1;
	varying vec4 v_ProjCoord1;
}

#ifdef(NUM_SHADOWMAP_3)
{
	uniform mat4 u_LightViewProjectionMatrix2;
	varying vec4 v_ProjCoord2;
}

#ifdef(NUM_SHADOWMAP_4)
{
	uniform mat4 u_LightViewProjectionMatrix3;
	varying vec4 v_ProjCoord3;
}


#ifdef(POINTLIGHT)
{
    uniform mat4 u_LightViewProjectionMatrix4;
    uniform mat4 u_LightViewProjectionMatrix5;
    varying vec4 v_ProjCoord4;
    varying vec4 v_ProjCoord5;
    varying vec4 v_WorldPos;
}
#else
{
    #ifndef(PSSM)
	{
        uniform vec3 u_LightDir; 
        varying vec4 v_LightDot;
    }
}

#ifdef(PSSM || FADE)
{
	varying vec4 v_ShadowPosition;
}

#ifdef(DISCARD_ALPHA)
{
    attribute vec2 a_TexCoord(TEXCOORD);
	varying vec2 v_TexCoord;
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

	vec4 t_WorldPos;
    #ifndef(POINTLIGHT)
	{
       t_WorldPos = 0.0;
    }
	
    // get the vertex in world space
    t_WorldPos = t_ModelSpacePos * u_WorldMatrix;
	
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
	
	#ifdef(NUM_SHADOWMAP_2)
	{
		v_ProjCoord1 = t_WorldPos * u_LightViewProjectionMatrix1;
	}

	#ifdef(NUM_SHADOWMAP_3)
	{
		v_ProjCoord2 = t_WorldPos * u_LightViewProjectionMatrix2;
	}

	#ifdef(NUM_SHADOWMAP_4)
	{
		v_ProjCoord3 = t_WorldPos * u_LightViewProjectionMatrix3;
	}

    #ifdef(POINTLIGHT)
	{
        v_ProjCoord4 = t_WorldPos * u_LightViewProjectionMatrix4;
        v_ProjCoord5 = t_WorldPos * u_LightViewProjectionMatrix5;
	}
    #else
	{
        #ifndef(PSSM)
		{
            vec3 t_LightDir = t_WorldPos.xyz - u_LightPos;
            v_LightDot = dot(u_LightDir,t_LightDir);
        }
    }
}