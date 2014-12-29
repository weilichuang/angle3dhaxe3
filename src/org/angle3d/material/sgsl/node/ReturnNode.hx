package org.angle3d.material.sgsl.node;

/**
 * ...
 * @author weilichuang
 */
class ReturnNode extends BranchNode
{
	public function new() 
	{
		super("return");
	}
	
	override public function toString(level:Int = 0):String
	{
		var result:String = getSpace(level) + "return " + getChildrenString(0) + ";\n";

		return result;
	}
}