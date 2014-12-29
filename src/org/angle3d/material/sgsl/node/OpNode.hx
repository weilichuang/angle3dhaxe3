package org.angle3d.material.sgsl.node;
import org.angle3d.material.sgsl.node.agal.FlatInfo;

class OpNode extends BranchNode
{
	public function new(name:String) 
	{
		super(name);
	}
	
	override public function getDataType():String
	{
		switch(this.name)
		{
			case "+", "-", "/":
				return mChildren[0].getDataType();
			case "*":
				if (mChildren[0].getDataType() == "vec3")
					return "vec3";
				else if (mChildren[0].getDataType() == "vec2")
					return "vec2";
				else if (mChildren[0].getDataType() == "vec4")
					return "vec4";
				else 
					return "float";
			default:
				return "";
		}
	}
	
	override public function toString(level:Int = 0):String
	{
		var result:String = getSpace(level) + mChildren[0].toString(0) + this.name + mChildren[1].toString(0);

		return result;
	}
}