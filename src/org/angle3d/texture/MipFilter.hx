package org.angle3d.texture;

@:enum abstract MipFilter(String) {
	var MIPLINEAR = "miplinear";
	var MIPNEAREST = "mipnearest";
	var MIPNONE = "mipnone";

	inline function new(v:String)
	this = v;

	inline public function toString():String
	return this;
}