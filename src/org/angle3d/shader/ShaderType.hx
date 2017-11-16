package org.angle3d.shader;

@:enum abstract ShaderType(Int)  
{
	var VERTEX = 0;
	var FRAGMENT = 1;
	
	inline function new(v:Int)
        this = v;

    inline public function toInt():Int
    	return this;
}
