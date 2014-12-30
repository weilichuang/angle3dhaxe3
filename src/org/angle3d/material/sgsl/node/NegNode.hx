package org.angle3d.material.sgsl.node;

class NegNode extends SgslNode
{
	public function new() 
	{
		super(NodeType.NEG,"-");
	}
	
	override public function clone():LeafNode
	{
		var node:NegNode = new NegNode();
		cloneChildren(node);
		return node;
	}
	
	override public function toString(level:Int = 0):String
	{
		var result:String = "";

		result = "-" + getChildrenString(level);

		return result;
	}
}