package com.bulletphysics.collision.narrowphase;
import com.bulletphysics.linearmath.IDebugDraw;
import com.bulletphysics.linearmath.Transform;
import com.vecmath.Vector3f;

/**
 * RayResult stores the closest result. Alternatively, add a callback method
 * to decide about closest/all results.
 */
class CastResult
{
	public var hitTransformA:Transform = new Transform();
	public var hitTransformB:Transform = new Transform();

	public var normal:Vector3f = new Vector3f();
	public var hitPoint:Vector3f = new Vector3f();
	public var fraction:Float = 1e30; // input and output
	public var allowedPenetration:Float = 0;

	public var debugDrawer:IDebugDraw;
	
	public function new()
	{
		
	}

	public function debugDraw(fraction:Float):Void
	{
	}

	public function drawCoordSystem(trans:Transform):Void
	{
	}
	
}