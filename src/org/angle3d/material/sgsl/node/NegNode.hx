package org.angle3d.material.sgsl.node;

class NegNode extends SgslNode
{
	public function new() 
	{
		super(NodeType.NEG,"-");
	}
	
	override private function get_dataType():String
	{
		return mChildren[0].dataType;
	}
	
	public function toFunctionCallNode():FunctionCallNode
	{
		var callNode:FunctionCallNode = new FunctionCallNode("neg");
		cloneChildren(callNode);
		callNode.mask = mask;
		return callNode;
	}
	
	override public function clone():LeafNode
	{
		var node:NegNode = new NegNode();
		cloneChildren(node);
		node.mask = mask;
		return node;
	}
	
	override public function toString(level:Int = 0):String
	{
		var result:String = "";

		result = "-" + getChildrenString(level);

		return result;
	}
}