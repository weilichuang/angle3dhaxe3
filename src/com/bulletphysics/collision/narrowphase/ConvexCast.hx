package com.bulletphysics.collision.narrowphase;
import com.bulletphysics.linearmath.Transform;

/**
 * ConvexCast is an interface for casting.
 * @author weilichuang
 */
interface ConvexCast
{
	/**
     * Cast a convex against another convex object.
     */
    function calcTimeOfImpact(fromA:Transform, toA:Transform, fromB:Transform, toB:Transform, result:CastResult):Bool;
}