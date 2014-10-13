package com.bulletphysics.dynamics.vehicle;
import vecmath.Vector3f;

/**
 * Vehicle raycaster result.
 * @author weilichuang
 */
class VehicleRaycasterResult
{

	public var hitPointInWorld:Vector3f = new Vector3f();
    public var hitNormalInWorld:Vector3f = new Vector3f();
    public var distFraction:Float = -1;

	
}