package com.bulletphysics.collision.broadphase;
import com.bulletphysics.collision.broadphase.Dbvt.DbvtNode;
import flash.Vector;

/**
 * Dbvt implementation by Nathanael Presson
 
 */
class DbvtProxy extends BroadphaseProxy
{
	public var aabb:DbvtAabbMm = new DbvtAabbMm();
    public var leaf:DbvtNode;
    public var links:Vector<DbvtProxy> = new Vector<DbvtProxy>(2);
    public var stage:Int;

	public function new(userPtr:Dynamic, collisionFilterGroup:Int, collisionFilterMask:Int, multiSapParentProxy:Dynamic = null)
	{
		super(userPtr, collisionFilterGroup, collisionFilterMask, multiSapParentProxy);
	}
}