package com.bulletphysics.collision.broadphase;

/**
 * OverlapCallback is used when processing all overlapping pairs in broadphase.
 
 */
interface OverlapCallback
{
	//return true for deletion of the pair
    function processOverlap(pair:BroadphasePair):Bool;
}