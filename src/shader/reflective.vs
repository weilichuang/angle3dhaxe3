attribute vec3 a_position(POSITION);
attribute vec2 a_texCoord(TEXCOORD);
attribute vec3 a_normal(NORMAL);

#ifdef(USE_KEYFRAME)
{
	attribute vec3 a_position1(POSITION1);
	attribute vec3 a_normal1(NORMAL1);
	uniform vec4 u_influences;
}

varying vec4 v_texCoord;
varying vec4 v_R;

uniform mat4 u_WorldViewProjectionMatrix(WorldViewProjectionMatrix);
uniform mat4 u_worldMatrix(WorldMatrix);
uniform vec4 u_camPosition(CameraPosition);

void function main()
{
	#ifdef(USE_KEYFRAME)
	{
		vec3 morphed0;
		morphed0 = mul(a_position,u_influences.x);
		vec3 morphed1;
		morphed1 = mul(a_position1,u_influences.y);
		vec4 t_position;
		t_position.xyz = add(morphed0,morphed1);
		t_position.w = 1.0;
		output = m44(t_position,u_WorldViewProjectionMatrix);
		
		vec3 normalMorphed0;
		normalMorphed0 = mul(a_normal,u_influences.x);
		vec3 normalMorphed1;
		normalMorphed1 = mul(a_normal1,u_influences.y);
		vec3 t_normal = add(normalMorphed0,normalMorphed1);

	}
	#else 
	{
		vec4 t_position;
		t_position.xyz = a_position;
		t_position.w = 1.0;
		output = m44(t_position,u_WorldViewProjectionMatrix);
		vec3 t_normal = a_normal;
	}

    vec3 t_N = m33(t_normal.xyz,u_worldMatrix);
    t_N = normalize(t_N);

    vec4 t_positionW = m44(t_position,u_worldMatrix);
    vec3 t_I = sub(t_positionW.xyz,u_camPosition.xyz);

    v_R = reflect(t_I,t_N);
    v_texCoord = a_texCoord;
}