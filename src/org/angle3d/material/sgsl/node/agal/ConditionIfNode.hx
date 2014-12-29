package org.angle3d.material.sgsl.node.agal;

import org.angle3d.material.sgsl.node.LeafNode;


/**
 * andy
 * @author andy
 */
class ConditionIfNode extends AgalNode
{
	public var compareMethod:String;
	
	public function new(name:String)
	{
		super();
		this.name = name;
	}

	override public function clone():LeafNode
	{
		var node:ConditionIfNode = new ConditionIfNode(this.name);
		node.compareMethod = this.compareMethod;
		cloneChildren(node);
		return node;
	}

	override public function toString(level:Int = 0):String
	{
		var space:String = getSpace(level++);

		var text:String = space + this.name + "(" + mChildren[0].toString(0) + " " + this.compareMethod + " " + mChildren[1].toString(0) + ")\n" + space + "{\n";
		var length:Int = mChildren.length;
		for (i in 2...length)
		{
			var m:LeafNode = mChildren[i];
			text += m.toString(level + 1);
		}
		text += "\n" + space + "}\n";
		
		return text;
	}

}
