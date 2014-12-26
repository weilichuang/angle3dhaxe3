package org.angle3d.material.sgsl.node;

/**
 * ...
 * @author weilichuang
 */
class OpNode extends LeafNode
{
	public var leftNode:LeafNode;
	public var rightNode:LeafNode;

	public function new(name:String) 
	{
		super(name);
	}
	
}