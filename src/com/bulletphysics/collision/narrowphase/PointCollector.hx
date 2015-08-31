package com.bulletphysics.collision.narrowphase;
import com.bulletphysics.collision.narrowphase.DiscreteCollisionDetectorInterface.Result;
import com.vecmath.Vector3f;

/**
 * ...
 * @author weilichuang
 */
class PointCollector implements Result
{

	public var normalOnBInWorld:Vector3f = new Vector3f();
    public var pointInWorld:Vector3f = new Vector3f();
    public var distance:Float = 1e30; // negative means penetration

    public var hasResult:Bool = false;
	
	public function new()
	{
		
	}

    public function setShapeIdentifiers(partId0:Int, index0:Int, partId1:Int, index1:Int):Void
	{
        // ??
    }

    public function addContactPoint(normalOnBInWorld:Vector3f, pointInWorld:Vector3f, depth:Float):Void
	{
        if (depth < distance) 
		{
            hasResult = true;
            this.normalOnBInWorld.copyFrom(normalOnBInWorld);
            this.pointInWorld.copyFrom(pointInWorld);
            // negative means penetration
            distance = depth;
        }
    }
}