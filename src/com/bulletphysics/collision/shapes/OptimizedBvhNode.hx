package com.bulletphysics.collision.shapes;
import com.vecmath.Vector3f;

/**
 * OptimizedBvhNode contains both internal and leaf node information.
 * @author weilichuang
 */
class OptimizedBvhNode
{
	public var aabbMinOrg:Vector3f = new Vector3f();
	public var aabbMaxOrg:Vector3f = new Vector3f();
	
	public var escapeIndex:Int;
	
	//for child nodes
	public var subPart:Int;
	public var triangleIndex:Int;
	
	
	public function new() 
	{
		
	}
	
	public function set(node:OptimizedBvhNode):Void
	{
		aabbMinOrg.fromVector3f(node.aabbMinOrg);
		aabbMaxOrg.fromVector3f(node.aabbMaxOrg);
		escapeIndex = node.escapeIndex;
		subPart = node.subPart;
		triangleIndex = node.triangleIndex;
	}
}