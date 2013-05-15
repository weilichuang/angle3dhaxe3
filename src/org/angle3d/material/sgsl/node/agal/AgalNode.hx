package org.angle3d.material.sgsl.node.agal;

import org.angle3d.material.sgsl.node.BranchNode;
import org.angle3d.material.sgsl.node.LeafNode;

/**
 * 对应于一行agal代码
 * AgalNode最多有两个children
 */
class AgalNode extends BranchNode
{
	public function new()
	{
		super();
	}

	override public function clone():LeafNode
	{
		var node:AgalNode = new AgalNode();
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

		if (result.length == 1)
		{
			return space + result[0] + ";\n";
		}
		else
		{
			return space + result[0] + " = " + result[1] + ";\n";
		}
	}
}

