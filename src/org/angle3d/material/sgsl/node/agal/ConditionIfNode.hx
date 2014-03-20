package org.angle3d.material.sgsl.node.agal;

import org.angle3d.material.sgsl.node.LeafNode;


/**
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

		var result:Array<String> = [];

		var m:LeafNode;
		var length:Int = mChildren.length;
		for (i in 0...length)
		{
			m = mChildren[i];
			result.push(m.toString(level));
		}
		return space + this.name + "(" + result[0] + " " + this.compareMethod + " " + result[1] + "){\n";
	}

}
