package org.angle3d.material.sgsl.node.agal;

import org.angle3d.material.sgsl.node.LeafNode;

/**
 * andy
 * @author
 */
class ConditionEndNode extends AgalNode
{
	public function new()
	{
		super();
		this.name = "eif";
	}

	override public function clone():LeafNode
	{
		var node:ConditionEndNode = new ConditionEndNode();
		cloneChildren(node);
		return node;
	}

	override public function toString(level:Int = 0):String
	{
		var space:String = getSpace(level++);
		return "";// space + "}\n";
	}

}
