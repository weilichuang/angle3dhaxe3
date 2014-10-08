package com.bulletphysics.collision.shapes;

/**
 * BvhSubtreeInfo provides info to gather a subtree of limited size.
 * @author weilichuang
 */
class BvhSubtreeInfo
{
	public var quantizedAabbMin:Array<Int> = [];
	public var quantizedAabbMax:Array<Int> = [];
	// points to the root of the subtree
	public var rootNodeIndex:Int;
	public var subtreeSize:Int;

	public function new() 
	{
		
	}
	
	public function setAabbFromQuantizeNode(quantizedNodes:QuantizedBvhNodes, nodeId:Int):Void
	{
		quantizedAabbMin[0] = quantizedNodes.getQuantizedAabbMinAt(nodeId, 0);
        quantizedAabbMin[1] = quantizedNodes.getQuantizedAabbMinAt(nodeId, 1);
        quantizedAabbMin[2] = quantizedNodes.getQuantizedAabbMinAt(nodeId, 2);
        quantizedAabbMax[0] = quantizedNodes.getQuantizedAabbMaxAt(nodeId, 0);
        quantizedAabbMax[1] = quantizedNodes.getQuantizedAabbMaxAt(nodeId, 1);
        quantizedAabbMax[2] = quantizedNodes.getQuantizedAabbMaxAt(nodeId, 2);
	}
	
}