package com.bulletphysics.collision.narrowphase;
import com.bulletphysics.collision.narrowphase.DiscreteCollisionDetectorInterface.Result;
import vecmath.Vector3f;

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

    public function setShapeIdentifiers(partId0:Int, index0:Int, partId1:Int, index1:Int):Void
	{
        // ??
    }

    public function addContactPoint(normalOnBInWorld:Vector3f, pointInWorld:Vector3f, depth:Float):Void
	{
        if (depth < distance) 
		{
            hasResult = true;
            this.normalOnBInWorld.fromVector3f(normalOnBInWorld);
            this.pointInWorld.fromVector3f(pointInWorld);
            // negative means penetration
            distance = depth;
        }
    }
}