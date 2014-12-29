package org.angle3d.material.sgsl.node;

class NegNode extends BranchNode
{
	public function new() 
	{
		super("-");
	}	
	
	override public function toString(level:Int = 0):String
	{
		var result:String = "";

		result = "-" + getChildrenString(level);

		return result;
	}
}