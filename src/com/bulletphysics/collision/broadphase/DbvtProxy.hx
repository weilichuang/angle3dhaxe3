package com.bulletphysics.collision.broadphase;
import com.bulletphysics.collision.broadphase.Dbvt.Node;
import haxe.ds.Vector;

/**
 * Dbvt implementation by Nathanael Presson
 * @author weilichuang
 */
class DbvtProxy extends BroadphaseProxy
{
	public var aabb:DbvtAabbMm = new DbvtAabbMm();
    public var leaf:Node;
    public var links:Vector<DbvtProxy> = new Vector<DbvtProxy>(2);
    public var stage:Int;

	public function new(userPtr:Dynamic, collisionFilterGroup:Int, collisionFilterMask:Int, multiSapParentProxy:Dynamic = null)
	{
		super(userPtr, collisionFilterGroup, collisionFilterMask, multiSapParentProxy);
	}
	
}