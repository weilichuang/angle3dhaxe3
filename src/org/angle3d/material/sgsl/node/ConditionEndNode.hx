package org.angle3d.material.sgsl.node;

class ConditionEndNode extends SgslNode
{
	public function new()
	{
		super(NodeType.CONDITION, "eif");
	}
	
	override private function get_dataType():String
	{
		return DataType.VOID;
	}
	
	override public function flat(programNode:ProgramNode, functionNode:FunctionNode, result:Array<LeafNode>):Void
	{
		this.isFlat = true;
		result.push(this);
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
		
		if (isFlat)
		{
			return space + "end\n";
		}
		else
		{
			return "";
		}
	}

}
