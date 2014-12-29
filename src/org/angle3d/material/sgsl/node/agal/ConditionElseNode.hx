package org.angle3d.material.sgsl.node.agal;

import org.angle3d.material.sgsl.node.LeafNode;

/**
 * andy
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

		var text:String = space + this.name + "\n{\n";
		var length:Int = mChildren.length;
		for (i in 0...length)
		{
			var m:LeafNode = mChildren[i];
			text += m.toString(level + 1);
		}
		text += "\n}\n";
		
		return text;
	}
}
