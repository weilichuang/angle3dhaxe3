package com.bulletphysics.collision.shapes;

/**
 * Traversal mode for {OptimizedBvh}.
 
 */
@:enum abstract TraversalMode(Int)  
{
	var STACKLESS = 0;
	var STACKLESS_CACHE_FRIENDLY = 1;
	var RECURSIVE = 2;
}