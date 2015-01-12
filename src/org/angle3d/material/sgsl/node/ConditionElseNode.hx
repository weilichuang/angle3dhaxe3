package org.angle3d.material.sgsl.node;

import org.angle3d.material.sgsl.node.LeafNode;

class ConditionElseNode extends SgslNode
{
	public function new()
	{
		super(NodeType.CONDITION, "else");
	}
	
	override private function get_dataType():String
	{
		return DataType.VOID;
	}
	
	override public function toAgalNode():AgalNode
	{
		var node:AgalNode = new AgalNode();

		node.name = "els";
		
		return node;
	}
	
	//先处理自身，最后处理内部内容
	override public function flat(programNode:ProgramNode, functionNode:FunctionNode, result:Array<LeafNode>):Void
	{
		var newElseNode:ConditionElseNode = new ConditionElseNode();
		newElseNode.isFlat = true;
		result.push(newElseNode);
		
		var child:LeafNode;
		for (i in 0...mChildren.length)
		{
			child = mChildren[i];
			
			child.flat(programNode, functionNode, result);
			
			if (child.type != NodeType.CONDITION)
			{
				result.push(child);
			}
		}
	}

	override public function clone():LeafNode
	{
		var node:ConditionElseNode = new ConditionElseNode();
		cloneChildren(node);
		return node;
	}
	
	override public function toString(level:Int = 0):String
	{
		var space:String = getSpace(level++);

		var text:String = space + this.name + "\n";
		
		if (!isFlat)
		{
			text += space + "{\n";
			
			var length:Int = mChildren.length;
			for (i in 0...length)
			{
				var m:LeafNode = mChildren[i];
				text += m.toString(level + 1);
			}
			text += "\n" + space + "}\n";
		}
		
		return text;
	}
}
