attribute vec3 a_position;
varying vec4 v_color;
uniform mat4 u_WorldViewProjectionMatrix;
uniform vec4 u_color;

#ifdef(USE_KEYFRAME){
    attribute vec3 a_position1;
    uniform vec4 u_influences;
}

void function main(){
	#ifdef(USE_KEYFRAME){
        vec3 morphed0;
        morphed0 = mul(a_position,u_influences.x);
        vec3 morphed1;
        morphed1 = mul(a_position1,u_influences.y);
        vec4 morphed;
        morphed.xyz = add(morphed0,morphed1);
        morphed.w = 1.0;
        output = m44(morphed,u_WorldViewProjectionMatrix);
    }
    #else {
        output = m44(a_position,u_WorldViewProjectionMatrix);
    }
    v_color = u_color;
}