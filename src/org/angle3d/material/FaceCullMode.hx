package org.angle3d.material;

@:enum abstract FaceCullMode(Int)  
{
	var BACK = 0;
	var FRONT = 1;
	var FRONT_AND_BACK = 2;
	var NONE = 3;
}