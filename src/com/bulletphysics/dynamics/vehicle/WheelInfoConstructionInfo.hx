package com.bulletphysics.dynamics.vehicle;
import vecmath.Vector3f;

/**
 * ...
 * @author weilichuang
 */
class WheelInfoConstructionInfo
{

	public var chassisConnectionCS:Vector3f = new Vector3f();
    public var wheelDirectionCS:Vector3f = new Vector3f();
    public var wheelAxleCS:Vector3f = new Vector3f();
    public var suspensionRestLength:Float;
    public var maxSuspensionTravelCm:Float;
	public var maxSuspensionForce:Float = 6000;
    public var wheelRadius:Float;

    public var suspensionStiffness:Float;
    public var wheelsDampingCompression:Float;
    public var wheelsDampingRelaxation:Float;
    public var frictionSlip:Float;
    public var bIsFrontWheel:Bool;
	
	public function new()
	{
		
	}

}