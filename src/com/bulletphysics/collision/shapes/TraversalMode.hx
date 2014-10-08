package com.bulletphysics.collision.shapes;

/**
 * Traversal mode for {@link OptimizedBvh}.
 * @author weilichuang
 */

enum TraversalMode 
{
	STACKLESS;
	STACKLESS_CACHE_FRIENDLY;
	RECURSIVE;
}