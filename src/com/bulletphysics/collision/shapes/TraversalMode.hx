package com.bulletphysics.collision.shapes;

/**
 * Traversal mode for {OptimizedBvh}.
 * @author weilichuang
 */

enum TraversalMode 
{
	STACKLESS;
	STACKLESS_CACHE_FRIENDLY;
	RECURSIVE;
}