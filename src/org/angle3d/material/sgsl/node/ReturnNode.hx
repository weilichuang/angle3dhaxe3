package org.angle3d.material.sgsl.node;

class ReturnNode extends SgslNode
{
	public function new() 
	{
		super(NodeType.RETURN,"return");
	}
	
	override public function clone(result:LeafNode = null):LeafNode
	{
		if (result == null)
			result = new ReturnNode();
			
		return super.clone(result);
	}
	
	override public function toString(level:Int = 0):String
	{
		var result:String = getSpace(level) + "return " + getChildrenString(0) + ";\n";

		return result;
	}
}