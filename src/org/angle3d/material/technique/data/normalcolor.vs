attribute vec3 a_position;
attribute vec3 a_normal;

#ifdef(USE_KEYFRAME){
	attribute vec3 a_position1;
	attribute vec3 a_normal1;
	uniform vec4 u_influences;
}

varying vec4 v_normal;

uniform mat4 u_WorldViewProjectionMatrix;

void function main()
{
	#ifdef(USE_KEYFRAME){
		vec3 morphed0;
		morphed0 = mul(a_position,u_influences.x);
		vec3 morphed1;
		morphed1 = mul(a_position1,u_influences.y);
		vec4 morphed;
		morphed.xyz = add(morphed0,morphed1);
		morphed.w = 1.0;
		output = m44(morphed,u_WorldViewProjectionMatrix);

		vec3 normalMorphed0;
		normalMorphed0 = mul(a_normal,u_influences.x);
		vec3 normalMorphed1;
		normalMorphed1 = mul(a_normal1,u_influences.y);
		vec3 normalMorphed;
		normalMorphed = add(normalMorphed0,normalMorphed1);
		normalMorphed = normalize(normalMorphed);
		v_normal = normalMorphed;
	}
	#else {
		output = m44(a_position,u_WorldViewProjectionMatrix);
		v_normal = a_normal;
	}
}