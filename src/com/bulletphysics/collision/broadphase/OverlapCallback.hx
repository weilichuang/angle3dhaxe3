package com.bulletphysics.collision.broadphase;

/**
 * OverlapCallback is used when processing all overlapping pairs in broadphase.
 * @author weilichuang
 */
class OverlapCallback
{

	public function new() 
	{
		
	}
	
	//return true for deletion of the pair
    public function processOverlap(pair:BroadphasePair):Bool
	{
		return false;
	}
}