package com.bulletphysics.dynamics.vehicle;

/**
 * Vehicle tuning parameters.
 
 */
class VehicleTuning
{

	public var suspensionStiffness:Float = 5.88;
    public var suspensionCompression:Float = 0.83;
    public var suspensionDamping:Float = 0.88;
    public var maxSuspensionTravelCm:Float = 500;
	public var maxSuspensionForce:Float = 6000;
    public var frictionSlip:Float = 10.5;
	
	public function new()
	{
		
	}
	
}