package com.bulletphysics.collision.shapes;

/**
 * Scalar type, used when accessing triangle mesh data.
 
 */
@:enum abstract ScalarType(Int)   
{
	var FLOAT = 0;
    var INTEGER = 1;
    var SHORT = 2;
}