package com.bulletphysics.collision.broadphase;
import com.bulletphysics.linearmath.IDebugDraw;

/**
 * ...
 
 */
class DispatcherInfo
{
	public var timeStep:Float;
    public var stepCount:Int;
    public var dispatchFunc:DispatchFunc;
    public var timeOfImpact:Float;
    public var useContinuous:Bool;
    public var debugDraw:IDebugDraw;
    public var enableSatConvex:Bool;
    public var enableSPU:Bool = true;
    public var useEpa:Bool = true;
    public var allowedCcdPenetration:Float = 0.04;

	public function new() 
	{
		dispatchFunc = DispatchFunc.DISPATCH_DISCRETE;
        timeOfImpact = 1;
	}
	
}