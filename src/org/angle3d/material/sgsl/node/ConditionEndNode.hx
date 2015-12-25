package org.angle3d.material.sgsl.node;
import flash.Vector;

class ConditionEndNode extends SgslNode
{
	public function new()
	{
		super(NodeType.CONDITION, "eif");
		this.dataType = DataType.VOID;
	}
	
	override public function toAgalNode():AgalNode
	{
		var node:AgalNode = new AgalNode();

		node.name = "eif";
		
		return node;
	}
	
	override public function flat(programNode:ProgramNode, functionNode:FunctionNode, result:Vector<LeafNode>):Void
	{
		this.isFlat = true;
		result.push(this);
	}
	
	override public function clone(result:LeafNode = null):LeafNode
	{
		if (result == null)
			result = new ConditionEndNode();
			
		return super.clone(result);
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
