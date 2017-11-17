package org.angle3d.texture;

@:enum abstract WrapMode(String) {
	var CLAMP = "clamp";
	var CLAMP_U_REPEAT_V = "clamp_u_repeat_v";
	var REPEAT = "repeat";
	var REPEAT_U_CLAMP_V = "repeat_u_clamp_v";

	inline function new(v:String)
	this = v;

	inline public function toString():String
	return this;
}