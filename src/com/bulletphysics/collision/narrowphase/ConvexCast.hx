package com.bulletphysics.collision.narrowphase;
import com.bulletphysics.linearmath.Transform;

/**
 * ConvexCast is an interface for casting.
 * @author weilichuang
 */
class ConvexCast
{

	public function new() 
	{
		
	}
	
	/**
     * Cast a convex against another convex object.
     */
    public function calcTimeOfImpact(fromA:Transform, toA:Transform, fromB:Transform, toB:Transform, result:CastResult):Bool
	{
		return false;
	}
	
}