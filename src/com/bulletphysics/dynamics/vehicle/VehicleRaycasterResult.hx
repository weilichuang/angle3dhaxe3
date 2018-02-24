package com.bulletphysics.dynamics.vehicle;
import angle3d.math.Vector3f;

/**
 * Vehicle raycaster result.
 
 */
class VehicleRaycasterResult
{

	public var hitPointInWorld:Vector3f = new Vector3f();
    public var hitNormalInWorld:Vector3f = new Vector3f();
    public var distFraction:Float = -1;

	public function new()
	{
		
	}
	
}