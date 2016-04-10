package org.angle3d.renderer;

/**
 * Caps is an enum specifying a capability that the Renderer
 * supports.
 * 
 
 */
@:enum abstract Caps(Int)    
{
	var AGAL1 = 0;
	var AGAL2 = 1;
	var FloatTexture = 2;
    var RectangleTexture = 3;
	var MRT = 4;
}