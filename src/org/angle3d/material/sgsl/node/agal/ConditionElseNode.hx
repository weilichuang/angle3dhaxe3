package org.angle3d.material.sgsl.node.agal;

import org.angle3d.material.sgsl.node.LeafNode;

/**
 * @author
 */
class ConditionElseNode extends AgalNode
{

	public function new()
	{
		super();
		this.name = "els";
	}

	override public function clone():LeafNode
	{
		var node:ConditionElseNode = new ConditionElseNode();
		node.name = this.name;
		cloneChildren(node);
		return node;
	}

	override public function toString(level:Int = 0):String
	{
		var space:String = getSpace(level++);
		return space + "} else" + "{\n";
	}

}
