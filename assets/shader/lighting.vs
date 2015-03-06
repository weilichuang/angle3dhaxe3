//MultiPass Lighting
attribute vec3 a_Position(POSITION);
attribute vec2 a_TexCoord(TEXCOORD);
attribute vec3 a_Normal(NORMAL);

uniform mat4 u_WorldViewProjectionMatrix(WorldViewProjectionMatrix);
uniform mat4 u_WorldViewMatrix(WorldViewMatrix);
uniform mat3 u_NormalMatrix(NormalMatrix);
uniform mat4 u_ViewMatrix(ViewMatrix);

#ifdef(MATERIAL_COLORS)
{
	uniform vec4 u_Ambient;
	uniform vec4 u_Diffuse;
	uniform vec4 u_Specular;
}

uniform float u_Shininess;

uniform vec4 gu_LightColor;
uniform vec4 gu_LightPosition;
uniform vec4 gu_AmbientLightColor;

varying vec4 v_TexCoord;

#ifdef(SEPARATE_TEXCOORD)
{
  varying vec4 v_TexCoord2;
  attribute vec2 a_TexCoord2(TEXCOORD2);
}

varying vec3 v_AmbientSum;
varying vec4 v_DiffuseSum;
varying vec3 v_SpecularSum;

varying vec3 v_LightVec;

#ifdef(VERTEX_COLOR)
{
  attribute vec4 a_Color(COLOR);
}

#ifdef(VERTEX_LIGHTING)
{
  varying vec4 v_VertexLightValues;
  uniform vec4 gu_LightDirection;
} 
#else 
{
  //attribute vec4 a_Tangent(TANGENT);

  #ifndef(NORMALMAP)
  {
    varying vec4 v_Normal;
  } 
  
  varying vec4 v_ViewDir;
  varying vec4 v_LightDir;
}

#ifdef(USE_REFLECTION)
{
    uniform vec3 u_CameraPosition(CameraPosition);
    uniform mat4 u_WorldMatrix(WorldMatrix);

    uniform vec3 u_FresnelParams;
    varying vec4 v_RefVec;
}

/*
* Computes light direction 
* lightType should be 0.0,1.0,2.0, repectively for Directional, point and spot lights.
* Outputs the light direction and the light half vector. 
*/
void function lightComputeDir(vec3 worldPos, float lightType, vec4 position, vec4 lightDir, vec3 lightVec)
{
	float t_PosLight = step(0.5, lightType);
	vec3 t_TempVec = position.xyz * abs(t_PosLight - 0.5) - (worldPos * t_PosLight);
	lightVec = t_TempVec;  
	
	float t_Dist = length(t_TempVec);
	#ifdef(SRGB)
	{
		lightDir.w = (1.0 - position.w * t_Dist) / (1.0 + position.w * t_Dist * t_Dist);
		lightDir.w = clamp(lightDir.w, 1.0 - t_PosLight, 1.0);
	} 
	#else 
	{
		lightDir.w = saturate(1.0 - position.w * t_Dist * t_PosLight);
	}
	lightDir.xyz = t_TempVec / t_Dist;
}

#ifdef(VERTEX_LIGHTING)
{
	/*
	* Computes the spot falloff for a spotlight
	*/
	float function computeSpotFalloff(vec4 lightDirection, vec3 lightVector){
		vec3 t_L = normalize(lightVector);
		vec3 t_Spotdir = normalize(lightDirection.xyz);
		float t_CurAngleCos = dot3(-t_L, t_Spotdir);    
		float t_InnerAngleCos = floor(lightDirection.w) * 0.001;
		float t_OuterAngleCos = fract(lightDirection.w);
		float t_InnerMinusOuter = t_InnerAngleCos - t_OuterAngleCos;
		return clamp((t_CurAngleCos - t_OuterAngleCos) / t_InnerMinusOuter, step(lightDirection.w, 0.001), 1.0);
	}

	/*
	* Computes diffuse factor (Lambert)
	*/
	float function lightComputeDiffuse(vec3 norm, vec3 lightdir){
		return max(0.0, dot3(norm, lightdir));
	}

	/*
	* Computes specular factor   (blinn phong) 
	*/
	float function lightComputeSpecular(vec3 norm, vec3 viewdir, vec3 lightdir, float shiny)
	{
		vec3 H = normalize(viewdir + lightdir);
		float HdotN = max(0.0, dot3(H, norm));
		return pow(HdotN, shiny);
	}

	/*
	* Computes diffuse and specular factors and pack them in a vec2 (x=diffuse, y=specular)
	*/
	vec2 function computeLighting(vec3 norm, vec3 viewDir, vec3 lightDir, float attenuation, float shininess)
	{
	   float diffuseFactor = lightComputeDiffuse(norm, lightDir);
	   float specularFactor = lightComputeSpecular(norm, viewDir, lightDir, shininess);      
	   if (shininess <= 1.0)
	   {
		   specularFactor = 0.0; // should be one instruction on most cards ..
	   }
	   specularFactor = specularFactor * diffuseFactor;
	   diffuseFactor = diffuseFactor * attenuation;
	   specularFactor = specularFactor * attenuation;
	   return Vec2(diffuseFactor, specularFactor);
	}
} 

//uniform vec4 u_boneMatrixs[42];

void function main()
{
    vec4 t_ModelSpacePos = Vec4(a_Position,1.0);

    vec3 t_ModelSpaceNorm = a_Normal;
   
    #ifndef(VERTEX_LIGHTING)
	{
      vec3 t_ModelSpaceTan = 1.0;//a_Tangent.xyz;
    }

	//TODO support bones
    //#ifdef(NUM_BONES)
	//{
        //#ifndef(VERTEX_LIGHTING)
		//{
			//skinning_Compute(t_ModelSpacePos, t_modelSpaceNorm, t_modelSpaceTan);
		//}
        //#else
		//{
			//skinning_Compute(t_ModelSpacePos, t_modelSpaceNorm);
        //}
    //}

    output = t_ModelSpacePos * u_WorldViewProjectionMatrix;
	
    v_TexCoord = a_TexCoord;
    #ifdef(SEPARATE_TEXCOORD)
	{
      v_TexCoord2 = a_TexCoord2;
    }
	
    vec3 t_WvPosition = (t_ModelSpacePos * u_WorldViewMatrix).xyz;
    vec3 t_WvNormal  = normalize((t_ModelSpaceNorm * u_NormalMatrix).xyz);
    vec3 t_ViewDir = normalize(-t_WvPosition);
  
	float t_lightType = gu_LightColor.w;
    vec4 t_WvLightPos = (Vec4(gu_LightPosition.xyz,saturate(t_lightType)) * u_ViewMatrix);
    t_WvLightPos.w = gu_LightPosition.w;
    vec4 t_LightColor = gu_LightColor;

    #ifndef(VERTEX_LIGHTING)
	{
		#ifdef(NORMALMAP)
		{
			vec3 t_WvTangent = normalize(t_ModelSpaceTan * u_NormalMatrix);
			vec3 t_WvBinormal = crossProduct(t_WvNormal, t_WvTangent);
			//TODO need test function Mat3 
			mat3 t_TbnMat = Mat3(t_WvTangent, t_WvBinormal * a_Tangent.w,t_WvNormal);
			 
			v_ViewDir  = -t_WvPosition * t_TbnMat;
			lightComputeDir(t_WvPosition, t_LightColor.w, t_WvLightPos, v_LightDir, v_LightVec);
			v_LightDir.xyz = (v_LightDir.xyz * t_TbnMat).xyz;
		}
		#else 
		{
			v_Normal = t_WvNormal;
			v_ViewDir = t_ViewDir;
			lightComputeDir(t_WvPosition, t_LightColor.w, t_WvLightPos, v_LightDir, v_LightVec);
		}
    }

    #ifdef(MATERIAL_COLORS)
	{
        vec3 t_Ambient  = u_Ambient.rgb;
		v_AmbientSum  = t_Ambient.rgb * gu_AmbientLightColor.rgb;
        v_DiffuseSum  =  u_Diffuse  * t_LightColor;
        v_SpecularSum = (u_Specular * t_LightColor).rgb;
    } 
	#else
	{
	    // Default: ambient color is dark gray
        v_AmbientSum  = gu_AmbientLightColor.rgb; 
        v_DiffuseSum  = t_LightColor;
        v_SpecularSum = 0.0;
    }

    #ifdef(VERTEX_COLOR)
	{
        v_AmbientSum = v_AmbientSum * a_Color.rgb;
        v_DiffuseSum = v_DiffuseSum * a_Color;
    }

    #ifdef(VERTEX_LIGHTING)
	{
		float t_SpotFallOff = 1.0;
		vec4 t_LightDir;
		lightComputeDir(t_WvPosition, t_LightColor.w, t_WvLightPos, t_LightDir, v_LightVec);
		
		//TODO try replace condition
		if(t_LightColor.w > 1.0)
		{
			t_SpotFallOff = computeSpotFalloff(gu_LightDirection, v_LightVec);
		}
		
        v_VertexLightValues = computeLighting(t_WvNormal, t_ViewDir, t_LightDir.xyz, t_LightDir.w * t_SpotFallOff, u_Shininess);
    }

    #ifdef(USE_REFLECTION)
	{
        vec3 t_worldPos = (u_WorldMatrix * t_ModelSpacePos).xyz;

        vec3 t_I = normalize( u_CameraPosition - t_worldPos  );
        vec3 t_N = normalize((u_WorldMatrix * Vec4(a_Normal, 0.0)));

        v_RefVec.xyz = reflect(t_I, t_N);
        v_RefVec.w   = u_FresnelParams.x + u_FresnelParams.y * pow(1.0 + dot3(t_I, t_N), u_FresnelParams.z);
    } 
}