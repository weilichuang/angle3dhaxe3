package org.angle3d.material.sgsl.node.agal;
import org.angle3d.material.sgsl.node.LeafNode;

/**
 * ...
 * @author weilichuang
 */
class FlatInfo
{
	public var depth:Int;
	
	public var node:LeafNode;

	public function new(node:LeafNode, depth:Int) 
	{
		this.node = node;
		this.depth = depth;
	}
	
}