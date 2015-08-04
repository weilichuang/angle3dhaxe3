package com.bulletphysics.collision.narrowphase;
import com.bulletphysics.linearmath.IDebugDraw;
import com.bulletphysics.linearmath.Transform;
import com.vecmath.Vector3f;

/**
 * This interface is made to be used by an iterative approach to do TimeOfImpact calculations.<p>
 * <p/>
 * This interface allows to query for closest points and penetration depth between two (convex) objects
 * the closest point is on the second object (B), and the normal points from the surface on B towards A.
 * distance is between closest points on B and closest point on A. So you can calculate closest point on A
 * by taking <code>closestPointInA = closestPointInB + distance * normalOnSurfaceB</code>.
 * 
 * @author weilichuang
 */
interface DiscreteCollisionDetectorInterface
{
	/**
     * Give either closest points (distance > 0) or penetration (distance)
     * the normal always points from B towards A.
     */
    function getClosestPoints(input:ClosestPointInput, output:Result, debugDraw:IDebugDraw, swapResults:Bool = false):Void;
}

interface Result
{
	///setShapeIdentifiers provides experimental support for per-triangle material / custom material combiner
	function setShapeIdentifiers(partId0:Int, index0:Int, partId1:Int, index1:Int):Void;

	function addContactPoint(normalOnBInWorld:Vector3f, pointInWorld:Vector3f, depth:Float):Void;
}

class ClosestPointInput
{
	public var transformA:Transform = new Transform();
	public var transformB:Transform = new Transform();
	public var maximumDistanceSquared:Float;

	public function new()
	{
		init();
	}

	public inline function init():Void
	{
		maximumDistanceSquared = 1e30;
	}
}