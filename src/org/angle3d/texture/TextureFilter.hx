package org.angle3d.texture;

@:enum abstract TextureFilter(String)  
{
	var LINEAR = "linear";
	var NEAREST = "nearest";
	var ANISOTROPIC2X = "anisotropic2x";
	var ANISOTROPIC4X = "anisotropic4x";
	var ANISOTROPIC8X = "anisotropic8x";
	var ANISOTROPIC16X = "anisotropic16x";
	
	inline function new(v:String)
        this = v;

    inline public function toString():String
    	return this;
}