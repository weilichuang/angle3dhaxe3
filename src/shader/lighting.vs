//lighting vertex lessThan
/** 
	test comment for debug 
 */
attribute vec3 a_position(POSITION);
attribute vec3 a_normal(NORMAL);
attribute vec2 a_texCoord(TEXCOORD);

uniform mat4 u_WorldViewProjectionMatrix(WorldViewProjectionMatrix);
uniform mat4 u_WorldViewMatrix(WorldViewMatrix);
uniform mat3 u_NormalMatrix(NormalMatrix);
uniform mat4 u_ViewMatrix(ViewMatrix);

uniform vec4 u_Ambient;
uniform vec4 u_Diffuse;
uniform vec4 u_Specular;
uniform float u_Shininess;

uniform vec4 u_LightColor;
uniform vec4 u_LightPosition;
uniform vec4 u_AmbientLightColor;

varying vec4 v_texCoord;

#ifdef(SEPARATE_TEXCOORD){
  varying vec4 v_texCoord2;
  attribute vec2 a_texCoord2(TEXCOORD2);
}

varying vec4 v_AmbientSum;
varying vec4 v_DiffuseSum;
varying vec4 v_SpecularSum;

varying vec4 v_lightVec;

#ifdef(VERTEX_COLOR){
  attribute vec4 a_color(COLOR);
}

#ifdef(VERTEX_LIGHTING){
  varying vec4 v_vertexLightValues;
  uniform vec4 u_LightDirection;
} 
#else 
{
  attribute vec4 a_inTangent(TANGENT);

  #ifndef(NORMALMAP)
  {
    varying vec4 v_vNormal;
  } 
  
  varying vec4 v_vViewDir;
  varying vec4 v_vLightDir;
}

#ifdef(USE_REFLECTION)
{
    uniform vec3 u_CameraPosition;
    uniform mat4 u_WorldMatrix;

    uniform vec3 u_FresnelParams;
    varying vec4 refVec;
	
    void function computeRef(vec4 modelSpacePos)
	{
        vec3 worldPos = (u_WorldMatrix * modelSpacePos);

        vec3 I = normalize( u_CameraPosition - worldPos  );
        vec3 N = normalize( (u_WorldMatrix * Vec4(a_normal, 0.0)) );

        refVec.xyz = reflect(I, N);
        refVec.w   = u_FresnelParams.x + u_FresnelParams.y * pow(1.0 + dot(I, N), u_FresnelParams.z);
    }
}

// JME3 lights in world space
void function lightComputeDir(vec3 worldPos, vec4 color, vec4 position, vec4 lightDir)
{
    float posLight = step(0.5, color.w);
    vec3 tempVec = position.xyz * sign(posLight - 0.5) - (worldPos * posLight);
    v_lightVec = tempVec;  
    #ifdef(ATTENUATION)
	{
        float dist = length(tempVec);
        lightDir.w = clamp(1.0 - position.w * dist * posLight, 0.0, 1.0);
        lightDir.xyz = tempVec / Vec3(dist);
    } 
	#else 
	{
        lightDir = Vec4(normalize(tempVec), 1.0);
    }
}

#ifdef(VERTEX_LIGHTING)
{
    float function lightComputeSpecular(vec3 norm, vec3 viewdir, vec3 lightdir, float shiny)
	{
		if (shiny <= 1.0){
			return 0.0;
		}
		  
		#ifdef(LOW_QUALITY)
		{
			return 0.0;
		} 
		#else 
		{
			vec3 H = (viewdir + lightdir) * Vec3(0.5);
			return pow(maxDot(H, norm, 0.0), shiny);
		}
    }

    vec2 function computeLighting(vec3 wvPos, vec3 wvNorm, vec3 wvViewDir, vec4 wvLightPos)
	{
        vec4 lightDir;
        lightComputeDir(wvPos, u_LightColor, wvLightPos, lightDir);
        float spotFallOff = 1.0;
        if(u_LightDirection.w != 0.0)
		{
            vec3 L=normalize(v_lightVec.xyz);
            vec3 spotdir = normalize(u_LightDirection.xyz);
            float curAngleCos = dot(-L, spotdir);    
            float innerAngleCos = floor(u_LightDirection.w) * 0.001;
            float outerAngleCos = fract(u_LightDirection.w);
            float innerMinusOuter = innerAngleCos - outerAngleCos;
            spotFallOff = clamp((curAngleCos - outerAngleCos) / innerMinusOuter, 0.0, 1.0);
        }
        float diffuseFactor = maxDot(wvNorm, lightDir.xyz, 0.0);
        float specularFactor = lightComputeSpecular(wvNorm, wvViewDir, lightDir.xyz, u_Shininess);
        return Vec2(diffuseFactor, specularFactor) * Vec2(lightDir.w) * spotFallOff;
    }
}

void function main()
{
    vec4 modelSpacePos;
    modelSpacePos.xyz = a_position.xyz;
    modelSpacePos.w = 1.0;
   
    vec3 modelSpaceNorm = a_normal;
   
    #ifndef(VERTEX_LIGHTING)
	{
      vec3 modelSpaceTan = a_inTangent.xyz;
    }

    #ifdef(NUM_BONES)
	{
        #ifndef(VERTEX_LIGHTING)
		{
			skinning_Compute(modelSpacePos, modelSpaceNorm, modelSpaceTan);
		}
        #else
		{
			skinning_Compute(modelSpacePos, modelSpaceNorm);
        }
    }

    output = u_WorldViewProjectionMatrix * modelSpacePos;
	
    v_texCoord = a_texCoord;
	
    #ifdef(SEPARATE_TEXCOORD)
	{
      v_texCoord2 = a_texCoord2;
    }

    vec3 wvPosition = (u_WorldViewMatrix * modelSpacePos);//.xyz;
    vec3 wvNormal  = normalize(u_NormalMatrix * modelSpaceNorm);
    vec3 viewDir = normalize(-wvPosition);
  
    vec4 wvLightPos = (u_ViewMatrix * Vec4(u_LightPosition.xyz,clamp(u_LightColor.w,0.0,1.0)));
    wvLightPos.w = u_LightPosition.w;
    vec4 lightColor = u_LightColor;
   
    #ifndef(VERTEX_LIGHTING)
	{
		#ifdef(NORMALMAP)
		{
			vec3 wvTangent = normalize(u_NormalMatrix * modelSpaceTan);
			vec3 wvBinormal = crossProduct(wvNormal, wvTangent);

			mat3 tbnMat = Mat3(wvTangent, wvBinormal * a_inTangent.w,wvNormal);
			 
			v_vViewDir  = -wvPosition * tbnMat;
			lightComputeDir(wvPosition, lightColor, wvLightPos, v_vLightDir);
			v_vLightDir.xyz = (v_vLightDir.xyz * tbnMat);//.xyz;
		}
		#else 
		{
			v_vNormal = wvNormal;

			v_vViewDir = viewDir;

			lightComputeDir(wvPosition, lightColor, wvLightPos, v_vLightDir);

			#ifdef(V_TANGENT)
			{
				v_vNormal = normalize(u_NormalMatrix * a_inTangent.xyz);
				v_vNormal = -crossProduct(crossProduct(v_vLightDir.xyz, v_vNormal), v_vNormal);
		    }
		}
    }

    lightColor.w = 1.0;
    #ifdef(MATERIAL_COLORS)
	{
        v_AmbientSum  = (u_Ambient  * u_AmbientLightColor);//.rgb;
        v_DiffuseSum  =  u_Diffuse  * lightColor;
        v_SpecularSum = (u_Specular * lightColor);//.rgb;
    } 
	#else
	{
	    // Default: ambient color is dark gray
        v_AmbientSum  = Vec3(0.2, 0.2, 0.2) * u_AmbientLightColor.rgb; 
        v_DiffuseSum  = lightColor;
        v_SpecularSum = Vec3(0.0);
    }

    #ifdef(VERTEX_COLOR)
	{
        v_AmbientSum = v_AmbientSum * a_color.rgb;
        v_DiffuseSum = v_DiffuseSum * a_color;
    }

    #ifdef(VERTEX_LIGHTING)
	{
        v_vertexLightValues = computeLighting(wvPosition, wvNormal, viewDir, wvLightPos);
    }

    #ifdef(USE_REFLECTION)
	{
        computeRef(modelSpacePos);
    } 
}