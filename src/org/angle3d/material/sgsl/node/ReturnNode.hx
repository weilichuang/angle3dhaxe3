package org.angle3d.material.sgsl.node;

class ReturnNode extends SgslNode
{
	public function new() 
	{
		super(NodeType.RETURN,"return");
	}
	
	override public function clone():LeafNode
	{
		var node:ReturnNode = new ReturnNode();
		cloneChildren(node);
		return node;
	}
	
	override public function toString(level:Int = 0):String
	{
		var result:String = getSpace(level) + "return " + getChildrenString(0) + ";\n";

		return result;
	}
}